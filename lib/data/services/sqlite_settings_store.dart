import 'package:sqflite/sqflite.dart';

import '../db/app_database.dart';
import 'settings_store.dart';

class SqliteSettingsStore implements SettingsStore {
  SqliteSettingsStore(this._database);

  final AppDatabase _database;

  @override
  Future<String?> read(String key) async {
    final rows = await _database.database.query(
      'settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  @override
  Future<void> write(String key, String value) async {
    await _database.database.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
