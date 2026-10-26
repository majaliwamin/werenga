import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_tokens.dart';
import '../../state/playback_controller.dart';
import '../dashboard/dashboard_screen.dart';
import '../history/history_screen.dart';
import '../library/library_screen.dart';
import '../player/widgets/mini_player.dart';
import '../settings/settings_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final GlobalKey<LibraryScreenState> _libraryKey =
      GlobalKey<LibraryScreenState>();
  int _index = 0;
  PlaybackController? _playback;
  int _lastErrorId = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final playback = context.read<PlaybackController>();
    if (!identical(playback, _playback)) {
      _playback?.removeListener(_handlePlaybackChange);
      _playback = playback;
      _lastErrorId = playback.errorId;
      playback.addListener(_handlePlaybackChange);
    }
  }

  @override
  void dispose() {
    _playback?.removeListener(_handlePlaybackChange);
    super.dispose();
  }

  void _handlePlaybackChange() {
    final playback = _playback;
    if (playback == null || !mounted) return;
    final message = playback.errorMessage;
    if (message == null || playback.errorId == _lastErrorId) return;
    _lastErrorId = playback.errorId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            action: SnackBarAction(
              label: 'Dismiss',
              onPressed: () {
                _playback?.clearError();
              },
            ),
          ),
        );
    });
  }

  void _selectTab(int index) {
    if (_index == index) return;
    setState(() => _index = index);
  }

  void _openLibrary() {
    setState(() => _index = 1);
  }

  void _openSettings() {
    setState(() => _index = 3);
  }

  void _openSearch() {
    setState(() => _index = 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _libraryKey.currentState?.focusSearch();
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      body: IndexedStack(
        index: _index,
        children: [
          DashboardScreen(
            onSearch: _openSearch,
            onOpenLibrary: _openLibrary,
            onOpenSettings: _openSettings,
          ),
          LibraryScreen(key: _libraryKey),
          HistoryScreen(onBrowse: _openLibrary),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.navBackground,
          border: Border(
            top: BorderSide(color: palette.cardBorder.withValues(alpha: 0.8)),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                alignment: Alignment.bottomCenter,
                child: context.select<PlaybackController, bool>(
                      (playback) => playback.current != null,
                    )
                    ? const MiniPlayer()
                    : const SizedBox(width: double.infinity),
              ),
              NavigationBar(
                selectedIndex: _index,
                onDestinationSelected: _selectTab,
                height: 66,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                shadowColor: Colors.transparent,
                indicatorColor: palette.emerald.withValues(alpha: 0.13),
                labelBehavior:
                    NavigationDestinationLabelBehavior.alwaysShow,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.library_music_outlined),
                    selectedIcon: Icon(Icons.library_music_rounded),
                    label: 'Library',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.history_rounded),
                    selectedIcon: Icon(Icons.history_rounded),
                    label: 'History',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.tune_rounded),
                    selectedIcon: Icon(Icons.tune_rounded),
                    label: 'Settings',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
