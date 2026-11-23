import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:gymrecords/data/mock_data.dart';
import 'package:gymrecords/models/workout_record.dart';
import 'package:gymrecords/services/workout_snapshot_codec.dart';
import 'package:gymrecords/services/local_data_store.dart';
import 'package:gymrecords/state/app_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late String databasePath;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    databasePath = p.join(await getDatabasesPath(), 'gymrecords_v1.db');
  });

  setUp(() async {
    await deleteDatabase(databasePath);
  });

  tearDown(() async {
    await deleteDatabase(databasePath);
  });

  test('migra banco real v1 para v3 sem apagar snapshot e cria índices',
      () async {
    final before = <String, dynamic>{
      'schemaVersion': 1,
      'machines': [],
      'cardio': <String, dynamic>{},
      'sessions': [],
      'favorites': [],
      'activeSessionId': null,
    };
    final old = await openDatabase(databasePath, version: 1,
      onCreate: (db, version) async {
        await db.execute('CREATE TABLE user_state '
          '(id INTEGER PRIMARY KEY, payload TEXT NOT NULL, '
          'updated_at TEXT NOT NULL)');
      });
    await old.insert('user_state', {
      'id': 1, 'payload': jsonEncode(before), 'updated_at': '2026-11-22',
    });
    await old.close();

    final store = SqliteLocalDataStore();
    expect((await store.load())!['schemaVersion'], 1,
      reason: 'Migração não pode apagar o JSON v1 original.');
    final app = AppController(persistenceEnabled: false, store: store);
    await app.loadPreferences();
    final session = app.startSession();
    final exercise = app.ensureMachineAdded(buildExerciseCatalog()
      .firstWhere((m) => m.id == 'barbell_squat'));
    app.addRecord(exercise, weight: 80, repetitions: 8);
    app.setExerciseCompleted(exercise.id, true);
    await app.flushPendingWrites();
    expect(app.persistenceError, isNull);
    final db = await openDatabase(databasePath, version: 3);
    final sessions = await db.query('workout_sessions');
    final progress = await db.query('session_exercises');
    final sets = await db.query('workout_sets');
    expect(sessions.single['id'], session.id);
    expect(progress.single['exercise_id'], exercise.id);
    expect(progress.single['completed'], 1);
    expect(sets.single['weight_kg'], 80);
    expect(sets.single['repetitions'], 8);
    final indexes = (await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='index'"))
      .map((x) => x['name']).toSet();
    expect(indexes, contains('idx_sets_exercise_date'));
    expect(indexes, contains('idx_sets_session_date'));
    expect((await store.load())!['schemaVersion'], 2);
    expect(await store.loadPreviousSnapshot(), isNotNull);
    await db.close();
    app.dispose();
    await store.close();
  });

  test('histórico preenchido no SQLite v1 migra sem perder séries', () async {
    final exercise = buildExerciseCatalog().firstWhere(
      (m) => m.id == 'barbell_squat');
    exercise.records.add(WorkoutRecord(
      date: DateTime(2026, 11, 18, 13, 30),
      weight: 65, repetitions: 6));
    final legacy = WorkoutSnapshotCodec.encode(
      machines: [exercise], cardioActivities: []);
    legacy['schemaVersion'] = 1;
    legacy.remove('sessions');
    final old = await openDatabase(databasePath, version: 1,
      onCreate: (db, version) async {
        await db.execute('CREATE TABLE user_state '
          '(id INTEGER PRIMARY KEY, payload TEXT NOT NULL, '
          'updated_at TEXT NOT NULL)');
      });
    await old.insert('user_state', {
      'id': 1, 'payload': jsonEncode(legacy),
      'updated_at': '2026-11-18',
    });
    await old.close();

    final store = SqliteLocalDataStore();
    // The relational projection is rebuilt immediately at migration time,
    // even before the legacy JSON is saved in the modern format.
    expect((await store.load())!['schemaVersion'], 1);
    final migratedDb = await openDatabase(databasePath, version: 3);
    final migratedSets = await migratedDb.query('workout_sets');
    expect(migratedSets.length, 1);
    expect(migratedSets.single['weight_kg'], 65);
    expect((await migratedDb.query('workout_sessions')).length, 1);
    await migratedDb.close();
    final app = AppController(persistenceEnabled: false, store: store);
    await app.loadPreferences();
    final restored = app.machineById(exercise.id);
    expect(restored.records.length, 1);
    expect(restored.records.single.weight, 65);
    app.startSession();
    app.addRecord(restored, weight: 70, repetitions: 5);
    await app.flushPendingWrites();
    expect(app.persistenceError, isNull);
    final db = await openDatabase(databasePath, version: 3);
    final rows = await db.query('workout_sets');
    expect(rows.length, 2);
    expect(rows.map((r) => r['weight_kg']),
      containsAll([65, 70]));
    await db.close();
    app.dispose();
    await store.close();
  });

  test('falha ao indexar não sobrescreve snapshot válido', () async {
    final store = SqliteLocalDataStore();
    final valid = <String, dynamic>{
      'schemaVersion': 2,
      'machines': [],
      'cardio': {},
      'sessions': [],
      'favorites': [],
      'activeSessionId': null,
    };
    await store.save(valid);
    final bad = jsonDecode(jsonEncode(valid)) as Map<String, dynamic>;
    bad['machines'] = [{
      'id': 'barbell_bench_press',
      'records': [{
        'id': 'invalid',
        'sessionId': 'session_not_found',
        'date': '2026-11-23T13:00:00Z',
        'weight': 100, 'repetitions': 8,
      }],
    }];
    await expectLater(store.save(bad), throwsFormatException);
    expect(await store.load(), valid);
    await store.close();
  });

  test('snapshot anterior é recuperável após alteração', () async {
    final store = SqliteLocalDataStore();
    final original = <String, dynamic>{
      'schemaVersion': 2,
      'machines': [], 'cardio': {}, 'sessions': [],
      'favorites': [], 'activeSessionId': null,
    };
    await store.save(original);
    final next = {...original, 'favorites': ['barbell_squat']};
    await store.save(next);
    expect((await store.loadPreviousSnapshot())!['favorites'], isEmpty);
    expect((await store.load())!['favorites'], ['barbell_squat']);
    await store.close();
  });

  test('v2 com grupos, cardio e séries migra para v3 sem perder dados', () async {
    final date = DateTime.utc(2026, 11, 23, 13);
    final original = <String, dynamic>{
      'schemaVersion': 2,
      'activeSessionId': 's1',
      'favorites': ['barbell_bench_press'],
      'sessions': [{
        'id': 's1', 'name': 'Peito + corrida',
        'startedAt': date.toIso8601String(), 'completedAt': null,
        'exerciseIds': ['barbell_bench_press'],
        'completedExerciseIds': ['barbell_bench_press'],
        'selectedGroupIds': ['chest', 'cardio'],
        'plannedCardioIds': ['outdoor_run'],
      }],
      'machines': [{
        'id': 'barbell_bench_press', 'custom': false,
        'name': 'Supino reto com barra', 'note': '', 'group': 'chest',
        'equipment': 'barbell',
        'records': [{
          'id': 'set1', 'sessionId': 's1', 'date': date.toIso8601String(),
          'weight': 80.0, 'repetitions': 8, 'durationSeconds': null,
          'warmup': false, 'rpe': null, 'rir': null,
          'restSeconds': 90, 'note': '',
        }],
      }],
      'cardio': {
        'outdoor_run': [{
          'date': date.toIso8601String(), 'seconds': 600,
          'distanceKm': 2.0, 'heartRateBpm': 120,
          'calories': null, 'inclinePercent': null,
          'resistanceLevel': null, 'notes': '',
          'sessionId': 's1',
        }],
      },
    };
    final old = await openDatabase(databasePath, version: 2,
      onCreate: (db, version) async {
        await db.execute('CREATE TABLE user_state ('
          'id INTEGER PRIMARY KEY, payload TEXT NOT NULL,'
          'updated_at TEXT NOT NULL)');
        await db.execute('CREATE TABLE user_state_previous ('
          'id INTEGER PRIMARY KEY, payload TEXT NOT NULL,'
          'updated_at TEXT NOT NULL)');
        await db.execute('CREATE TABLE workout_sessions ('
          'id TEXT PRIMARY KEY, name TEXT NOT NULL,'
          'started_at TEXT NOT NULL, completed_at TEXT)');
        await db.execute('CREATE TABLE session_exercises ('
          'session_id TEXT NOT NULL, exercise_id TEXT NOT NULL,'
          'position INTEGER NOT NULL, completed INTEGER NOT NULL,'
          'PRIMARY KEY(session_id, exercise_id))');
        await db.execute('CREATE TABLE workout_sets ('
          'record_id TEXT PRIMARY KEY, session_id TEXT NOT NULL,'
          'exercise_id TEXT NOT NULL, occurred_at TEXT NOT NULL,'
          'weight_kg REAL NOT NULL, repetitions INTEGER,'
          'duration_seconds INTEGER, is_warmup INTEGER,'
          'rpe REAL, rir INTEGER, rest_seconds INTEGER, note TEXT)');
        await db.execute('CREATE TABLE cardio_entries ('
          'entry_key TEXT PRIMARY KEY, activity_id TEXT NOT NULL,'
          'occurred_at TEXT NOT NULL, duration_seconds INTEGER,'
          'distance_km REAL, calories REAL)');
      });
    await old.insert('user_state', {
      'id': 1, 'payload': jsonEncode(original), 'updated_at': '2026-11-23',
    });
    await old.close();

    final store = SqliteLocalDataStore();
    expect(await store.load(), original,
      reason: 'Upgrade must keep the original canonical snapshot.');
    final db = await openDatabase(databasePath, version: 3);
    final groups = await db.query('session_groups',
      orderBy: 'position ASC');
    final planned = await db.query('session_cardio');
    final cardio = await db.query('cardio_entries');
    final sets = await db.query('workout_sets');
    expect(groups.map((x) => x['group_id']).toList(), ['chest', 'cardio']);
    expect(planned.single['activity_id'], 'outdoor_run');
    expect(cardio.single['session_id'], 's1');
    expect(cardio.single['duration_seconds'], 600);
    expect(sets.single['weight_kg'], 80.0);
    expect(sets.single['repetitions'], 8);
    expect((await db.rawQuery('PRAGMA foreign_key_check')), isEmpty);
    final cols = await db.rawQuery('PRAGMA table_info(cardio_entries)');
    expect(cols.map((x) => x['name']), contains('session_id'));
    await db.close();

    final app = AppController(persistenceEnabled: false, store: store);
    await app.loadPreferences();
    expect(app.storageRecoveryRequired, isFalse);
    expect(app.activeSession?.selectedGroupIds, ['chest', 'cardio']);
    expect(app.activeSession?.plannedCardioIds, ['outdoor_run']);
    expect(app.recordsForSession('s1').single.weight, 80);
    expect(app.cardioActivities.first.records.single.sessionId, 's1');
    app.setActiveSessionGroups(['legs']);
    await app.flushPendingWrites();
    final savedDb = await openDatabase(databasePath, version: 3);
    expect((await savedDb.query('session_groups')).single['group_id'], 'legs');
    expect((await savedDb.query('workout_sets')).length, 1);
    expect((await savedDb.query('cardio_entries')).length, 1);
    await savedDb.close();
    app.dispose();
    await store.close();
  });

  test('importar snapshot legado v1 indexa séries sem exigir novo registro',
      () async {
    final store = SqliteLocalDataStore();
    final exercise = buildExerciseCatalog().firstWhere(
      (m) => m.id == 'barbell_bench_press');
    exercise.records.add(WorkoutRecord(
      date: DateTime.utc(2026, 11, 10), weight: 45, repetitions: 10));
    final legacy = WorkoutSnapshotCodec.encode(
      machines: [exercise], cardioActivities: []);
    legacy['schemaVersion'] = 1;
    legacy.remove('sessions');
    await store.save(legacy);
    expect((await store.load())!['schemaVersion'], 1);
    final db = await openDatabase(databasePath, version: 3);
    expect((await db.query('workout_sets')).length, 1);
    expect((await db.query('workout_sessions')).length, 1);
    expect((await db.query('session_groups')), isEmpty);
    expect((await db.query('session_cardio')), isEmpty);
    await db.close();
    await store.close();
  });

  test('v3 rejects broken cardio projection without losing prior state',
      () async {
    final store = SqliteLocalDataStore();
    final original = <String, dynamic>{
      'schemaVersion': 2, 'machines': [],
      'cardio': {}, 'sessions': [], 'favorites': [],
      'activeSessionId': null,
    };
    await store.save(original);
    final invalid = jsonDecode(jsonEncode(original)) as Map<String, dynamic>;
    invalid['cardio'] = {
      'outdoor_run': [{
        'date': '2026-11-23T13:00:00Z', 'seconds': 900,
        'distanceKm': -1, 'notes': '',
        'sessionId': 'old',
      }]
    };
    await expectLater(store.save(invalid), throwsA(isA<Exception>()));
    expect(await store.load(), original);
    await store.close();
  });

}
