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

class SqliteLocalDataStore implements LocalDataStore {
  Database? _database;

  Future<Database> _open() async {
    final current = _database;
    if (current != null && current.isOpen) return current;
    final path = p.join(await getDatabasesPath(), 'gymrecords_v1.db');
    final db = await openDatabase(
      path,
      version: 1,
      onCreate: (database, version) async {
        await database.execute(
          'CREATE TABLE user_state (id INTEGER PRIMARY KEY, payload TEXT NOT NULL, updated_at TEXT NOT NULL)',
        );
      },
    );
    _database = db;
    return db;
  }

  @override
  Future<Map<String, dynamic>?> load() async {
    final db = await _open();
    final rows = await db.query('user_state', columns: ['payload'], where: 'id = ?', whereArgs: [1], limit: 1);
    if (rows.isEmpty) return null;
    final decoded = jsonDecode(rows.first['payload'] as String);
    if (decoded is! Map<String, dynamic>) throw const FormatException('Invalid local data');
    return decoded;
  }

  @override
  Future<void> save(Map<String, dynamic> snapshot) async {
    final db = await _open();
    await db.insert(
      'user_state',
      {'id': 1, 'payload': jsonEncode(snapshot), 'updated_at': DateTime.now().toUtc().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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
