import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymrecords/data/mock_data.dart';
import 'package:gymrecords/services/analytics_service.dart';
import 'package:gymrecords/services/local_data_store.dart';
import 'package:gymrecords/services/report_export_service.dart';
import 'package:gymrecords/state/app_controller.dart';

void main() {
  test('maquinas de musculacao sempre permitem repeticoes', () {
    final machine = buildExerciseCatalog()
        .firstWhere((m) => m.id == 'chest_press_machine');
    expect(machine.supportsRepetitions, isTrue);
  });

  test('CRUD de series e favoritos persistem entre execucoes', () async {
    final store = MemoryLocalDataStore();
    final one = AppController(persistenceEnabled: false, store: store);
    await one.loadPreferences();
    final machine = one.ensureMachineAdded(
      buildExerciseCatalog().firstWhere((m) => m.id == 'barbell_bench_press'));
    one.toggleFavorite(machine.id);
    final first = one.addRecord(machine, weight: 100, repetitions: 3,
      at: DateTime(2026, 11, 20, 10));
    expect(first.repetitions, 3);
    expect(first.effectiveSessionId, 'day-2026-11-20');
    one.editRecord(machine, first, first.copyWith(weight: 95, repetitions: 8));
    final second = one.addRecord(machine, weight: 105, repetitions: 2,
      isWarmup: true, at: DateTime(2026, 11, 20, 10, 1));
    expect(machine.recordWeight, 95); // warmup never enters PR
    final deletedAt = one.deleteRecord(machine, second);
    one.restoreRecord(machine, second, deletedAt);
    await one.flushPendingWrites();

    final two = AppController(persistenceEnabled: false, store: store);
    await two.loadPreferences();
    final restored = two.machineById(machine.id);
    expect(two.isFavorite(machine.id), isTrue);
    expect(restored.records.length, 2);
    expect(restored.records.first.repetitions, 8);
    expect(restored.records.last.isWarmup, isTrue);
    expect(restored.recordWeight, 95);
    expect(two.todaysSets(restored, today: DateTime(2026, 11, 20)).length, 2);
    one.dispose(); two.dispose();
  });

  test('backup v1 e aceito e migrado sem apagar as series', () async {
    final store = MemoryLocalDataStore();
    final one = AppController(persistenceEnabled: false, store: store);
    final machine = one.ensureMachineAdded(
      buildExerciseCatalog().firstWhere((m) => m.id == 'barbell_bench_press'));
    one.addRecord(machine, weight: 80, repetitions: 10,
      at: DateTime(2026, 11, 20, 10));
    final legacy = jsonDecode(one.exportBackup()) as Map<String, dynamic>;
    legacy['schemaVersion'] = 1;
    legacy.remove('favorites');
    for (final entry in (legacy['machines'] as List)) {
      for (final record in (entry['records'] as List)) {
        record.remove('id');
        record.remove('sessionId');
        record.remove('isWarmup');
        record.remove('rpe');
        record.remove('note');
      }
    }
    final two = AppController(persistenceEnabled: false, store: MemoryLocalDataStore());
    await two.importBackup(jsonEncode(legacy));
    final restored = two.machineById(machine.id).records.single;
    expect(restored.repetitions, 10);
    expect(restored.id, startsWith('legacy-'));
    expect(restored.effectiveSessionId, 'day-2026-11-20');
    expect((jsonDecode(two.exportBackup()) as Map)['schemaVersion'], 2);
    one.dispose(); two.dispose();
  });

  test('CSV contem carga, repeticoes, sessao e numero da serie', () {
    final app = AppController(persistenceEnabled: false);
    final machine = app.ensureMachineAdded(
      buildExerciseCatalog().firstWhere((m) => m.id == 'barbell_bench_press'));
    final date = DateTime(2026, 11, 20, 10);
    app.addRecord(machine, weight: 100, repetitions: 3, at: date);
    app.addRecord(machine, weight: 95, repetitions: 8,
      at: date.add(const Duration(minutes: 1)));
    final entries = ReportExportService.entries(
      machines: [machine], cardioActivities: app.cardioActivities,
      period: AnalyticsPeriod.all, now: DateTime(2026, 11, 21));
    expect(entries.length, 2);
    expect(entries.any((e) => e.weight == 100 && e.repetitions == 3), isTrue);
    final csv = ReportExportService.toCsv(entries);
    expect(csv, contains('"session_id"'));
    expect(csv, contains('"set_number"'));
    expect(csv, contains('"3"'));
    expect(csv, contains('"8"'));
    expect(csv, contains('"day-2026-11-20"'));
    app.dispose();
  });
}
