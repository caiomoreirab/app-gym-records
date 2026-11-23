import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:gymrecords/data/mock_data.dart';
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

  test('migra banco real v1 para v2 sem apagar snapshot e cria índices',
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
    final db = await openDatabase(databasePath, version: 2);
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
}
