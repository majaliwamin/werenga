import '../data/db/app_database.dart';
import '../data/repositories/sqlite_recording_store.dart';
import '../data/services/bundled_library_service.dart';
import '../data/services/file_recording_importer.dart';
import '../data/services/sqlite_settings_store.dart';
import 'app_bootstrap.dart';
import 'library_controller.dart';
import 'playback_controller.dart';
import 'preferences_controller.dart';

/// Android, iOS, desktop and test bootstrap: SQLite plus real file imports.
Future<AppBootstrap> createBootstrap() async {
  final database = await AppDatabase.open();
  final store = SqliteRecordingStore(database);

  final preferences = PreferencesController(SqliteSettingsStore(database));
  await preferences.load();

  final bundledLibrary = BundledLibraryService();
  final bundledResult = await syncBundledLibrary(bundledLibrary, store);

  final library = LibraryController(store);
  await library.load();
  if (bundledResult.warning != null) {
    library.setStartupNotice(bundledResult.warning);
  }

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
    importer: FileRecordingImporter(store: store),
    bundledLibrary: bundledLibrary,
    startupNotice: bundledResult.warning,
    onDispose: database.close,
  );
}
