import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Owns the single SQLite connection used for the local library.
class AppDatabase {
  AppDatabase._(this.database);

  final Database database;

  static const _fileName = 'werenga.db';
  static const _version = 1;

  static Future<AppDatabase> open({String? overridePath}) async {
    final path =
        overridePath ??
        p.join(await getDatabasesPath(), _fileName);
    final database = await openDatabase(
      path,
      version: _version,
      onConfigure: (db) => db.execute('PRAGMA journal_mode = WAL'),
      onCreate: _create,
      onUpgrade: _upgrade,
    );
    return AppDatabase._(database);
  }

  static Future<void> _create(Database db, int version) async {
    await db.execute('''
      CREATE TABLE recordings (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        surah_name TEXT,
        surah_number INTEGER,
        verse_range TEXT,
        source TEXT NOT NULL,
        source_path TEXT NOT NULL UNIQUE,
        duration_ms INTEGER,
        size_bytes INTEGER,
        date_added INTEGER NOT NULL,
        last_position_ms INTEGER NOT NULL DEFAULT 0,
        last_played_at INTEGER,
        completed INTEGER NOT NULL DEFAULT 0,
        content_hash TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_recordings_last_played '
      'ON recordings(last_played_at DESC)',
    );
    await db.execute(
      'CREATE INDEX idx_recordings_added ON recordings(date_added DESC)',
    );
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _upgrade(Database db, int oldVersion, int newVersion) async {
    // Reserved for future schema migrations. The initial schema is version 1.
  }

  Future<void> close() => database.close();
}
