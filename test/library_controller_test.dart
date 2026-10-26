import 'package:flutter_test/flutter_test.dart';
import 'package:werenga/data/models/recording.dart';
import 'package:werenga/data/repositories/recording_store.dart';
import 'package:werenga/state/library_controller.dart';

class _FakeStore implements RecordingStore {
  _FakeStore(this.items);

  List<Recording> items;
  bool failFetch = false;

  @override
  Future<List<Recording>> fetchAll() async {
    if (failFetch) throw StateError('database unavailable');
    return List.of(items);
  }

  @override
  Future<Recording?> findById(String id) async {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  Future<Recording?> findByContentHash(String hash) async {
    for (final item in items) {
      if (item.contentHash == hash) return item;
    }
    return null;
  }

  @override
  Future<void> insert(Recording recording) async {
    items = [...items, recording];
  }

  @override
  Future<void> upsertBundled(Recording recording) async {
    final index = items.indexWhere((item) => item.id == recording.id);
    if (index < 0) {
      items = [...items, recording];
    } else {
      items = [...items]..[index] = recording;
    }
  }

  @override
  Future<void> updatePlayback({
    required String id,
    required int positionMs,
    DateTime? lastPlayedAt,
    bool? completed,
  }) async {
    items = [
      for (final item in items)
        if (item.id == id)
          item.copyWithPlayback(
            lastPositionMs: positionMs,
            lastPlayedAt: lastPlayedAt,
            completed: completed,
          )
        else
          item,
    ];
  }

  @override
  Future<void> updateDuration(String id, int? durationMs) async {
    items = [
      for (final item in items)
        if (item.id == id) item.copyWithDuration(durationMs) else item,
    ];
  }

  @override
  Future<void> updateMetadata(Recording recording) async {
    items = [
      for (final item in items)
        if (item.id == recording.id) recording else item,
    ];
  }

  @override
  Future<void> delete(String id) async {
    items = items.where((item) => item.id != id).toList();
  }

  @override
  Future<void> clearHistory() async {
    items = [
      for (final item in items)
        item.copyWithPlayback(
          lastPositionMs: 0,
          clearLastPlayedAt: true,
          completed: false,
        ),
    ];
  }

  @override
  Future<void> pruneBundledAssets(Set<String> keepPaths) async {
    items = [
      for (final item in items)
        if (!item.isBundled || keepPaths.contains(item.sourcePath)) item,
    ];
  }
}

Recording _recording({
  required String id,
  String title = 'Recording',
  RecordingSource source = RecordingSource.localFile,
  bool completed = false,
  DateTime? lastPlayedAt,
  int lastPositionMs = 0,
}) {
  return Recording(
    id: id,
    title: title,
    source: source,
    sourcePath: source == RecordingSource.bundledAsset
        ? 'assets/audio/$id.mp3'
        : 'C:/recordings/$id.mp3',
    dateAdded: DateTime(2026, 1, 1),
    durationMs: 60000,
    completed: completed,
    lastPlayedAt: lastPlayedAt,
    lastPositionMs: lastPositionMs,
  );
}

void main() {
  test('loads recordings and counts sources', () async {
    final store = _FakeStore([
      _recording(id: 'a'),
      _recording(id: 'b', source: RecordingSource.bundledAsset),
      _recording(id: 'c', source: RecordingSource.bundledAsset),
    ]);
    final controller = LibraryController(store);

    await controller.load();

    expect(controller.isLoading, isFalse);
    expect(controller.count, 3);
    expect(controller.importedCount, 1);
    expect(controller.bundledCount, 2);
    expect(controller.isEmpty, isFalse);
    expect(controller.byId('b')?.isBundled, isTrue);
    expect(controller.byId('missing'), isNull);
  });

  test('reports a friendly error when loading fails', () async {
    final store = _FakeStore([])..failFetch = true;
    final controller = LibraryController(store);

    await controller.load();

    expect(controller.isLoading, isFalse);
    expect(controller.loadError, isNotNull);
    expect(controller.recordings, isEmpty);
  });

  test('applies playback state to the matching recording', () async {
    final store = _FakeStore([
      _recording(id: 'a'),
      _recording(id: 'b'),
    ]);
    final controller = LibraryController(store);
    await controller.load();
    final playedAt = DateTime(2026, 6, 1, 12);

    controller.applyPlaybackState(
      id: 'a',
      positionMs: 12000,
      lastPlayedAt: playedAt,
      durationMs: 65000,
    );

    final updated = controller.byId('a')!;
    expect(updated.lastPositionMs, 12000);
    expect(updated.lastPlayedAt, playedAt);
    expect(updated.durationMs, 65000);
    expect(controller.byId('b')!.lastPositionMs, 0);
  });

  test('clears history without removing recordings', () async {
    final store = _FakeStore([
      _recording(
        id: 'a',
        completed: true,
        lastPlayedAt: DateTime(2026, 1, 2),
        lastPositionMs: 0,
      ),
    ]);
    final controller = LibraryController(store);
    await controller.load();

    await controller.clearHistory();

    expect(controller.count, 1);
    expect(controller.byId('a')!.lastPlayedAt, isNull);
    expect(controller.byId('a')!.completed, isFalse);
    expect(controller.history, isEmpty);
  });

  test('removes imported recordings but refuses bundled ones', () async {
    final store = _FakeStore([
      _recording(id: 'a'),
      _recording(id: 'b', source: RecordingSource.bundledAsset),
    ]);
    final controller = LibraryController(store);
    await controller.load();

    await controller.remove(controller.byId('a')!);
    expect(controller.count, 1);
    expect(controller.byId('a'), isNull);

    await expectLater(
      controller.remove(controller.byId('b')!),
      throwsStateError,
    );
    expect(controller.count, 1);
  });

  test('queries the in-memory library', () async {
    final store = _FakeStore([
      _recording(id: 'a', title: 'Al-Fatihah'),
      _recording(id: 'b', title: 'Al-Baqarah'),
    ]);
    final controller = LibraryController(store);
    await controller.load();

    final results = controller.query(search: 'baqarah');

    expect(results, hasLength(1));
    expect(results.single.id, 'b');
  });
}
