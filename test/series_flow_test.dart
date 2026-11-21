import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymrecords/data/mock_data.dart';
import 'package:gymrecords/models/workout_record.dart';
import 'package:gymrecords/services/local_data_store.dart';
import 'package:gymrecords/services/report_export_service.dart';
import 'package:gymrecords/services/analytics_service.dart';
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
