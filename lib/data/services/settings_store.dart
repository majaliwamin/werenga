/// Small key/value persistence boundary for preferences.
abstract interface class SettingsStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);
}
