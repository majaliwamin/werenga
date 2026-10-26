import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/ornaments.dart';
import '../../state/playback_controller.dart';

Future<void> openPlayer(BuildContext context) {
  final playback = context.read<PlaybackController>();
  if (playback.current == null) return Future.value();
  return Navigator.of(context).push(PlayerScreen.route());
}

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  static Route<void> route() {
    return PageRouteBuilder<void>(
      fullscreenDialog: true,
      opaque: true,
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) =>
          const PlayerScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final playback = context.watch<PlaybackController>();
    final recording = playback.current;

    if (recording == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
      return const Scaffold(backgroundColor: AppColors.emeraldNight);
    }

    final screen = MediaQuery.sizeOf(context);
    final artworkSize = math
        .min(screen.width - 84, screen.height * 0.34)
        .clamp(170.0, 316.0)
        .toDouble();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: AppColors.emeraldNight,
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF12523E),
                Color(0xFF0A3529),
                Color(0xFF051B16),
              ],
              stops: [0, 0.52, 1],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              IgnorePointer(
                child: CustomPaint(
                  painter: const IslamicPatternPainter(
                    color: Color(0x12C6A664),
                    cell: 104,
                  ),
                ),
              ),
              Positioned(
                left: -60,
                right: -60,
                bottom: -120,
                height: 520,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.14,
                    child: MihrabArch(
                      color: AppColors.gold,
                      strokeWidth: 1.5,
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    _PlayerTopBar(
                      onClose: () => Navigator.of(context).maybePop(),
                      onRestart: () {
                        unawaited(playback.restart());
                      },
                      onStop: () {
                        unawaited(playback.stop());
                      },
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 6, 24, 28),
                        child: Column(
                          children: [
                            const SizedBox(height: 6),
                            RecordingCoverArt(
                              seed: recording.title,
                              size: artworkSize,
                              radius: 30,
                              large: true,
                              glow: true,
                            ),
                            const SizedBox(height: 28),
                            Text(
                              recording.title,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'CormorantGaramond',
                                fontSize: 30,
                                height: 1.12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.3,
                                color: AppColors.ivory,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              recording.surahLine,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 12.5,
                                height: 1.4,
                                color: AppColors.ivory.withValues(alpha: 0.62),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 7,
                              runSpacing: 7,
                              children: [
                                const _DarkPill(
                                  icon: Icons.offline_bolt_rounded,
                                  label: 'Offline',
                                ),
                                const _DarkPill(
                                  icon: Icons.translate_rounded,
                                  label: 'Recitation + Chichewa',
                                ),
                                if (recording.isBundled)
                                  const _DarkPill(
                                    icon: Icons.inventory_2_outlined,
                                    label: 'Bundled recording',
                                  )
                                else
                                  const _DarkPill(
                                    icon: Icons.phone_android_rounded,
                                    label: 'On this device',
                                  ),
                              ],
                            ),
                            if (playback.hasError) ...[
                              const SizedBox(height: 18),
                              _PlaybackErrorNotice(
                                message: playback.errorMessage!,
                                onRetry: () {
                                  playback.clearError();
                                  unawaited(playback.play());
                                },
                              ),
                            ],
                            const SizedBox(height: 20),
                            _SeekSection(
                              playback: playback,
                              dragValue: _dragValue,
                              onDrag: (value) {
                                setState(() => _dragValue = value);
                              },
                              onDragEnd: (value) {
                                setState(() => _dragValue = null);
                                unawaited(
                                  playback.seek(
                                    Duration(milliseconds: value.round()),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 6),
                            _Controls(playback: playback),
                            const SizedBox(height: 22),
                            if (playback.isCompleted)
                              Text(
                                'You have reached the end of this recording.',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.gold.withValues(alpha: 0.85),
                                ),
                              ),
                            const SizedBox(height: 8),
                            Text(
                              'The recitation and its Chichewa translation '
                              'play exactly as supplied.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10.5,
                                height: 1.5,
                                color: AppColors.ivory.withValues(alpha: 0.38),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerTopBar extends StatelessWidget {
  const _PlayerTopBar({
    required this.onClose,
    required this.onRestart,
    required this.onStop,
  });

  final VoidCallback onClose;
  final VoidCallback onRestart;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: Row(
        children: [
          const SizedBox(width: 6),
          IconButton(
            tooltip: 'Close player',
            onPressed: onClose,
            color: AppColors.ivory,
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'NOW PLAYING',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.6,
                    color: AppColors.gold.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Local · offline',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: AppColors.ivory.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Player options',
            color: AppColors.emeraldDeep,
            icon: const Icon(Icons.more_horiz_rounded, color: AppColors.ivory),
            onSelected: (value) {
              if (value == 'restart') onRestart();
              if (value == 'stop') onStop();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'restart',
                child: Text(
                  'Restart recording',
                  style: TextStyle(color: AppColors.ivory),
                ),
              ),
              PopupMenuItem(
                value: 'stop',
                child: Text(
                  'Stop playback',
                  style: TextStyle(color: AppColors.ivory),
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _DarkPill extends StatelessWidget {
  const _DarkPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.13)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11.5, color: AppColors.gold.withValues(alpha: 0.9)),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
              color: AppColors.ivory.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeekSection extends StatelessWidget {
  const _SeekSection({
    required this.playback,
    required this.dragValue,
    required this.onDrag,
    required this.onDragEnd,
  });

  final PlaybackController playback;
  final double? dragValue;
  final ValueChanged<double> onDrag;
  final ValueChanged<double> onDragEnd;

  @override
  Widget build(BuildContext context) {
    final total = playback.totalDuration;
    final totalMs = total?.inMilliseconds ?? 0;
    final enabled = totalMs > 0;

    return StreamBuilder<Duration>(
      stream: playback.positionStream,
      initialData: playback.position,
      builder: (context, snapshot) {
        final currentMs =
            dragValue ?? snapshot.data?.inMilliseconds.toDouble() ?? 0;
        final max = enabled ? totalMs.toDouble() : 1.0;
        final value = currentMs.clamp(0.0, max);
        return Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.gold,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.16),
                thumbColor: AppColors.goldBright,
                overlayColor: AppColors.gold.withValues(alpha: 0.15),
                disabledActiveTrackColor: AppColors.gold.withValues(alpha: 0.3),
                disabledInactiveTrackColor: Colors.white.withValues(
                  alpha: 0.08,
                ),
                disabledThumbColor: AppColors.gold.withValues(alpha: 0.35),
              ),
              child: Slider(
                value: value,
                max: max,
                onChanged: enabled ? onDrag : null,
                onChangeEnd: enabled ? onDragEnd : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Text(
                    formatPlayerTime(Duration(milliseconds: value.round())),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.ivory.withValues(alpha: 0.58),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    enabled ? formatPlayerTime(total) : '—',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.ivory.withValues(alpha: 0.58),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.playback});

  final PlaybackController playback;

  @override
  Widget build(BuildContext context) {
    final playing = playback.isPlaying;
    final loading = playback.isLoading || playback.isBuffering;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ControlButton(
          icon: Icons.replay_rounded,
          tooltip: 'Restart recording',
          size: 46,
          iconSize: 23,
          onPressed: () => unawaited(playback.restart()),
        ),
        const SizedBox(width: 8),
        _ControlButton(
          icon: Icons.skip_previous_rounded,
          tooltip: 'Previous recording',
          size: 50,
          iconSize: 29,
          onPressed: playback.canSkipPrevious
              ? () => unawaited(playback.previous())
              : null,
        ),
        const SizedBox(width: 12),
        _MainPlayButton(
          playing: playing,
          loading: loading,
          onPressed: () => unawaited(playback.toggle()),
        ),
        const SizedBox(width: 12),
        _ControlButton(
          icon: Icons.skip_next_rounded,
          tooltip: 'Next recording',
          size: 50,
          iconSize: 29,
          onPressed: playback.canSkipNext
              ? () => unawaited(playback.next())
              : null,
        ),
        const SizedBox(width: 8),
        _ControlButton(
          icon: Icons.stop_rounded,
          tooltip: 'Stop playback',
          size: 46,
          iconSize: 22,
          onPressed: () => unawaited(playback.stop()),
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.tooltip,
    required this.size,
    required this.iconSize,
    this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final double size;
  final double iconSize;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        iconSize: iconSize,
        color: AppColors.ivory.withValues(alpha: 0.88),
        disabledColor: AppColors.ivory.withValues(alpha: 0.22),
        icon: Icon(icon),
      ),
    );
  }
}

class _MainPlayButton extends StatelessWidget {
  const _MainPlayButton({
    required this.playing,
    required this.loading,
    required this.onPressed,
  });

  final bool playing;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 78,
      height: 78,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.goldBright, AppColors.gold, AppColors.goldDeep],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.3),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation(
                          AppColors.emeraldNight,
                        ),
                      ),
                    )
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      transitionBuilder: (child, animation) =>
                          ScaleTransition(scale: animation, child: child),
                      child: Icon(
                        playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        key: ValueKey(playing),
                        size: 40,
                        color: AppColors.emeraldNight,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaybackErrorNotice extends StatelessWidget {
  const _PlaybackErrorNotice({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.goldBright,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 11.5,
                height: 1.4,
                color: AppColors.ivory,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
