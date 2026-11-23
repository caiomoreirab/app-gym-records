import 'dart:convert';

import '../data/mock_data.dart';
import '../models/machine.dart';
import 'workout_snapshot_codec.dart';

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

/// Read-only health report for the mobile SQLite database.
class LocalDatabaseStatus {
  const LocalDatabaseStatus({
    required this.schemaVersion,
    required this.sqliteQuickCheck,
    required this.foreignKeyProblems,
    required this.actualCounts,
    required this.expectedCounts,
  });

  final int schemaVersion;
  final String sqliteQuickCheck;
  final int foreignKeyProblems;
  final Map<String, int> actualCounts;
  final Map<String, int> expectedCounts;

  bool get isHealthy => schemaVersion == 3 &&
      sqliteQuickCheck == 'ok' && foreignKeyProblems == 0 &&
      expectedCounts.keys.every((key) =>
        actualCounts[key] == expectedCounts[key]);
}

/// SQLite v3: immutable backup snapshot + transactional relational indexes.
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
      version: 3,
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
        await _createV3Tables(database);
      },
      onUpgrade: (database, oldVersion, newVersion) async {
        if (oldVersion < 2) await _createV2Tables(database);
        if (oldVersion < 3) {
          await _createV3Tables(database);
          // Upgrade relational mirrors without modifying the historical JSON.
          // This also handles original v1 backups with implicit daily sessions.
          final rows = await database.query('user_state',
            columns: ['payload'], where: 'id = ?', whereArgs: [1], limit: 1);
          if (rows.isNotEmpty) {
            final payload = jsonDecode(rows.single['payload'] as String);
            if (payload is! Map<String, dynamic>) {
              throw const FormatException('Snapshot legado inválido.');
            }
            await _rebuildIndexes(database, _projectionSnapshot(payload));
          }
        }
        // Original user_state payload is never rewritten by migration.
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

  /// Additive, non-destructive v3 migration for planned groups/cardio and
  /// the link between a cardio record and its originating workout.
  static Future<void> _createV3Tables(DatabaseExecutor database) async {
    await database.execute(
      'CREATE TABLE IF NOT EXISTS session_groups ('
      'session_id TEXT NOT NULL, group_id TEXT NOT NULL, '
      'position INTEGER NOT NULL CHECK(position >= 0), '
      'PRIMARY KEY(session_id, group_id), '
      'FOREIGN KEY(session_id) REFERENCES workout_sessions(id) '
      'ON DELETE CASCADE)',
    );
    await database.execute(
      'CREATE TABLE IF NOT EXISTS session_cardio ('
      'session_id TEXT NOT NULL, activity_id TEXT NOT NULL, '
      'position INTEGER NOT NULL CHECK(position >= 0), '
      'PRIMARY KEY(session_id, activity_id), '
      'FOREIGN KEY(session_id) REFERENCES workout_sessions(id) '
      'ON DELETE CASCADE)',
    );
    await database.execute(
      'ALTER TABLE cardio_entries ADD COLUMN session_id TEXT',
    );
    await database.execute(
      'CREATE INDEX IF NOT EXISTS idx_cardio_session_date '
      'ON cardio_entries(session_id, occurred_at)',
    );
    await database.execute(
      'CREATE INDEX IF NOT EXISTS idx_group_session '
      'ON session_groups(group_id, session_id)',
    );
    await database.execute(
      'CREATE INDEX IF NOT EXISTS idx_planned_cardio '
      'ON session_cardio(activity_id, session_id)',
    );
  }

  /// Relational mirrors need normalized IDs even for imported legacy v1 JSON.
  /// Their historical payload itself is preserved byte-for-byte.
  static Map<String, dynamic> _projectionSnapshot(
      Map<String, dynamic> snapshot) {
    if (snapshot['schemaVersion'] == 2 && snapshot['sessions'] is List) {
      return snapshot;
    }
    final restored = WorkoutSnapshotCodec.decode(snapshot);
    final machines = <Machine>[];
    final cardioActivities = buildCardioActivities();
    final preserved = restored.applyTo(machines, cardioActivities);
    return WorkoutSnapshotCodec.encode(
      machines: machines,
      cardioActivities: cardioActivities,
      preservedCardio: preserved,
      sessions: restored.sessions,
      favorites: restored.favorites,
      activeSessionId: restored.activeSessionId,
      rootExtras: restored.rootExtras,
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

  /// Non-destructive integrity verification available to mobile testers.
  /// It checks SQLite pages, FK constraints and mirror counts vs the snapshot.
  Future<LocalDatabaseStatus> inspectIntegrity() async {
    final db = await _open();
    final quickRows = await db.rawQuery('PRAGMA quick_check');
    final quick = quickRows.isEmpty
      ? 'not available' : quickRows.first.values.first.toString();
    final foreignKeys = await db.rawQuery('PRAGMA foreign_key_check');
    final stored = await load();
    final projected = stored == null ? <String, dynamic>{
      'machines': const [], 'sessions': const [], 'cardio': const {},
    } : _projectionSnapshot(stored);
    final sessions = projected['sessions'] as List;
    final machines = projected['machines'] as List;
    final cardio = projected['cardio'] as Map;
    int countRecords(Iterable<dynamic> items, String field) =>
        items.fold<int>(0, (sum, item) =>
          sum + (item is Map && item[field] is List
            ? (item[field] as List).length : 0));
    final expected = <String, int>{
      'workout_sessions': sessions.length,
      'session_exercises': countRecords(sessions, 'exerciseIds'),
      'session_groups': countRecords(sessions, 'selectedGroupIds'),
      'session_cardio': countRecords(sessions, 'plannedCardioIds'),
      'workout_sets': countRecords(machines, 'records'),
      'cardio_entries': countRecords(cardio.values, 'records'),
    };
    // Cardio is stored as a map of lists rather than an array of objects.
    expected['cardio_entries'] = cardio.values.fold<int>(0, (sum, list) =>
      sum + (list is List ? list.length : 0));
    final actual = <String, int>{};
    for (final table in expected.keys) {
      final result = await db.rawQuery('SELECT COUNT(*) AS count FROM $table');
      actual[table] = result.single['count'] as int;
    }
    return LocalDatabaseStatus(
      schemaVersion: await db.getVersion(),
      sqliteQuickCheck: quick,
      foreignKeyProblems: foreignKeys.length,
      actualCounts: actual,
      expectedCounts: expected,
    );
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
      await _rebuildIndexes(txn, _projectionSnapshot(snapshot));
    });
  }

  /// Read-only projections of the canonical snapshot. Legacy JSON stays
  /// intact, while all future workout queries have indexed SQL tables.
  static Future<void> _rebuildIndexes(
      DatabaseExecutor txn, Map<String, dynamic> snapshot) async {
    // One batch keeps projection updates fast as the history grows.
    final batch = txn.batch();
    // Children first, respecting foreign key constraints.
    batch.delete('workout_sets');
    batch.delete('session_exercises');
    batch.delete('session_groups');
    batch.delete('session_cardio');
    batch.delete('workout_sessions');
    batch.delete('cardio_entries');

    final rawSessions = snapshot['sessions'];
    final sessions = rawSessions is List ? rawSessions : const [];
    final ids = <String>{};
    for (final raw in sessions) {
      if (raw is! Map || raw['id'] is! String) {
        throw const FormatException('Sessão inválida para indexação.');
      }
      final id = raw['id'] as String;
      ids.add(id);
      batch.insert('workout_sessions', {
        'id': id,
        'name': raw['name']?.toString() ?? 'Treino',
        'started_at': raw['startedAt']?.toString() ?? '',
        'completed_at': raw['completedAt']?.toString(),
      });
      final groupIds = raw['selectedGroupIds'];
      if (groupIds is List) {
        for (var i = 0; i < groupIds.length; i++) {
          batch.insert('session_groups', {
            'session_id': id, 'group_id': groupIds[i], 'position': i,
          });
        }
      }
      final plannedCardio = raw['plannedCardioIds'];
      if (plannedCardio is List) {
        for (var i = 0; i < plannedCardio.length; i++) {
          batch.insert('session_cardio', {
            'session_id': id, 'activity_id': plannedCardio[i], 'position': i,
          });
        }
      }
      final list = raw['exerciseIds'];
      final done = raw['completedExerciseIds'] is List
          ? (raw['completedExerciseIds'] as List).toSet() : const <Object>{};
      if (list is List) {
        for (var i = 0; i < list.length; i++) {
          batch.insert('session_exercises', {
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
          batch.insert('workout_sets', {
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
        if (activity.key is! String || records is! List) {
          throw const FormatException('Atividade de cardio inválida.');
        }
        for (var index = 0; index < records.length; index++) {
          final record = records[index];
          if (record is! Map) {
            throw const FormatException('Registro de cardio inválido.');
          }
          final seconds = record['seconds'];
          final distance = record['distanceKm'];
          final calories = record['calories'];
          final sessionId = record['sessionId'];
          if (seconds is! int || seconds < 0 ||
              (distance != null && (distance is! num ||
                  !distance.isFinite || distance < 0)) ||
              (calories != null && (calories is! int || calories < 0)) ||
              (sessionId != null && (sessionId is! String ||
                  sessionId.isEmpty || sessionId.length > 160))) {
            throw const FormatException('Cardio inconsistente no snapshot.');
          }
          batch.insert('cardio_entries', {
            // JSON composite keys avoid collisions for custom activity IDs.
            'entry_key': jsonEncode([activity.key, index]),
            'activity_id': activity.key,
            'occurred_at': record['date'],
            'duration_seconds': record['seconds'],
            'distance_km': record['distanceKm'],
            'calories': record['calories'],
            'session_id': record['sessionId'],
          });
        }
      }
    }
    await batch.commit(noResult: true);
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
