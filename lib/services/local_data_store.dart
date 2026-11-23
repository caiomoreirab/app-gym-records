import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

/// Persists the user's private workout history. No network is used.
///
/// Android/iOS: SQLite. Web preview and desktop: local preferences.
/// Inject [MemoryLocalDataStore] for deterministic tests.
abstract class LocalDataStore {
  Future<Map<String, dynamic>?> load();
  Future<void> save(Map<String, dynamic> snapshot);
  Future<void> close() async {}

  factory LocalDataStore.production() {
    if (kIsWeb) return PreferencesLocalDataStore();
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return SqliteLocalDataStore();
      default:
        return PreferencesLocalDataStore();
    }
  }
}

/// SQLite v2: immutable backup snapshot + transactional relational indexes.
///
/// The canonical v2 JSON remains the compatibility/backup source of truth,
/// while normalized projection tables support future local queries without a
/// destructive migration. Every write updates both in one SQLite transaction.
class SqliteLocalDataStore implements LocalDataStore {
  Database? _database;

  Future<Database> _open() async {
    final current = _database;
    if (current != null && current.isOpen) return current;
    // Keep the old database name: switching files would lose existing users.
    final path = p.join(await getDatabasesPath(), 'gymrecords_v1.db');
    final db = await openDatabase(
      path,
      version: 2,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (database, version) async {
        await database.execute(
          'CREATE TABLE user_state ('
          'id INTEGER PRIMARY KEY, '
          'payload TEXT NOT NULL, updated_at TEXT NOT NULL)',
        );
        await _createV2Tables(database);
      },
      onUpgrade: (database, oldVersion, newVersion) async {
        if (oldVersion < 2) await _createV2Tables(database);
        // Existing user_state rows remain untouched and readable.
      },
    );
    _database = db;
    return db;
  }

  static Future<void> _createV2Tables(Database database) async {
    await database.execute(
      'CREATE TABLE IF NOT EXISTS user_state_previous ('
      'id INTEGER PRIMARY KEY, payload TEXT NOT NULL, '
      'updated_at TEXT NOT NULL)',
    );
    await database.execute(
      'CREATE TABLE IF NOT EXISTS workout_sessions ('
      'id TEXT PRIMARY KEY, name TEXT NOT NULL, '
      'started_at TEXT NOT NULL, completed_at TEXT)',
    );
    await database.execute(
      'CREATE TABLE IF NOT EXISTS session_exercises ('
      'session_id TEXT NOT NULL, exercise_id TEXT NOT NULL, '
      'position INTEGER NOT NULL, completed INTEGER NOT NULL DEFAULT 0 '
      'CHECK(completed IN (0,1)), '
      'PRIMARY KEY(session_id, exercise_id), '
      'FOREIGN KEY(session_id) REFERENCES workout_sessions(id) '
      'ON DELETE CASCADE)',
    );
    await database.execute(
      'CREATE TABLE IF NOT EXISTS workout_sets ('
      'record_id TEXT PRIMARY KEY, session_id TEXT NOT NULL, '
      'exercise_id TEXT NOT NULL, occurred_at TEXT NOT NULL, '
      'weight_kg REAL NOT NULL CHECK(weight_kg >= 0), '
      'repetitions INTEGER, duration_seconds INTEGER, '
      'is_warmup INTEGER NOT NULL DEFAULT 0 CHECK(is_warmup IN (0,1)), '
      'rpe REAL, rir INTEGER, rest_seconds INTEGER, note TEXT, '
      'FOREIGN KEY(session_id) REFERENCES workout_sessions(id) '
      'ON DELETE CASCADE)',
    );
    await database.execute(
      'CREATE TABLE IF NOT EXISTS cardio_entries ('
      'entry_key TEXT PRIMARY KEY, activity_id TEXT NOT NULL, '
      'occurred_at TEXT NOT NULL, duration_seconds INTEGER, '
      'distance_km REAL, calories REAL)',
    );
    await database.execute(
      'CREATE INDEX IF NOT EXISTS idx_sets_session_date '
      'ON workout_sets(session_id, occurred_at)',
    );
    await database.execute(
      'CREATE INDEX IF NOT EXISTS idx_sets_exercise_date '
      'ON workout_sets(exercise_id, occurred_at)',
    );
    await database.execute(
      'CREATE INDEX IF NOT EXISTS idx_cardio_activity_date '
      'ON cardio_entries(activity_id, occurred_at)',
    );
  }

