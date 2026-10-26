import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/platform/local_files.dart';
import '../data/models/library_query.dart';
import '../data/models/recording.dart';
import '../data/repositories/recording_store.dart';

/// Owns the in-memory view of the local library.
class LibraryController extends ChangeNotifier {
  LibraryController(this._store);

  final RecordingStore _store;

  List<Recording> _recordings = const [];
  bool _isLoading = true;
  String? _loadError;
  String? _startupNotice;
  bool _disposed = false;

  List<Recording> get recordings => _recordings;

  bool get isLoading => _isLoading;

  String? get loadError => _loadError;

  String? get startupNotice => _startupNotice;

  bool get isEmpty => !_isLoading && _recordings.isEmpty;

  Recording? get featured => featuredRecording(_recordings);

  List<Recording> get recentlyPlayed => continueListening(_recordings);

  List<Recording> get history => historyRecordings(_recordings);

  int get count => _recordings.length;

  int get importedCount =>
      _recordings.where((item) => !item.isBundled).length;

  int get bundledCount => _recordings.where((item) => item.isBundled).length;

  int get totalBytes => _recordings.fold(
    0,
    (total, item) => total + (item.sizeBytes ?? 0),
  );

  int get importedBytes => _recordings
      .where((item) => !item.isBundled)
      .fold(0, (total, item) => total + (item.sizeBytes ?? 0));

  Recording? byId(String id) {
    for (final item in _recordings) {
      if (item.id == id) return item;
    }
    return null;
  }

  void setStartupNotice(String? notice) {
    _startupNotice = notice;
    _safeNotify();
  }

  Future<void> load({bool showSpinner = true}) async {
    if (showSpinner) {
      _isLoading = true;
      _loadError = null;
      _safeNotify();
    }
    try {
      final items = await _store.fetchAll();
      _recordings = await _withAvailability(items);
      _loadError = null;
    } catch (error) {
      _loadError =
          'Your local library could not be opened. Please try again.';
      debugPrint('Library load failed: $error');
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  Future<void> refresh() => load(showSpinner: false);

  Future<List<Recording>> _withAvailability(List<Recording> items) async {
    final checked = await Future.wait(
      items.map((item) async {
        if (item.source != RecordingSource.localFile) return item;
        try {
          final exists = await localFiles.exists(item.sourcePath);
          return item.copyWithAvailability(!exists);
        } catch (_) {
          return item.copyWithAvailability(true);
        }
      }),
    );
    return checked;
  }

  void applyPlaybackState({
    required String id,
    required int positionMs,
    DateTime? lastPlayedAt,
    bool? completed,
    int? durationMs,
  }) {
    var changed = false;
    final updated = <Recording>[];
    for (final item in _recordings) {
      if (item.id == id) {
        changed = true;
        final withDuration = durationMs != null
            ? item.copyWithDuration(durationMs)
            : item;
        updated.add(
          withDuration.copyWithPlayback(
            lastPositionMs: positionMs,
            lastPlayedAt: lastPlayedAt,
            completed: completed,
          ),
        );
      } else {
        updated.add(item);
      }
    }
    _recordings = List.unmodifiable(updated);
    if (changed) _safeNotify();
  }

  void applyMetadata(Recording recording) {
    _recordings = [
      for (final item in _recordings)
        if (item.id == recording.id) recording else item,
    ];
    _safeNotify();
  }

  Future<void> remove(Recording recording) async {
    if (recording.isBundled) {
      throw StateError('Bundled recordings are managed by the application.');
    }
    if (recording.source == RecordingSource.localFile) {
      try {
        await localFiles.delete(recording.sourcePath);
      } catch (_) {
        // Remove the library entry even if the file itself is locked.
      }
    }
    await _store.delete(recording.id);
    _recordings = _recordings
        .where((item) => item.id != recording.id)
        .toList(growable: false);
    _safeNotify();
  }

  Future<void> clearHistory() async {
    await _store.clearHistory();
    _recordings = _recordings
        .map(
          (item) => item.copyWithPlayback(
            lastPositionMs: 0,
            clearLastPlayedAt: true,
            completed: false,
          ),
        )
        .toList(growable: false);
    _safeNotify();
  }

  List<Recording> query({
    String search = '',
    RecordingSort sort = RecordingSort.recentlyAdded,
    RecordingFilter filter = RecordingFilter.all,
  }) {
    return queryRecordings(
      _recordings,
      search: search,
      sort: sort,
      filter: filter,
    );
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
