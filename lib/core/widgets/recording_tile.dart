import 'package:flutter/material.dart';

import '../../data/models/recording.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import '../utils/formatters.dart';
import 'ornaments.dart';

class RecordingTile extends StatelessWidget {
  const RecordingTile({
    super.key,
    required this.recording,
    this.onTap,
    this.trailing,
    this.showProgress = true,
    this.selected = false,
  });

  final Recording recording;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showProgress;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);
    final progress = recording.progress;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: selected
              ? palette.emerald.withValues(alpha: 0.07)
              : palette.card,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected
                ? palette.gold.withValues(alpha: 0.55)
                : palette.cardBorder,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
            child: Row(
              children: [
                RecordingCoverArt(
                  seed: recording.title,
                  size: 52,
                  radius: 14,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              recording.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: palette.ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (recording.completed)
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Icon(
                                Icons.check_circle_rounded,
                                size: 14,
                                color: palette.emerald.withValues(alpha: 0.8),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              recording.isUnavailable
                                  ? 'File not found on this device'
                                  : recording.metadataLine,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: recording.isUnavailable
                                    ? palette.danger
                                    : palette.inkMuted,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                          if (recording.durationMs != null &&
                              recording.durationMs! > 0) ...[
                            const SizedBox(width: 8),
                            Text(
                              formatDurationMs(recording.durationMs),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: palette.inkMuted,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (showProgress &&
                          !recording.isUnavailable &&
                          !recording.completed &&
                          progress > 0.01) ...[
                        const SizedBox(height: 7),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 2.5,
                            backgroundColor: palette.cardBorder.withValues(
                              alpha: 0.5,
                            ),
                            valueColor: const AlwaysStoppedAnimation(
                              AppColors.gold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                trailing ??
                    Icon(
                      recording.isUnavailable
                          ? Icons.error_outline_rounded
                          : Icons.play_circle_outline_rounded,
                      size: 26,
                      color: recording.isUnavailable
                          ? palette.danger
                          : palette.emerald.withValues(alpha: 0.9),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
