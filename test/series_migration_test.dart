import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymrecords/data/mock_data.dart';
import 'package:gymrecords/state/app_controller.dart';
import 'package:gymrecords/services/local_data_store.dart';
import 'package:gymrecords/services/workout_snapshot_codec.dart';

void main() {
  test('migração v1 preserva duas séries iguais sem deduplicar', () async {
    final store = MemoryLocalDataStore();
    final app = AppController(persistenceEnabled: false, store: store);
    final payload = jsonDecode(app.exportBackup()) as Map<String, dynamic>;
    payload['schemaVersion'] = 1;
    payload.remove('sessions');
    payload.remove('activeSessionId');
    payload.remove('favorites');
    (payload['machines'] as List).add({
      'id': 'barbell_bench_press',
      'custom': false,
      'name': 'Supino reto com barra',
      'note': '',
      'group': 'chest',
      'equipment': 'barbell',
      'records': [
        {'date': '2026-11-20T11:00:00.000Z', 'weight': 100.0,
         'repetitions': 3, 'durationSeconds': null},
        {'date': '2026-11-20T11:05:00.000Z', 'weight': 100.0,
         'repetitions': 3, 'durationSeconds': null},
      ],
    });
    await app.importBackup(jsonEncode(payload));
    final records = app.machineById('barbell_bench_press').records;
    expect(records.length, 2);
    expect(records.map((r) => r.repetitions), [3, 3]);
    expect(records.map((r) => r.weight), [100.0, 100.0]);
    expect(records[0].id, isNot(records[1].id));
    expect(records[0].effectiveSessionId, records[1].effectiveSessionId);
    final upgraded = jsonDecode(app.exportBackup()) as Map<String, dynamic>;
    expect(upgraded['schemaVersion'], 2);
    expect((upgraded['sessions'] as List).length, 1);
    app.dispose();
  });

  test('nova sessão, repetir série, edição, exclusão e restauração', () async {
    final store = MemoryLocalDataStore();
    final app = AppController(persistenceEnabled: false, store: store);
    await app.loadPreferences();
    final machine = app.ensureMachineAdded(
      buildExerciseCatalog().firstWhere((m) => m.id == 'barbell_bench_press'));
    final first = app.addRecord(machine, weight: 100, repetitions: 3);
    final second = app.addRecord(machine,
      weight: first.weight, repetitions: first.repetitions);
    expect(app.recordsForSession(first.sessionId).length, 2);
    expect(first.id, isNot(second.id));
    app.replaceRecord(machine, second.copyWith(weight: 102.5));
    expect(machine.records.last.weight, 102.5);
    final removed = app.removeRecord(machine, second.id);
    expect(machine.records.length, 1);
    app.restoreRecord(machine, removed);
    expect(machine.records.length, 2);
    app.completeSession();
    final next = app.startSession(name: 'Treino B');
    app.addRecord(machine, weight: 90, repetitions: 8);
    expect(next.id, isNot(first.sessionId));
    expect(app.recordsForSession(next.id).length, 1);
    await app.flushPendingWrites();
    final reopened = AppController(persistenceEnabled: false, store: store);
    await reopened.loadPreferences();
    expect(reopened.sessions.length, 2);
    expect(reopened.machineById(machine.id).records.length, 3);
    app.dispose();
    reopened.dispose();
  });

  test('lê backup experimental v1 mantendo metadados desconhecidos', () async {
    final app = AppController(persistenceEnabled: false,
      store: MemoryLocalDataStore());
    final raw = jsonDecode(app.exportBackup()) as Map<String, dynamic>;
    raw['schemaVersion'] = 1;
    raw['gyms'] = {'default': 'Minha academia'};
    raw['targetWeights'] = {'barbell_bench_press': 100.0};
    (raw['machines'] as List).add({
      'id': 'barbell_bench_press', 'custom': false,
      'name': 'Supino reto com barra', 'note': '',
      'group': 'chest', 'equipment': 'barbell',
      'adjustments': {'bench': '3'},
      'records': [{
        'id': 'set_experimental', 'sessionId': 'session_old',
        'date': '2026-11-20T11:00:00.000Z',
        'weight': 100, 'repetitions': 3,
        'durationSeconds': null, 'warmup': true,
        'rpe': 8, 'gymId': 'default',
      }],
    });
    await app.importBackup(jsonEncode(raw));
    final upgraded = jsonDecode(app.exportBackup()) as Map<String, dynamic>;
    expect(upgraded['gyms'], raw['gyms']);
    expect(upgraded['targetWeights'], raw['targetWeights']);
    final m = (upgraded['machines'] as List).single as Map;
    expect(m['adjustments'], {'bench': '3'});
    final rec = (m['records'] as List).single as Map;
    expect(rec['id'], 'set_experimental');
    expect(rec['gymId'], 'default');
    expect(rec['warmup'], isTrue);
    expect(rec['rpe'], 8);
    app.dispose();
  });
}
