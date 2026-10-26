import 'package:flutter/material.dart';

import '../data/services/settings_store.dart';

/// Small, local-only preference store for theme and playback behaviour.
class PreferencesController extends ChangeNotifier {
  PreferencesController(this._store);

  final SettingsStore _store;

  static const _themeKey = 'theme_mode';
  static const _resumeKey = 'resume_from_last_position';

  ThemeMode _themeMode = ThemeMode.system;
  bool _resumeFromLastPosition = true;
  bool _loaded = false;

  ThemeMode get themeMode => _themeMode;

  bool get resumeFromLastPosition => _resumeFromLastPosition;

  bool get loaded => _loaded;

  Future<void> load() async {
    try {
      final theme = await _store.read(_themeKey);
      _themeMode = switch (theme) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
      final resume = await _store.read(_resumeKey);
      if (resume != null) _resumeFromLastPosition = resume == 'true';
      _loaded = true;
    } catch (_) {
      _loaded = true;
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    try {
      await _store.write(_themeKey, mode.name);
    } catch (_) {
      // A preference that cannot be stored should not interrupt the session.
    }
  }

  Future<void> setResumeFromLastPosition(bool value) async {
    if (_resumeFromLastPosition == value) return;
    _resumeFromLastPosition = value;
    notifyListeners();
    try {
      await _store.write(_resumeKey, value.toString());
    } catch (_) {
      // Best effort persistence.
    }
  }
}
