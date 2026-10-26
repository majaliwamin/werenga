import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/ornaments.dart';
import '../../core/widgets/recording_tile.dart';
import '../../data/models/recording.dart';
import '../../state/library_controller.dart';
import '../../state/playback_controller.dart';
import '../player/player_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, this.onBrowse});

  final VoidCallback? onBrowse;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String? _openingId;

  Future<void> _open(Recording recording, List<Recording> queue) async {
    if (_openingId != null) return;
    if (recording.isUnavailable) {
      showMessage(
        context,
        'This recording could not be found on this device.',
      );
      return;
    }
    setState(() => _openingId = recording.id);
    final opened = await context.read<PlaybackController>().open(
      recording,
      queue: queue,
    );
    if (!mounted) return;
    setState(() => _openingId = null);
    if (opened) await openPlayer(context);
  }

  Future<void> _clear() async {
    final confirmed = await confirmAction(
      context,
      title: 'Clear listening history?',
      message:
          'Saved positions, completion marks and listening dates will be '
          'cleared. Your recordings will stay in the library.',
      confirmLabel: 'Clear history',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    await context.read<LibraryController>().clearHistory();
    if (mounted) showMessage(context, 'Listening history cleared.');
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryController>();
    final palette = context.palette;
    final history = library.history;
    final groups = _group(history);
    final completed = history.where((item) => item.completed).length;

    return ParchmentBackground(
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: palette.emerald,
          backgroundColor: palette.card,
          onRefresh: library.refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 14, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'History',
                              style: TextStyle(
                                fontFamily: 'CormorantGaramond',
                                fontSize: 34,
                                height: 1,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.3,
                                color: palette.ink,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              history.isEmpty
                                  ? 'Your listening journey, kept private.'
                                  : '${formatRecordingCount(history.length)} · '
                                        '$completed completed',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: palette.inkMuted),
                            ),
                          ],
                        ),
                      ),
                      if (history.isNotEmpty)
                        TextButton(
                          onPressed: () => unawaited(_clear()),
                          child: const Text('Clear'),
                        ),
                    ],
                  ),
                ),
              ),
              if (library.isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: _HistorySpinner()),
                )
              else if (history.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                    child: Center(
                      child: EmptyPanel(
                        title: 'No listening history yet',
                        message:
                            'Recordings you play will appear here with your '
                            'saved position and listening dates.',
                        icon: Icons.history_toggle_off_rounded,
                        action: widget.onBrowse == null
                            ? null
                            : OutlinedButton.icon(
                                onPressed: widget.onBrowse,
                                icon: const Icon(
                                  Icons.library_music_outlined,
                                  size: 18,
                                ),
                                label: const Text('Browse library'),
                              ),
                        footnote:
                            'History never leaves this device.',
                      ),
                    ),
                  ),
                )
              else ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      decoration: BoxDecoration(
                        color: palette.card.withValues(alpha: 0.62),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(color: palette.cardBorder),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 16,
                            color: palette.goldStrong,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              'Listening history is stored only on this device.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: palette.inkMuted),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                for (final entry in groups.entries) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                      child: Row(
                        children: [
                          EightPointStar(
                            size: 8,
                            color: palette.gold,
                            innerRatio: 0.38,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            entry.key.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.7,
                              color: palette.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
                    sliver: SliverList.separated(
                      itemCount: entry.value.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 9),
                      itemBuilder: (context, index) {
                        final recording = entry.value[index];
                        return RecordingTile(
                          recording: recording,
                          onTap: () =>
                              unawaited(_open(recording, history)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_openingId == recording.id)
                                SizedBox(
                                  width: 15,
                                  height: 15,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: palette.gold,
                                  ),
                                )
                              else
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      formatRelativeTime(
                                        recording.lastPlayedAt!,
                                      ),
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        color: palette.inkMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      recording.completed
                                          ? 'Finished'
                                          : formatPlaybackProgress(
                                              recording.lastPositionMs,
                                              recording.durationMs,
                                            ),
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures(),
                                        ],
                                        fontWeight: FontWeight.w600,
                                        color: recording.completed
                                            ? palette.emerald
                                            : palette.goldStrong,
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(width: 8),
                              Icon(
                                recording.completed
                                    ? Icons.replay_rounded
                                    : Icons.play_arrow_rounded,
                                size: 21,
                                color: palette.emerald.withValues(alpha: 0.9),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Map<String, List<Recording>> _group(List<Recording> history) {
    final groups = <String, List<Recording>>{};
    for (final recording in history) {
      final date = recording.lastPlayedAt!;
      final label = _dayLabel(date);
      groups.putIfAbsent(label, () => []).add(recording);
    }
    return groups;
  }

  String _dayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final difference = today.difference(day).inDays;
    if (difference <= 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return 'Earlier this week';
    return formatDate(date);
  }
}

class _HistorySpinner extends StatelessWidget {
  const _HistorySpinner();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        strokeWidth: 2.2,
        color: context.palette.emerald,
      ),
    );
  }
}
