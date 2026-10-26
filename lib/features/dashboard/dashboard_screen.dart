import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/brand_emblem.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/ornaments.dart';
import '../../core/widgets/recording_tile.dart';
import '../../data/models/library_query.dart';
import '../../data/models/recording.dart';
import '../../state/library_controller.dart';
import '../../state/playback_controller.dart';
import '../library/import_sheet.dart';
import '../player/player_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.onSearch,
    required this.onOpenLibrary,
    required this.onOpenSettings,
  });

  final VoidCallback onSearch;
  final VoidCallback onOpenLibrary;
  final VoidCallback onOpenSettings;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _openingId;
  bool _importing = false;

  Future<void> _open(Recording recording) async {
    if (_openingId != null) return;
    if (recording.isUnavailable) {
      showMessage(
        context,
        'This recording could not be found on this device.',
      );
      return;
    }
    setState(() => _openingId = recording.id);
    final playback = context.read<PlaybackController>();
    final queue = context.read<LibraryController>().recordings;
    final opened = await playback.open(recording, queue: queue);
    if (!mounted) return;
    setState(() => _openingId = null);
    if (opened) {
      await openPlayer(context);
    }
  }

  Future<void> _import() async {
    if (_importing) return;
    setState(() => _importing = true);
    await startImportFlow(context);
    if (!mounted) return;
    setState(() => _importing = false);
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryController>();
    final palette = context.palette;
    final featured = library.featured;
    final recent = library.recentlyPlayed.take(6).toList(growable: false);
    // Every recording is listed on the home page itself, in mushaf order so
    // the surahs read in sequence and nothing hides behind "view all".
    final all = library.query(sort: RecordingSort.surah);

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
              SliverToBoxAdapter(child: _Header(
                onSearch: widget.onSearch,
                onSettings: widget.onOpenSettings,
              )),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.list(
                  children: [
                    if (library.startupNotice != null) ...[
                      _StartupNotice(
                        message: library.startupNotice!,
                        onDismiss: () => library.setStartupNotice(null),
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (library.loadError != null) ...[
                      ErrorPanel(
                        message: library.loadError!,
                        onRetry: () => unawaited(library.load()),
                      ),
                      const SizedBox(height: 18),
                    ],
                    if (library.isLoading)
                      const _LoadingBlock()
                    else if (library.isEmpty)
                      EmptyPanel(
                        title: 'Your library is quiet',
                        message:
                            'Add the Quran recordings you already own. Each '
                            'file should contain the recitation followed by '
                            'its Chichewa translation.',
                        action: FilledButton.icon(
                          onPressed: _importing ? null : () => unawaited(_import()),
                          icon: _importing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                      AppColors.ivory,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.add_rounded,
                                  size: 19,
                                ),
                          label: Text(
                            _importing ? 'Opening picker…' : 'Add recordings',
                          ),
                        ),
                        footnote:
                            'MP3, M4A, AAC, WAV, OGG, OPUS and FLAC · stored '
                            'privately on this device.',
                      )
                    else if (featured != null)
                      _FeaturedCard(
                        recording: featured,
                        opening: _openingId == featured.id,
                        onPlay: () => unawaited(_open(featured)),
                      ),
                    if (!library.isLoading && !library.isEmpty) ...[
                      const SizedBox(height: 16),
                      _StatsRow(library: library),
                    ],
                    if (recent.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      SectionHeading(
                        title: 'Jump back in',
                        actionLabel: 'Library',
                        onAction: widget.onOpenLibrary,
                      ),
                      _RecentStrip(
                        recordings: recent,
                        openingId: _openingId,
                        onTap: (recording) => unawaited(_open(recording)),
                      ),
                    ],
                    if (!library.isLoading && !library.isEmpty) ...[
                      const SizedBox(height: 24),
                      SectionHeading(
                        title: 'All recordings',
                        actionLabel: 'Search',
                        onAction: widget.onSearch,
                      ),
                    ],
                  ],
                ),
              ),
              if (!library.isLoading && !library.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                  sliver: SliverList.separated(
                    itemCount: all.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 9),
                    itemBuilder: (context, index) {
                      final recording = all[index];
                      return RecordingTile(
                        recording: recording,
                        onTap: () => unawaited(_open(recording)),
                        trailing: _openingId == recording.id
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: palette.gold,
                                ),
                              )
                            : null,
                      );
                    },
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 26),
                sliver: SliverToBoxAdapter(child: const _OfflineNote()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onSearch, required this.onSettings});

  final VoidCallback onSearch;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 18),
      child: Row(
        children: [
          const BrandEmblem(size: 44),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "QUR'AN  ·  CHICHEWA",
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.1,
                    color: palette.goldStrong,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Werenga',
                  style: TextStyle(
                    fontFamily: 'CormorantGaramond',
                    fontSize: 27,
                    height: 1,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: palette.ink,
                  ),
                ),
              ],
            ),
          ),
          CircleAction(
            icon: Icons.search_rounded,
            tooltip: 'Search recordings',
            size: 40,
            iconSize: 20,
            onPressed: onSearch,
          ),
          const SizedBox(width: 8),
          CircleAction(
            icon: Icons.tune_rounded,
            tooltip: 'Settings',
            size: 40,
            iconSize: 19,
            onPressed: onSettings,
          ),
        ],
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({
    required this.recording,
    required this.opening,
    required this.onPlay,
  });

  final Recording recording;
  final bool opening;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final progress = recording.progress;
    final continuing = recording.wasPlayed && !recording.completed;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.42)),
        boxShadow: [
          BoxShadow(
            color: AppColors.emeraldNight.withValues(alpha: 0.24),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF176049),
                Color(0xFF0C3B2E),
                Color(0xFF06251D),
              ],
            ),
          ),
          child: InkWell(
            onTap: onPlay,
            child: Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: const IslamicPatternPainter(
                        color: Color(0x16C6A664),
                        cell: 74,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -46,
                  top: -28,
                  bottom: -30,
                  width: 220,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: 0.28,
                      child: MihrabArch(
                        color: AppColors.gold,
                        strokeWidth: 1.2,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 19),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const EightPointStar(
                            size: 9,
                            color: AppColors.goldBright,
                            innerRatio: 0.38,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            continuing
                                ? 'CONTINUE LISTENING'
                                : recording.completed
                                ? 'LISTEN AGAIN'
                                : 'BEGIN HERE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.2,
                              color: AppColors.goldBright.withValues(
                                alpha: 0.9,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.offline_bolt_rounded,
                            size: 15,
                            color: AppColors.ivory.withValues(alpha: 0.55),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        recording.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'CormorantGaramond',
                          fontSize: 31,
                          height: 1.08,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                          color: AppColors.ivory,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        recording.surahLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.ivory.withValues(alpha: 0.62),
                        ),
                      ),
                      if (progress > 0.01 && !recording.completed) ...[
                        const SizedBox(height: 13),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 3,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.14,
                            ),
                            valueColor: const AlwaysStoppedAnimation(
                              AppColors.goldBright,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${(progress * 100).round()}% listened',
                          style: TextStyle(
                            fontSize: 9.5,
                            color: AppColors.ivory.withValues(alpha: 0.52),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.goldBright,
                                  AppColors.gold,
                                ],
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: opening ? null : onPlay,
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    15,
                                    9,
                                    16,
                                    9,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (opening)
                                        const SizedBox(
                                          width: 13,
                                          height: 13,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation(
                                              AppColors.emeraldNight,
                                            ),
                                          ),
                                        )
                                      else
                                        Icon(
                                          recording.completed
                                              ? Icons.replay_rounded
                                              : Icons.play_arrow_rounded,
                                          size: 18,
                                          color: AppColors.emeraldNight,
                                        ),
                                      const SizedBox(width: 6),
                                      Text(
                                        opening
                                            ? 'Opening…'
                                            : recording.completed
                                            ? 'Replay'
                                            : continuing
                                            ? 'Resume'
                                            : 'Listen',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.2,
                                          color: AppColors.emeraldNight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (recording.durationMs != null)
                            Text(
                              formatDurationMs(recording.durationMs),
                              style: TextStyle(
                                fontSize: 11,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                                color: AppColors.ivory.withValues(
                                  alpha: 0.55,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.library});

  final LibraryController library;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            value: '${library.count}',
            label: library.count == 1 ? 'recording' : 'recordings',
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _StatTile(
            value: formatBytes(library.totalBytes),
            label: 'on this device',
          ),
        ),
        const SizedBox(width: 9),
        const Expanded(
          child: _StatTile(value: '100%', label: 'offline'),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: palette.card.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: palette.cardBorder.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'CormorantGaramond',
              fontSize: 21,
              height: 1,
              fontWeight: FontWeight.w600,
              color: palette.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.7,
              color: palette.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentStrip extends StatelessWidget {
  const _RecentStrip({
    required this.recordings,
    required this.openingId,
    required this.onTap,
  });

  final List<Recording> recordings;
  final String? openingId;
  final ValueChanged<Recording> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(right: 4),
        itemCount: recordings.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final recording = recordings[index];
          return _RecentCard(
            recording: recording,
            opening: openingId == recording.id,
            onTap: () => onTap(recording),
          );
        },
      ),
    );
  }
}

