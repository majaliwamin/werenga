import 'package:sqflite/sqflite.dart';

import '../db/app_database.dart';
import '../models/recording.dart';
import 'recording_store.dart';

class SqliteRecordingStore implements RecordingStore {
  SqliteRecordingStore(this._database);

  final AppDatabase _database;

  @override
  Future<List<Recording>> fetchAll() async {
    final rows = await _database.database.query(
      'recordings',
      orderBy: 'date_added DESC',
    );
    return rows.map(Recording.fromMap).toList(growable: false);
  }

  @override
  Future<Recording?> findById(String id) async {
    final rows = await _database.database.query(
      'recordings',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Recording.fromMap(rows.first);
  }

  @override
  Future<Recording?> findByContentHash(String hash) async {
    final rows = await _database.database.query(
      'recordings',
      where: 'content_hash = ?',
      whereArgs: [hash],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Recording.fromMap(rows.first);
  }

  @override
  Future<void> insert(Recording recording) async {
    await _database.database.insert(
      'recordings',
      recording.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  @override
  Future<void> upsertBundled(Recording recording) async {
    await _database.database.transaction((transaction) async {
      final existing = await transaction.query(
        'recordings',
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [recording.id],
        limit: 1,
      );
      if (existing.isEmpty) {
        await transaction.insert('recordings', recording.toMap());
        return;
      }
      await transaction.update(
        'recordings',
        {
          'title': recording.title,
          'surah_name': recording.surahName,
          'surah_number': recording.surahNumber,
          'verse_range': recording.verseRange,
          'source': recording.source.storageValue,
          'source_path': recording.sourcePath,
          'size_bytes': recording.sizeBytes,
          if (recording.durationMs != null)
            'duration_ms': recording.durationMs,
        },
        where: 'id = ?',
        whereArgs: [recording.id],
      );
    });
  }

  @override
  Future<void> updatePlayback({
    required String id,
    required int positionMs,
    DateTime? lastPlayedAt,
    bool? completed,
  }) async {
    await _database.database.update(
      'recordings',
      {
        'last_position_ms': positionMs < 0 ? 0 : positionMs,
        if (lastPlayedAt != null)
          'last_played_at': lastPlayedAt.millisecondsSinceEpoch,
        if (completed != null) 'completed': completed ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> updateDuration(String id, int? durationMs) async {
    await _database.database.update(
      'recordings',
      {'duration_ms': durationMs},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> updateMetadata(Recording recording) async {
    await _database.database.update(
      'recordings',
      {
        'title': recording.title,
        'surah_name': recording.surahName,
        'surah_number': recording.surahNumber,
        'verse_range': recording.verseRange,
      },
      where: 'id = ?',
      whereArgs: [recording.id],
    );
  }

  @override
  Future<void> delete(String id) async {
    await _database.database.delete(
      'recordings',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> clearHistory() async {
    await _database.database.update('recordings', {
      'last_position_ms': 0,
      'last_played_at': null,
      'completed': 0,
    });
  }

  @override
  Future<void> pruneBundledAssets(Set<String> keepPaths) async {
    if (keepPaths.isEmpty) {
      await _database.database.delete(
        'recordings',
        where: 'source = ?',
        whereArgs: [RecordingSource.bundledAsset.storageValue],
      );
      return;
    }
    final placeholders = List.filled(keepPaths.length, '?').join(', ');
    await _database.database.delete(
      'recordings',
      where: 'source = ? AND source_path NOT IN ($placeholders)',
      whereArgs: [
        RecordingSource.bundledAsset.storageValue,
        ...keepPaths,
      ],
    );
  }
}
