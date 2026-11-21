import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymrecords/data/mock_data.dart';
import 'package:gymrecords/models/workout_record.dart';
import 'package:gymrecords/services/local_data_store.dart';
import 'package:gymrecords/services/report_export_service.dart';
import 'package:gymrecords/services/analytics_service.dart';
import 'package:gymrecords/services/weekly_workout_summary.dart';
import 'package:gymrecords/services/csv_history_import_service.dart';
import 'dart:typed_data';
import 'package:gymrecords/state/app_controller.dart';

void main() {
  test('editar, excluir, desfazer e repetir mantém séries distintas', () async {
    final store = MemoryLocalDataStore();
    final app = AppController(persistenceEnabled: false, store: store);
    await app.loadPreferences();
    final machine = app.ensureMachineAdded(
      buildExerciseCatalog().firstWhere((e) => e.id == 'barbell_bench_press'),
    );
    final first = app.addRecord(machine, weight: 80, repetitions: 3);
    final second = app.addRecord(machine, weight: 80, repetitions: 10);
    expect(first.id, isNot(second.id));
    expect(first.sessionId, WorkoutRecord.dayKey(DateTime.now()));
    expect(app.updateRecord(machine, first, first.copyWith(repetitions: 8)), isTrue);
    expect(machine.records.map((r) => r.repetitions), containsAll([8, 10]));
    expect(app.removeRecord(machine, second), isTrue);
    expect(machine.records.length, 1);
    app.restoreRecord(machine, second);
    expect(machine.records.length, 2);
    await app.flushPendingWrites();
    final reopened = AppController(persistenceEnabled: false, store: store);
    await reopened.loadPreferences();
    final recovered = reopened.machineById(machine.id).records;
    expect(recovered.length, 2);
    expect(recovered.map((r) => r.repetitions), containsAll([8, 10]));
    app.dispose();
    reopened.dispose();
  });

  test('favoritos persistem no backup e após reiniciar', () async {
    final store = MemoryLocalDataStore();
    final app = AppController(persistenceEnabled: false, store: store);
    await app.loadPreferences();
    app.toggleFavorite('barbell_bench_press');
    await app.flushPendingWrites();
    expect(app.isFavorite('barbell_bench_press'), isTrue);
    final next = AppController(persistenceEnabled: false, store: store);
    await next.loadPreferences();
    expect(next.isFavorite('barbell_bench_press'), isTrue);
    expect((jsonDecode(next.exportBackup()) as Map)['favorites'],
        contains('barbell_bench_press'));
    app.dispose();
    next.dispose();
  });

  test('regulagens estruturadas persistem no backup sem perder registros', () async {
    final store = MemoryLocalDataStore();
    final app = AppController(persistenceEnabled: false, store: store);
    await app.loadPreferences();
    final machine = app.ensureMachineAdded(
      buildExerciseCatalog().firstWhere((e) => e.id == 'barbell_bench_press'),
    );
    app.addRecord(machine, weight: 50, repetitions: 10);
    app.updateMachineAdjustments(machine, {
      'seat': 'posição 4',
      'grip': 'pegada neutra',
      'other': '',
    });
    await app.flushPendingWrites();
    final reopened = AppController(persistenceEnabled: false, store: store);
    await reopened.loadPreferences();
    final saved = reopened.machineById(machine.id);
    expect(saved.adjustments['seat'], 'posição 4');
    expect(saved.adjustments['grip'], 'pegada neutra');
    expect(saved.adjustments.containsKey('other'), isFalse);
    expect(saved.records.single.repetitions, 10);
    app.dispose();
    reopened.dispose();
  });

  test('resumo semanal conta dias e séries sem aquecimento', () {
    final machine = buildExerciseCatalog().firstWhere(
      (e) => e.id == 'barbell_bench_press',
    );
    machine.records.addAll([
      WorkoutRecord(date: DateTime(2026, 11, 16, 10), weight: 50, repetitions: 8),
      WorkoutRecord(date: DateTime(2026, 11, 16, 11), weight: 20, repetitions: 10, isWarmup: true),
      WorkoutRecord(date: DateTime(2026, 11, 18, 9), weight: 55, repetitions: 8),
      WorkoutRecord(date: DateTime(2026, 11, 15, 9), weight: 99, repetitions: 1),
    ]);
    final summary = WeeklyWorkoutSummary.calculate([machine],
        now: DateTime(2026, 11, 20, 18));
    expect(summary.trainingDays, 2);
    expect(summary.exerciseCount, 1);
    expect(summary.workingSets, 2);
    expect(summary.totalVolume, 840);
  });

  test('texto ampliado é opcional e não modifica o histórico', () {
    final app = AppController(persistenceEnabled: false);
    expect(app.largeText, isFalse);
    app.setLargeText(true);
    expect(app.largeText, isTrue);
    app.setLargeText(false);
    expect(app.largeText, isFalse);
    app.dispose();
  });

  test('duas sessões no mesmo dia têm IDs distintos e persistem', () async {
    final store = MemoryLocalDataStore();
    final app = AppController(persistenceEnabled: false, store: store);
    await app.loadPreferences();
    final machine = app.ensureMachineAdded(
      buildExerciseCatalog().firstWhere((e) => e.id == 'barbell_bench_press'),
    );
    final firstSession = app.startSession(name: 'Treino A');
    app.addExerciseToSession(machine);
    final first = app.addRecord(machine, weight: 60, repetitions: 8);
    app.finishSession();
    final secondSession = app.startSession(name: 'Treino B');
    final second = app.addRecord(machine, weight: 70, repetitions: 6);
    expect(firstSession, isNot(secondSession));
    expect(first.sessionId, firstSession);
    expect(second.sessionId, secondSession);
    await app.flushPendingWrites();
    final restarted = AppController(persistenceEnabled: false, store: store);
    await restarted.loadPreferences();
    expect(restarted.activeSessionId, secondSession);
    expect(restarted.sessionNames[firstSession], 'Treino A');
    expect(restarted.sessionNames[secondSession], 'Treino B');
    expect(restarted.machineById(machine.id).records.length, 2);
    restarted.finishSession();
    await restarted.flushPendingWrites();
    final finalApp = AppController(persistenceEnabled: false, store: store);
    await finalApp.loadPreferences();
    expect(finalApp.activeSessionId, isNull);
    app.dispose();
    restarted.dispose();
    finalApp.dispose();
  });

  test('academias, metas e foto local persistem em backup v1 compatível', () async {
    final store = MemoryLocalDataStore();
    final app = AppController(persistenceEnabled: false, store: store);
    await app.loadPreferences();
    final id = app.addGym('Academia Centro');
    final machine = app.ensureMachineAdded(
      buildExerciseCatalog().firstWhere((e) => e.id == 'barbell_bench_press'),
    );
    app.setTargetWeight(machine.id, 100);
    app.setLocalPhoto(machine.id, Uint8List.fromList([1, 2, 3]));
    final record = app.addRecord(machine, weight: 80, repetitions: 10);
    expect(record.gymId, id);
    await app.flushPendingWrites();

    final loaded = AppController(persistenceEnabled: false, store: store);
    await loaded.loadPreferences();
    expect(loaded.selectedGymId, id);
    expect(loaded.gyms[id], 'Academia Centro');
    expect(loaded.targetWeights[machine.id], 100);
    expect(loaded.localPhoto(machine.id), [1, 2, 3]);
    expect(loaded.machineById(machine.id).records.last.gymId, id);
    app.dispose();
    loaded.dispose();
  });

  test('CSV com aspas e nomes conhecidos importa sem duplicar', () async {
    final rows = CsvHistoryImportService.parse(
      'date,exercise,weight,repetitions\n'
      '2026-11-20,"Supino reto com barra",80,10\n'
      '2026-11-20,"Exercício inexistente",20,12\n',
    );
    expect(rows.length, 2);
    final store = MemoryLocalDataStore();
    final app = AppController(persistenceEnabled: false, store: store);
    await app.loadPreferences();
    final first = app.importCsvEntries(rows);
    expect(first.imported, 1);
    expect(first.unmatched, 1);
    final second = app.importCsvEntries(rows);
    expect(second.imported, 0);
    expect(second.skipped, 1);
    await app.flushPendingWrites();
    final reopened = AppController(persistenceEnabled: false, store: store);
    await reopened.loadPreferences();
    expect(reopened.machineById('barbell_bench_press').records
      .any((r) => r.weight == 80 && r.repetitions == 10), isTrue);
    app.dispose();
    reopened.dispose();
  });

  test('CSV básico continua disponível sem assinatura Pro', () async {
    final app = AppController(persistenceEnabled: false);
    expect(app.isPro, isFalse);
    final machine = app.ensureMachineAdded(
      buildExerciseCatalog().firstWhere((e) => e.id == 'barbell_bench_press'),
    );
    app.addRecord(machine, weight: 45, repetitions: 8);
    final csv = ReportExportService.toCsv(ReportExportService.entries(
      machines: app.machines,
      cardioActivities: app.cardioActivities,
      period: AnalyticsPeriod.all,
      now: DateTime.now().add(const Duration(minutes: 1)),
    ));
    expect(csv, contains('"repetitions"'));
    expect(csv, contains('"8"'));
    app.dispose();
  });

  test('backup v1 legado ganha ID estável e mantém séries', () async {
    final store = MemoryLocalDataStore();
    final app = AppController(persistenceEnabled: false, store: store);
    final backup = <String, dynamic>{
      'schemaVersion': 1,
      'machines': [
        {
          'id': 'barbell_bench_press',
          'name': 'Supino reto com barra',
          'note': '',
          'group': 'chest',
          'equipment': 'barbell',
          'custom': false,
          'records': [
            {
              'date': DateTime.utc(2026, 11, 18).toIso8601String(),
              'weight': 100,
              'repetitions': 3,
              'durationSeconds': null,
            },
          ],
        },
      ],
      'cardio': <String, dynamic>{},
    };
    await app.importBackup(jsonEncode(backup));
    final first = app.machineById('barbell_bench_press').records.single;
    expect(first.id, startsWith('legacy_barbell_bench_press'));
    expect(first.repetitions, 3);
    await app.flushPendingWrites();
    final next = AppController(persistenceEnabled: false, store: store);
    await next.loadPreferences();
    final loaded = next.machineById('barbell_bench_press').records.single;
    expect(loaded.id, first.id);
    expect(loaded.repetitions, 3);
    app.dispose();
    next.dispose();
  });

  test('aquecimento não substitui PR; CSV conserva reps', () async {
    final app = AppController(persistenceEnabled: false);
    final machine = app.ensureMachineAdded(
      buildExerciseCatalog().firstWhere((e) => e.id == 'barbell_bench_press'),
    );
    app.addRecord(machine, weight: 120, repetitions: 5, isWarmup: true);
    app.addRecord(machine, weight: 80, repetitions: 10);
    expect(machine.recordWeight, 80);
    final entries = ReportExportService.entries(
      machines: app.machines,
      cardioActivities: app.cardioActivities,
      period: AnalyticsPeriod.all,
      now: DateTime.now().add(const Duration(minutes: 1)),
    );
    final csv = ReportExportService.toCsv(entries);
    expect(csv, contains('"repetitions"'));
    expect(csv, contains('"warmup"'));
    expect(csv, contains('"10"'));
    app.dispose();
  });
}