class _RecentCard extends StatelessWidget {
  const _RecentCard({
    required this.recording,
    required this.opening,
    required this.onTap,
  });

  final Recording recording;
  final bool opening;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);
    return SizedBox(
      width: 224,
      child: Container(
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: palette.cardBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      RecordingCoverArt(
                        seed: recording.title,
                        size: 38,
                        radius: 10,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
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
                              recording.completed
                                  ? 'Completed'
                                  : recording.isInProgress
                                  ? formatPlaybackProgress(
                                      recording.lastPositionMs,
                                      recording.durationMs,
                                    )
                                  : 'Ready to listen',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: palette.inkMuted,
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (opening)
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: palette.gold,
                          ),
                        )
                      else
                        Icon(
                          recording.completed
                              ? Icons.replay_rounded
                              : Icons.play_arrow_rounded,
                          size: 19,
                          color: palette.emerald,
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    recording.surahLine,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'CormorantGaramond',
                      fontSize: 16,
                      height: 1.15,
                      fontWeight: FontWeight.w500,
                      color: palette.ink.withValues(alpha: 0.82),
                    ),
                  ),
                  const Spacer(),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: LinearProgressIndicator(
                      value: recording.progress,
                      minHeight: 2.5,
                      backgroundColor: palette.cardBorder.withValues(
                        alpha: 0.45,
                      ),
                      valueColor: AlwaysStoppedAnimation(palette.gold),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        formatDurationMs(recording.durationMs),
                        style: TextStyle(
                          fontSize: 9.5,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: palette.inkMuted,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        recording.isBundled ? 'Bundled' : 'Imported',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                          color: palette.inkMuted.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
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

class _StartupNotice extends StatelessWidget {
  const _StartupNotice({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 10, 4, 10),
      decoration: BoxDecoration(
        color: palette.gold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: palette.gold.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: palette.goldStrong),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: palette.inkMuted,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Dismiss',
            onPressed: onDismiss,
            iconSize: 16,
            color: palette.inkMuted,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _OfflineNote extends StatelessWidget {
  const _OfflineNote();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.lock_outline_rounded,
          size: 12,
          color: palette.inkMuted.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            'Everything stays on this device · no account · no internet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9.5,
              letterSpacing: 0.3,
              color: palette.inkMuted.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      height: 180,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: palette.card.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: palette.cardBorder),
      ),
      child: SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          color: palette.emerald,
        ),
      ),
    );
  }
}