  @override
  Future<Map<String, dynamic>?> load() async {
    final db = await _open();
    final rows = await db.query('user_state', columns: ['payload'],
      where: 'id = ?', whereArgs: [1], limit: 1);
    if (rows.isEmpty) return null;
    final decoded = jsonDecode(rows.first['payload'] as String);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Dados locais não puderam ser lidos.');
    }
    return decoded;
  }

  Future<Map<String, dynamic>?> loadPreviousSnapshot() async {
    final db = await _open();
    final rows = await db.query('user_state_previous', columns: ['payload'],
      where: 'id = ?', whereArgs: [1], limit: 1);
    if (rows.isEmpty) return null;
    final decoded = jsonDecode(rows.first['payload'] as String);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Cópia local anterior inválida.');
    }
    return decoded;
  }

  @override
  Future<void> save(Map<String, dynamic> snapshot) async {
    final db = await _open();
    final json = jsonEncode(snapshot);
    final now = DateTime.now().toUtc().toIso8601String();
    await db.transaction((txn) async {
      final old = await txn.query('user_state', columns: ['payload'],
        where: 'id = ?', whereArgs: [1], limit: 1);
      if (old.isNotEmpty && old.first['payload'] != json) {
        await txn.insert('user_state_previous', {
          'id': 1,
          'payload': old.first['payload'],
          'updated_at': now,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      // Previous snapshot and new snapshot are committed atomically.
      await txn.insert('user_state', {
        'id': 1, 'payload': json, 'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await _rebuildIndexes(txn, snapshot);
    });
  }

  /// Read-only projections of the canonical snapshot. Legacy JSON stays
  /// intact, while all future workout queries have indexed SQL tables.
  static Future<void> _rebuildIndexes(
      Transaction txn, Map<String, dynamic> snapshot) async {
    // Children first, respecting foreign key constraints.
    await txn.delete('workout_sets');
    await txn.delete('session_exercises');
    await txn.delete('workout_sessions');
    await txn.delete('cardio_entries');

    final rawSessions = snapshot['sessions'];
    final sessions = rawSessions is List ? rawSessions : const [];
    final ids = <String>{};
    for (final raw in sessions) {
      if (raw is! Map || raw['id'] is! String) {
        throw const FormatException('Sessão inválida para indexação.');
      }
      final id = raw['id'] as String;
      ids.add(id);
      await txn.insert('workout_sessions', {
        'id': id,
        'name': raw['name']?.toString() ?? 'Treino',
        'started_at': raw['startedAt']?.toString() ?? '',
        'completed_at': raw['completedAt']?.toString(),
      });
      final list = raw['exerciseIds'];
      final done = raw['completedExerciseIds'] is List
          ? (raw['completedExerciseIds'] as List).toSet() : const <Object>{};
      if (list is List) {
        for (var i = 0; i < list.length; i++) {
          await txn.insert('session_exercises', {
            'session_id': id, 'exercise_id': list[i],
            'position': i, 'completed': done.contains(list[i]) ? 1 : 0,
          });
        }
      }
    }

    final rawMachines = snapshot['machines'];
    if (rawMachines is List) {
      for (final machine in rawMachines) {
        if (machine is! Map) continue;
        final machineId = machine['id'];
        final records = machine['records'];
        if (machineId is! String || records is! List) continue;
        for (final record in records) {
          if (record is! Map) continue;
          final session = record['sessionId'];
          if (session is! String || !ids.contains(session)) {
            throw const FormatException(
              'Série sem sessão correspondente no banco.');
          }
          await txn.insert('workout_sets', {
            'record_id': record['id'],
            'session_id': session,
            'exercise_id': machineId,
            'occurred_at': record['date'],
            'weight_kg': record['weight'] ?? 0,
            'repetitions': record['repetitions'],
            'duration_seconds': record['durationSeconds'],
            'is_warmup': record['warmup'] == true ? 1 : 0,
            'rpe': record['rpe'],
            'rir': record['rir'],
            'rest_seconds': record['restSeconds'],
            'note': record['note'] ?? '',
          });
        }
      }
    }

    final cardio = snapshot['cardio'];
    if (cardio is Map) {
      for (final activity in cardio.entries) {
        final records = activity.value;
        if (records is! List) continue;
        for (var index = 0; index < records.length; index++) {
          final record = records[index];
          if (record is! Map) continue;
          await txn.insert('cardio_entries', {
            'entry_key': '${activity.key}_$index',
            'activity_id': activity.key,
            'occurred_at': record['date'],
            'duration_seconds': record['seconds'],
            'distance_km': record['distanceKm'],
            'calories': record['calories'],
          });
        }
      }
    }
  }

  @override
  Future<void> close() async {
    final db = _database;
    _database = null;
    if (db != null && db.isOpen) await db.close();
  }
}

/// Browser preview: stores data locally in the browser's storage, not on a
/// server. Browser data is separate from Android/iOS and can be cleared.
class PreferencesLocalDataStore implements LocalDataStore {
  PreferencesLocalDataStore({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  // Phase 1 Web validation shares an origin with the classic main site.
  // A separate key prevents v2 snapshots from overwriting v1 user data.
  static const key = bool.fromEnvironment('GYM_PHASE1_PREVIEW')
      ? 'gymrecords_user_state_phase1_v2'
      : 'gymrecords_user_state_v1';
  final SharedPreferencesAsync _preferences;

  @override
  Future<void> close() async {}

  @override
  Future<Map<String, dynamic>?> load() async {
    final raw = await _preferences.getString(key);
    if (raw == null) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) throw const FormatException('Invalid local data');
    return decoded;
  }

  @override
  Future<void> save(Map<String, dynamic> snapshot) async {
    await _preferences.setString(key, jsonEncode(snapshot));
  }
}

class MemoryLocalDataStore implements LocalDataStore {
  Map<String, dynamic>? _snapshot;

  @override
  Future<void> close() async {}

  @override
  Future<Map<String, dynamic>?> load() async {
    final s = _snapshot;
    return s == null ? null : jsonDecode(jsonEncode(s)) as Map<String, dynamic>;
  }

  @override
  Future<void> save(Map<String, dynamic> snapshot) async {
    _snapshot = jsonDecode(jsonEncode(snapshot)) as Map<String, dynamic>;
  }
}
