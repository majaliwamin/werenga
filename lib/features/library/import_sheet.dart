import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/ornaments.dart';
import '../../data/services/recording_importer.dart';
import '../../state/library_controller.dart';

Future<void> startImportFlow(BuildContext context) async {
  final importer = context.read<RecordingImporter>();
  final library = context.read<LibraryController>();

  if (!importer.isSupported) {
    showMessage(
      context,
      'Importing is available in the Android app. This browser preview keeps '
      'its library in memory only.',
    );
    return;
  }

  List<ImportCandidate> candidates;
  try {
    candidates = await importer.pickCandidates();
  } catch (error) {
    if (context.mounted) {
      showMessage(
        context,
        'The file picker could not be opened. Please try selecting the files again.',
      );
    }
    return;
  }
  if (candidates.isEmpty || !context.mounted) return;

  final result = await showModalBottomSheet<ImportResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => ImportSheet(candidates: candidates),
  );
  if (result == null || !context.mounted) return;

  await library.refresh();
  if (!context.mounted) return;

  if (result.failures.isNotEmpty) {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _ImportOutcomeDialog(result: result),
    );
    return;
  }
  showMessage(context, _importSummary(result));
}

String _importSummary(ImportResult result) {
  final parts = <String>[];
  if (result.imported.isNotEmpty) {
    parts.add('${formatRecordingCount(result.imported.length)} added');
  }
  if (result.skipped.isNotEmpty) {
    parts.add('${result.skipped.length} already in your library');
  }
  if (result.failures.isNotEmpty) {
    parts.add('${result.failures.length} could not be imported');
  }
  if (parts.isEmpty) return 'Nothing new was imported.';
  return '${parts.join(' · ')}.';
}

class ImportSheet extends StatefulWidget {
  const ImportSheet({super.key, required this.candidates});

  final List<ImportCandidate> candidates;

  @override
  State<ImportSheet> createState() => _ImportSheetState();
}

class _ImportSheetState extends State<ImportSheet> {
  late final List<_Draft> _drafts;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _drafts = widget.candidates.map(_Draft.new).toList(growable: false);
  }

  @override
  void dispose() {
    for (final draft in _drafts) {
      draft.dispose();
    }
    super.dispose();
  }

  Future<void> _import() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await context.read<RecordingImporter>().importAll(
        _drafts.map((draft) => draft.toRequest()).toList(growable: false),
      );
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error =
            'The recordings could not be imported. Check that the files are '
            'still available and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final height =
        (MediaQuery.sizeOf(context).height - bottomInset) * 0.9;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: palette.background,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
          border: Border(
            top: BorderSide(color: palette.gold.withValues(alpha: 0.35)),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: palette.inkMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const EightPointStar(
                    size: 12,
                    color: AppColors.gold,
                    innerRatio: 0.38,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.candidates.length == 1
                              ? 'Review recording'
                              : 'Review ${widget.candidates.length} recordings',
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Confirm the details below. Files are copied into '
                          'Werenga and stay on this device.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: palette.inkMuted,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: _busy
                        ? null
                        : () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: palette.cardBorder),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                itemCount: _drafts.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _DraftCard(
                  draft: _drafts[index],
                  index: index,
                  enabled: !_busy,
                  onToggleDetails: () {
                    setState(() => _drafts[index].expanded = !_drafts[index].expanded);
                  },
                ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  _error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.danger,
                    height: 1.4,
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
              decoration: BoxDecoration(
                color: palette.surface,
                border: Border(
                  top: BorderSide(color: palette.cardBorder),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Audio is never altered or uploaded.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.inkMuted,
                        fontSize: 10.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => Navigator.of(context).maybePop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 4),
                  FilledButton.icon(
                    onPressed: _busy ? null : () => unawaited(_import()),
                    icon: _busy
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
                        : const Icon(Icons.download_done_rounded, size: 18),
                    label: Text(
                      _busy
                          ? 'Importing…'
                          : 'Import ${widget.candidates.length}',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Draft {
  _Draft(this.candidate)
    : titleController = TextEditingController(text: candidate.suggestedTitle),
      surahNameController = TextEditingController(),
      surahNumberController = TextEditingController(),
      verseController = TextEditingController();

  final ImportCandidate candidate;
  final TextEditingController titleController;
  final TextEditingController surahNameController;
  final TextEditingController surahNumberController;
  final TextEditingController verseController;
  bool expanded = false;

  ImportRequest toRequest() {
    final number = int.tryParse(surahNumberController.text.trim());
    return ImportRequest(
      candidate: candidate,
      title: titleController.text.trim(),
      surahName: surahNameController.text.trim(),
      surahNumber: number != null && number > 0 ? number : null,
      verseRange: verseController.text.trim(),
    );
  }

  void dispose() {
    titleController.dispose();
    surahNameController.dispose();
    surahNumberController.dispose();
    verseController.dispose();
  }
}

class _DraftCard extends StatelessWidget {
  const _DraftCard({
    required this.draft,
    required this.index,
    required this.enabled,
    required this.onToggleDetails,
  });

  final _Draft draft;
  final int index;
  final bool enabled;
  final VoidCallback onToggleDetails;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: palette.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.emerald.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: palette.gold.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(
                  Icons.audio_file_rounded,
                  size: 17,
                  color: palette.emerald,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      draft.candidate.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      draft.candidate.sizeBytes == null
                          ? 'Audio file'
                          : formatBytes(draft.candidate.sizeBytes),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.inkMuted,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${index + 1}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: palette.inkMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: draft.titleController,
            enabled: enabled,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Title',
              hintText: 'e.g. Al-Fatihah',
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: enabled ? onToggleDetails : null,
              icon: Icon(
                draft.expanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                size: 18,
              ),
              label: const Text('Surah details (optional)'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                minimumSize: const Size(0, 34),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          if (draft.expanded) ...[
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 96,
                  child: TextField(
                    controller: draft.surahNumberController,
                    enabled: enabled,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Surah no.',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: draft.surahNameController,
                    enabled: enabled,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Surah name',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: draft.verseController,
              enabled: enabled,
              decoration: const InputDecoration(
                labelText: 'Ayah range',
                hintText: 'e.g. 1–7',
              ),
            ),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}

class _ImportOutcomeDialog extends StatelessWidget {
  const _ImportOutcomeDialog({required this.result});

  final ImportResult result;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Import finished'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_importSummary(result)),
            if (result.skipped.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                'Already in your library',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: palette.inkMuted,
                ),
              ),
              const SizedBox(height: 4),
              ...result.skipped.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text('• $item', style: theme.textTheme.bodySmall),
                ),
              ),
            ],
            if (result.failures.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                'Could not be imported',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: palette.danger,
                ),
              ),
              const SizedBox(height: 4),
              ...result.failures.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text('• $item', style: theme.textTheme.bodySmall),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
