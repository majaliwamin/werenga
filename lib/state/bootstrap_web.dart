import '../data/repositories/memory_recording_store.dart';
import '../data/services/bundled_library_service.dart';
import '../data/services/memory_settings_store.dart';
import '../data/services/recording_importer.dart';
import 'app_bootstrap.dart';
import 'library_controller.dart';
import 'playback_controller.dart';
import 'preferences_controller.dart';

/// Browser preview bootstrap: SQLite and filesystem imports are unavailable, so
/// the library and preferences live in memory for the current session.
Future<AppBootstrap> createBootstrap() async {
  final store = MemoryRecordingStore();

  final preferences = PreferencesController(MemorySettingsStore());
  await preferences.load();

  final bundledLibrary = BundledLibraryService();
  final bundledResult = await syncBundledLibrary(bundledLibrary, store);

  final library = LibraryController(store);
  await library.load();

  final playback = PlaybackController(
    store: store,
    preferences: preferences,
    library: library,
  );
  await playback.initialize();

  return AppBootstrap(
    recordingStore: store,
    preferences: preferences,
    library: library,
    playback: playback,
    importer: const UnsupportedRecordingImporter(),
    bundledLibrary: bundledLibrary,
    startupNotice:
        bundledResult.warning ??
        'Browser preview: the library is held in memory and is not saved. '
            'Import recordings in the Android app.',
  );
}
