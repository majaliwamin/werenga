import '../models/recording.dart';
import 'recording_store.dart';

/// In-memory library used by the browser preview, where SQLite is unavailable.
///
/// It follows the same rules as the SQLite store so the controllers behave
/// identically; only persistence across reloads is lost.
class MemoryRecordingStore implements RecordingStore {
  final Map<String, Recording> _items = {};

  @override
  Future<List<Recording>> fetchAll() async {
    final items = _items.values.toList()
      ..sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
    return List.unmodifiable(items);
  }

  @override
  Future<Recording?> findById(String id) async => _items[id];

  @override
  Future<Recording?> findByContentHash(String hash) async {
    for (final item in _items.values) {
      if (item.contentHash == hash) return item;
    }
    return null;
  }

  @override
  Future<void> insert(Recording recording) async {
    _items[recording.id] = recording;
  }

  @override
  Future<void> upsertBundled(Recording recording) async {
    final existing = _items[recording.id];
    if (existing == null) {
      _items[recording.id] = recording;
      return;
    }
    _items[recording.id] = Recording(
      id: recording.id,
      title: recording.title,
      surahName: recording.surahName,
      surahNumber: recording.surahNumber,
      verseRange: recording.verseRange,
      source: recording.source,
      sourcePath: recording.sourcePath,
      durationMs: recording.durationMs ?? existing.durationMs,
      sizeBytes: recording.sizeBytes,
      dateAdded: existing.dateAdded,
      lastPositionMs: existing.lastPositionMs,
      lastPlayedAt: existing.lastPlayedAt,
      completed: existing.completed,
      contentHash: existing.contentHash,
      isUnavailable: existing.isUnavailable,
    );
  }

  @override
  Future<void> updatePlayback({
    required String id,
    required int positionMs,
    DateTime? lastPlayedAt,
    bool? completed,
  }) async {
    final existing = _items[id];
    if (existing == null) return;
    _items[id] = existing.copyWithPlayback(
      lastPositionMs: positionMs < 0 ? 0 : positionMs,
      lastPlayedAt: lastPlayedAt,
      completed: completed,
    );
  }

  @override
  Future<void> updateDuration(String id, int? durationMs) async {
    final existing = _items[id];
    if (existing == null) return;
    _items[id] = existing.copyWithDuration(durationMs);
  }

  @override
  Future<void> updateMetadata(Recording recording) async {
    final existing = _items[recording.id];
    if (existing == null) return;
    _items[recording.id] = existing.copyWithMetadata(
      title: recording.title,
      surahName: recording.surahName,
      surahNumber: recording.surahNumber,
      verseRange: recording.verseRange,
    );
  }

  @override
  Future<void> delete(String id) async {
    _items.remove(id);
  }

  @override
  Future<void> clearHistory() async {
    for (final entry in _items.entries.toList(growable: false)) {
      _items[entry.key] = entry.value.copyWithPlayback(
        lastPositionMs: 0,
        clearLastPlayedAt: true,
        completed: false,
      );
    }
  }

  @override
  Future<void> pruneBundledAssets(Set<String> keepPaths) async {
    _items.removeWhere(
      (_, item) =>
          item.isBundled && !keepPaths.contains(item.sourcePath),
    );
  }
}
