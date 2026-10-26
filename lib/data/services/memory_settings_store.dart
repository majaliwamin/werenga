import 'settings_store.dart';

/// Settings live only for the current browser session.
class MemorySettingsStore implements SettingsStore {
  final Map<String, String> _values = {};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }
}
