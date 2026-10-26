import '../models/recording.dart';

/// Persistence boundary for the recording library.
///
/// Keeping this as an interface makes the library and playback controllers
/// testable with an in-memory implementation. This file deliberately avoids
/// `dart:io` so the browser preview can share it with the Android build.
abstract interface class RecordingStore {
  Future<List<Recording>> fetchAll();

  Future<Recording?> findById(String id);

  Future<Recording?> findByContentHash(String hash);

  Future<void> insert(Recording recording);

  Future<void> upsertBundled(Recording recording);

  Future<void> updatePlayback({
    required String id,
    required int positionMs,
    DateTime? lastPlayedAt,
    bool? completed,
  });

  Future<void> updateDuration(String id, int? durationMs);

  Future<void> updateMetadata(Recording recording);

  Future<void> delete(String id);

  Future<void> clearHistory();

  Future<void> pruneBundledAssets(Set<String> keepPaths);
}
