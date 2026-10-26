import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/ornaments.dart';
import '../../core/widgets/recording_tile.dart';
import '../../data/models/library_query.dart';
import '../../data/models/recording.dart';
import '../../state/library_controller.dart';
import '../../state/playback_controller.dart';
import '../player/player_screen.dart';
import 'import_sheet.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => LibraryScreenState();
}

class LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();
  String _search = '';
  RecordingSort _sort = RecordingSort.surah;
  RecordingFilter _filter = RecordingFilter.all;
  String? _openingId;
  bool _importing = false;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void focusSearch() {
    _searchFocus.requestFocus();
    if (_scrollController.hasClients) {
      unawaited(
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        ),
      );
    }
  }

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

  Future<void> _import() async {
    if (_importing) return;
    setState(() => _importing = true);
    await startImportFlow(context);
    if (!mounted) return;
    setState(() => _importing = false);
  }

  Future<void> _remove(Recording recording) async {
    final confirmed = await confirmAction(
      context,
      title: 'Remove recording?',
      message:
          '“${recording.title}” will be removed from Werenga and its copied '
          'audio file will be deleted from this device.',
      confirmLabel: 'Remove',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    final playback = context.read<PlaybackController>();
    final library = context.read<LibraryController>();
    if (playback.current?.id == recording.id) {
      await playback.stop();
    }
    try {
      await library.remove(recording);
      if (mounted) showMessage(context, 'Recording removed.');
    } catch (error) {
      if (mounted) {
        showMessage(context, 'This recording could not be removed.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryController>();
    final palette = context.palette;
    final results = library.query(
      search: _search,
      sort: _sort,
      filter: _filter,
    );
    final queue = results.isEmpty ? library.recordings : results;

    return ParchmentBackground(
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: palette.emerald,
          backgroundColor: palette.card,
          onRefresh: library.refresh,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 16, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Library',
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
                              library.isLoading
                                  ? 'Opening your recordings…'
                                  : '${formatRecordingCount(library.count)} · '
                                        '${formatBytes(library.totalBytes)}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: palette.inkMuted),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: _importing
                            ? null
                            : () => unawaited(_import()),
                        icon: _importing
                            ? const SizedBox(
                                width: 15,
                                height: 15,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    AppColors.ivory,
                                  ),
                                ),
                              )
                            : const Icon(Icons.add_rounded, size: 19),
                        label: Text(_importing ? 'Adding…' : 'Add'),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                  child: AppSearchField(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    onChanged: (value) => setState(() => _search = value),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 14, 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final filter in RecordingFilter.values)
                                Padding(
                                  padding: const EdgeInsets.only(right: 7),
                                  child: ChoiceChip(
                                    label: Text(filter.label),
                                    selected: _filter == filter,
                                    onSelected: (_) {
                                      setState(() => _filter = filter);
                                    },
                                    showCheckmark: false,
                                    visualDensity: VisualDensity.compact,
                                    labelStyle: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _filter == filter
                                          ? palette.emerald
                                          : palette.inkMuted,
                                    ),
                                    selectedColor: palette.emerald.withValues(
                                      alpha: 0.11,
                                    ),
                                    backgroundColor: palette.card.withValues(
                                      alpha: 0.6,
                                    ),
                                    side: BorderSide(
                                      color: _filter == filter
                                          ? palette.emerald.withValues(
                                              alpha: 0.4,
                                            )
                                          : palette.cardBorder,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.pill,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      PopupMenuButton<RecordingSort>(
                        tooltip: 'Sort library',
                        initialValue: _sort,
                        onSelected: (value) {
                          setState(() => _sort = value);
                        },
                        itemBuilder: (context) => [
                          for (final sort in RecordingSort.values)
                            PopupMenuItem(
                              value: sort,
                              child: Row(
                                children: [
                                  if (sort == _sort)
                                    Icon(
                                      Icons.check_rounded,
                                      size: 16,
                                      color: palette.emerald,
                                    )
                                  else
                                    const SizedBox(width: 16),
                                  const SizedBox(width: 8),
                                  Text(sort.label),
                                ],
                              ),
                            ),
                        ],
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.sort_rounded,
                            size: 20,
                            color: palette.inkMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (library.loadError != null)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: ErrorPanel(
                      message: library.loadError!,
                      onRetry: () => unawaited(library.load()),
                    ),
                  ),
                )
              else if (library.isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: _LibrarySpinner()),
                )
              else if (library.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  sliver: SliverToBoxAdapter(
                    child: EmptyPanel(
                      title: 'Nothing here yet',
                      message:
                          'Add your own recordings to begin. Werenga copies '
                          'each file into the app so it is always available '
                          'offline.',
                      icon: Icons.library_music_outlined,
                      action: FilledButton.icon(
                        onPressed: _importing
                            ? null
                            : () => unawaited(_import()),
                        icon: const Icon(Icons.add_rounded, size: 19),
                        label: const Text('Add recordings'),
                      ),
                      footnote:
                          'Each file should contain the recitation followed '
                          'by its Chichewa translation.',
                    ),
                  ),
                )
              else if (results.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                    child: Center(
                      child: EmptyPanel(
                        title: 'No matches',
                        message: _filter == RecordingFilter.all
                            ? 'Try a different search term.'
                            : 'No recordings match this filter yet.',
                        icon: Icons.search_off_rounded,
                        action: TextButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _search = '';
                              _filter = RecordingFilter.all;
                            });
                          },
                          child: const Text('Clear filters'),
                        ),
                      ),
                    ),
                  ),
                )
              else ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: Row(
                      children: [
                        Text(
                          _resultsLabel(results.length),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: palette.inkMuted,
                                letterSpacing: 0.5,
                              ),
                        ),
                        const Spacer(),
                        Text(
                          _sort.label,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: palette.inkMuted.withValues(alpha: 0.8),
                                fontSize: 10,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                  sliver: SliverList.separated(
                    itemCount: results.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 9),
                    itemBuilder: (context, index) {
                      final recording = results[index];
                      return RecordingTile(
                        recording: recording,
                        onTap: () => unawaited(_open(recording, queue)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_openingId == recording.id)
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: palette.gold,
                                ),
                              )
                            else
                              Icon(
                                recording.isUnavailable
                                    ? Icons.error_outline_rounded
                                    : Icons.play_circle_outline_rounded,
                                size: 25,
                                color: recording.isUnavailable
                                    ? palette.danger
                                    : palette.emerald.withValues(alpha: 0.9),
                              ),
                            if (!recording.isBundled)
                              PopupMenuButton<String>(
                                tooltip: 'Recording options',
                                onSelected: (value) {
                                  if (value == 'remove') {
                                    unawaited(_remove(recording));
                                  }
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem(
                                    value: 'remove',
                                    child: Text('Remove from library'),
                                  ),
                                ],
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    6,
                                    8,
                                    2,
                                    8,
                                  ),
                                  child: Icon(
                                    Icons.more_vert_rounded,
                                    size: 18,
                                    color: palette.inkMuted,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _resultsLabel(int count) {
    final prefix = _search.trim().isEmpty ? '' : 'Results · ';
    return '$prefix${formatRecordingCount(count)}';
  }
}

class _LibrarySpinner extends StatelessWidget {
  const _LibrarySpinner();

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
