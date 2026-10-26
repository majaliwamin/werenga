import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'data/services/bundled_library_service.dart';
import 'data/services/recording_importer.dart';
import 'features/shell/app_shell.dart';
import 'features/splash/splash_screen.dart';
import 'state/app_bootstrap.dart';
import 'state/library_controller.dart';
import 'state/playback_controller.dart';
import 'state/preferences_controller.dart';

class WerengaApp extends StatefulWidget {
  const WerengaApp({super.key, required this.bootstrap});

  final AppBootstrap bootstrap;

  @override
  State<WerengaApp> createState() => _WerengaAppState();
}

class _WerengaAppState extends State<WerengaApp> {
  Timer? _splashTimer;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _splashTimer = Timer(const Duration(milliseconds: 1750), () {
      if (!mounted) return;
      setState(() => _showSplash = false);
    });
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bootstrap = widget.bootstrap;
    return MultiProvider(
      providers: [
        Provider<RecordingImporter>.value(value: bootstrap.importer),
        Provider<BundledLibraryService>.value(
          value: bootstrap.bundledLibrary,
        ),
        ChangeNotifierProvider<PreferencesController>.value(
          value: bootstrap.preferences,
        ),
        ChangeNotifierProvider<LibraryController>.value(
          value: bootstrap.library,
        ),
        ChangeNotifierProvider<PlaybackController>.value(
          value: bootstrap.playback,
        ),
      ],
      child: Consumer<PreferencesController>(
        builder: (context, preferences, _) {
          return MaterialApp(
            title: 'Werenga',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: preferences.themeMode,
            builder: (context, child) {
              return ScrollConfiguration(
                behavior: const WerengaScrollBehavior(),
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: AnimatedSwitcher(
              duration: const Duration(milliseconds: 650),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: _showSplash
                  ? const SplashScreen(key: ValueKey('splash'))
                  : const AppShell(key: ValueKey('shell')),
            ),
          );
        },
      ),
    );
  }
}

class WerengaScrollBehavior extends MaterialScrollBehavior {
  const WerengaScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
