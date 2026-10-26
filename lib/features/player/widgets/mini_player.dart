import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/ornaments.dart';
import '../../../state/playback_controller.dart';
import '../player_screen.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final playback = context.watch<PlaybackController>();
    final recording = playback.current;
    if (recording == null) return const SizedBox.shrink();

    final palette = context.palette;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.sm,
        0,
        AppSpace.sm,
        AppSpace.xs,
      ),
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: palette.cardBorder),
            boxShadow: [
              BoxShadow(
                color: palette.shadow,
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => openPlayer(context),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 58,
                    child: Row(
                      children: [
                        const SizedBox(width: 10),
                        RecordingCoverArt(
                          seed: recording.title,
                          size: 40,
                          radius: 11,
                        ),
                        const SizedBox(width: AppSpace.sm),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                recording.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: palette.ink,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                playback.hasError
                                    ? 'Playback needs attention'
                                    : recording.metadataLine,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: playback.hasError
                                      ? palette.danger
                                      : palette.inkMuted,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 38,
                          height: 38,
                          child: playback.isLoading
                              ? Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: palette.gold,
                                  ),
                                )
                              : IconButton(
                                  tooltip: playback.isPlaying
                                      ? 'Pause'
                                      : 'Play',
                                  onPressed: () {
                                    unawaited(playback.toggle());
                                  },
                                  padding: EdgeInsets.zero,
                                  icon: Icon(
                                    playback.isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    size: 26,
                                    color: palette.emerald,
                                  ),
                                ),
                        ),
                        IconButton(
                          tooltip: 'Stop and close player',
                          onPressed: () {
                            unawaited(playback.stop());
                          },
                          iconSize: 17,
                          color: palette.inkMuted,
                          padding: const EdgeInsets.only(
                            right: 10,
                            left: 4,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 42,
                          ),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  StreamBuilder<Duration>(
                    stream: playback.positionStream,
                    initialData: playback.position,
                    builder: (context, snapshot) {
                      final total = playback.totalDuration;
                      final position = snapshot.data ?? playback.position;
                      final value = total == null || total.inMilliseconds <= 0
                          ? 0.0
                          : (position.inMilliseconds / total.inMilliseconds)
                                .clamp(0.0, 1.0);
                      return LinearProgressIndicator(
                        value: value,
                        minHeight: 2,
                        backgroundColor: palette.cardBorder.withValues(
                          alpha: 0.45,
                        ),
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.gold,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
