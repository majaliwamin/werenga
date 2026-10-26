import 'package:flutter/foundation.dart';

import '../data/repositories/recording_store.dart';
import '../data/services/bundled_library_service.dart';
import '../data/services/recording_importer.dart';
import 'library_controller.dart';
import 'playback_controller.dart';
import 'preferences_controller.dart';

/// Composition root for the application's local services.
///
/// The platform-specific pieces (SQLite or in-memory persistence, filesystem or
/// no-op imports) are chosen in `bootstrap_io.dart` and `bootstrap_web.dart`.
class AppBootstrap {
  AppBootstrap({
    required this.recordingStore,
    required this.preferences,
    required this.library,
    required this.playback,
    required this.importer,
    required this.bundledLibrary,
    this.startupNotice,
    Future<void> Function()? onDispose,
  }) : _onDispose = onDispose;

  final RecordingStore recordingStore;
  final PreferencesController preferences;
  final LibraryController library;
  final PlaybackController playback;
  final RecordingImporter importer;
  final BundledLibraryService bundledLibrary;
  final String? startupNotice;

  final Future<void> Function()? _onDispose;

  Future<void> dispose() async {
    playback.dispose();
    library.dispose();
    preferences.dispose();
    await _onDispose?.call();
  }
}

/// Loads bundled recordings, turning a failure into a non-fatal notice.
Future<BundledSyncResult> syncBundledLibrary(
  BundledLibraryService service,
  RecordingStore store,
) async {
  try {
    return await service.sync(store);
  } catch (error, stackTrace) {
    debugPrint('Bundled library sync failed: $error\n$stackTrace');
    return const BundledSyncResult(
      warning: 'Bundled recordings could not be checked this time.',
    );
  }
}
