import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymrecords/data/mock_data.dart';
import 'package:gymrecords/models/cardio_record.dart';
import 'package:gymrecords/models/muscle_group.dart';
import 'package:gymrecords/services/local_data_store.dart';
import 'package:gymrecords/services/usage_events.dart';
import 'package:gymrecords/state/app_controller.dart';

void main() {
  test('registros de musculação e cardio sobrevivem a uma nova sessão', () async {
    final store = MemoryLocalDataStore();
    final first = AppController(persistenceEnabled: false, store: store);
    await first.loadPreferences();

    final exercise = first.ensureMachineAdded(
      buildExerciseCatalog().firstWhere((item) => item.id == 'barbell_bench_press'),
    );
    first.addRecord(exercise, weight: 75, repetitions: 8);
    first.updateMachineNote(exercise, 'Pausa de dois segundos');
    first.addCustomMachine(name: 'Minha máquina', group: MuscleGroup.chest);
    final cardio = first.cardioActivities.firstWhere((item) => item.id == 'jump_rope');
    first.addCardioRecord(cardio, CardioRecord(
      date: DateTime(2026, 11, 19),
      duration: const Duration(minutes: 14),
    ));
    await first.flushPendingWrites();

    final second = AppController(persistenceEnabled: false, store: store);
    await second.loadPreferences();
    final loaded = second.machineById('barbell_bench_press');
    expect(loaded.records.last.weight, 75);
    expect(loaded.records.last.repetitions, 8);
    expect(loaded.note, 'Pausa de dois segundos');
    expect(second.machines.any((machine) => machine.isCustom && machine.name == 'Minha máquina'), isTrue);
    expect(second.cardioActivities.firstWhere((item) => item.id == 'jump_rope').records.last.duration.inMinutes, 14);
    first.dispose();
    second.dispose();
  });

  test('backup JSON é restaurável e backup inválido não apaga os treinos', () async {
    final store = MemoryLocalDataStore();
    final app = AppController(persistenceEnabled: false, store: store);
    await app.loadPreferences();
    final machine = app.ensureMachineAdded(
      buildExerciseCatalog().firstWhere((item) => item.id == 'barbell_bench_press'),
    );
    app.addRecord(machine, weight: 82.5, repetitions: 5);
    await app.flushPendingWrites();
    final json = app.exportBackup();

    await expectLater(app.importBackup('{"schemaVersion":999,"machines":[],"cardio":{}}'),
        throwsA(isA<FormatException>()));
    expect(app.machineById('barbell_bench_press').records.last.weight, 82.5);

    final newApp = AppController(persistenceEnabled: false, store: MemoryLocalDataStore());
    await newApp.importBackup(json);
    expect(newApp.machineById('barbell_bench_press').records.last.weight, 82.5);
    app.dispose();
    newApp.dispose();
  });

  test('eventos anônimos só são registrados após consentimento', () async {
    final sink = MemoryUsageEventSink();
    final app = AppController(persistenceEnabled: false, analyticsSink: sink);
    app.trackUsage('app_opened');
    await Future<void>.delayed(Duration.zero);
    expect(sink.events, isEmpty);

    app.setAnalyticsConsent(true);
    app.trackUsage('app_opened');
    await Future<void>.delayed(Duration.zero);
    expect(sink.events.single.name, 'app_opened');
    expect(sink.events.single.attributes, isEmpty);
    app.dispose();
  });

  test('permite retentar gravação após erro temporário', () async {
    final store = _FlakyDataStore();
    final controller = AppController(persistenceEnabled: false, store: store);
    await controller.loadPreferences();
    final exercise = controller.ensureMachineAdded(
      buildExerciseCatalog().firstWhere((m) => m.id == 'barbell_bench_press'),
    );
    store.rejectWrites = true;
    controller.addRecord(exercise, weight: 65, repetitions: 10);
    await controller.flushPendingWrites();
    expect(controller.persistenceError, isNotNull);
    expect(store.writes, 0); // no snapshot was committed while storage was failing.
    store.rejectWrites = false;
    expect(await controller.retrySave(), isTrue);
    expect(controller.persistenceError, isNull);
    final next = AppController(persistenceEnabled: false, store: store);
    await next.loadPreferences();
    expect(next.machineById(exercise.id).records.single.weight, 65);
    controller.dispose();
    next.dispose();
  });

  test('não sobrescreve um banco se a leitura inicial falhar', () async {
    final store = _FlakyDataStore()..rejectReads = true;
    final controller = AppController(persistenceEnabled: false, store: store);
    await controller.loadPreferences();
    expect(controller.storageRecoveryRequired, isTrue);
    final exercise = controller.ensureMachineAdded(
      buildExerciseCatalog().firstWhere((m) => m.id == 'barbell_bench_press'),
    );
    controller.addRecord(exercise, weight: 99);
    await controller.flushPendingWrites();
    expect(store.writes, 0);
    expect(await controller.retrySave(), isFalse);
    expect(store.writes, 0);
    controller.dispose();
  });

  test('backup mantém exercícios e atividades descontinuadas', () async {
    final store = MemoryLocalDataStore();
    final controller = AppController(persistenceEnabled: false, store: store);
    final data = jsonDecode(controller.exportBackup()) as Map<String, dynamic>;
    final oldDate = DateTime.utc(2025, 8, 15).toIso8601String();
    (data['machines'] as List).add({
      'id': 'legacy_movement_0001',
      'name': 'Meu exercício antigo',
      'custom': false,
      'note': 'Preservar histórico',
      'group': 'chest',
      'equipment': 'barbell',
      'records': [
        {'date': oldDate, 'weight': 71.5,
         'repetitions': 8, 'durationSeconds': null}
      ],
    });
    (data['cardio'] as Map<String, dynamic>)['legacy_cardio_001'] = [
      {'date': oldDate, 'seconds': 1540, 'distanceKm': 4.2,
       'heartRateBpm': null, 'calories': null, 'inclinePercent': null,
       'resistanceLevel': null, 'notes': ''}
    ];
    await controller.importBackup(jsonEncode(data));
    expect(controller.machineById('legacy_movement_0001').isCustom, isTrue);
    final saved = jsonDecode(controller.exportBackup()) as Map<String, dynamic>;
    expect((saved['cardio'] as Map).containsKey('legacy_cardio_001'), isTrue);

    final next = AppController(persistenceEnabled: false, store: store);
    await next.loadPreferences();
    expect(next.machineById('legacy_movement_0001').records.single.weight, 71.5);
    final afterRestart = jsonDecode(next.exportBackup()) as Map<String, dynamic>;
    expect(((afterRestart['cardio'] as Map)['legacy_cardio_001'] as List).length, 1);
    controller.dispose();
    next.dispose();
  });
}

class _FlakyDataStore implements LocalDataStore {
  bool rejectReads = false;
  bool rejectWrites = false;
  int writes = 0;
  Map<String, dynamic>? snapshot;

  @override
  Future<Map<String, dynamic>?> load() async {
    if (rejectReads) throw StateError('test read failure');
    return snapshot == null
        ? null
        : jsonDecode(jsonEncode(snapshot)) as Map<String, dynamic>;
  }

  @override
  Future<void> save(Map<String, dynamic> value) async {
    if (rejectWrites) throw StateError('test storage full');
    writes++;
    snapshot = jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
  }

  @override
  Future<void> close() async {}
}
