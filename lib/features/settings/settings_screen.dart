import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/brand_emblem.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/ornaments.dart';
import '../../state/library_controller.dart';
import '../../state/preferences_controller.dart';
import '../library/import_sheet.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _importing = false;

  Future<void> _import() async {
    if (_importing) return;
    setState(() => _importing = true);
    await startImportFlow(context);
    if (!mounted) return;
    setState(() => _importing = false);
  }

  @override
  Widget build(BuildContext context) {
    final preferences = context.watch<PreferencesController>();
    final library = context.watch<LibraryController>();
    final palette = context.palette;
    final theme = Theme.of(context);

    return ParchmentBackground(
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
          children: [
            Text(
              'Settings',
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
              'Quiet control over how Werenga looks and plays.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: palette.inkMuted,
              ),
            ),
            const SizedBox(height: 26),
            const SectionHeading(title: 'Appearance'),
            _SettingsCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      for (final mode in ThemeMode.values) ...[
                        if (mode != ThemeMode.values.first)
                          const SizedBox(width: 8),
                        Expanded(
                          child: _ThemeChoice(
                            mode: mode,
                            selected: preferences.themeMode == mode,
                            onTap: () {
                              unawaited(
                                preferences.setThemeMode(mode),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'System follows this device’s light or dark setting.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.inkMuted,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const SectionHeading(title: 'Playback'),
            _SettingsCard(
              padding: EdgeInsets.zero,
              child: SwitchListTile(
                value: preferences.resumeFromLastPosition,
                onChanged: (value) {
                  unawaited(
                    preferences.setResumeFromLastPosition(value),
                  );
                },
                secondary: Icon(
                  Icons.bookmark_added_outlined,
                  color: palette.emerald,
                  size: 21,
                ),
                title: const Text('Resume where I left off'),
                subtitle: Text(
                  'Continue each recording from its last saved position. '
                  'Completed recordings start again from the beginning.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.inkMuted,
                    height: 1.4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const SectionHeading(title: 'Your library'),
            _SettingsCard(
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.library_music_outlined,
                    label: 'Recordings',
                    value: formatRecordingCount(library.count),
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: Icons.inventory_2_outlined,
                    label: 'Bundled with Werenga',
                    value: '${library.bundledCount}',
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: Icons.phone_android_rounded,
                    label: 'Added on this device',
                    value: '${library.importedCount}',
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: Icons.sd_storage_outlined,
                    label: 'Audio storage',
                    value: formatBytes(library.totalBytes),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _importing
                          ? null
                          : () => unawaited(_import()),
                      icon: _importing
                          ? const SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.add_rounded, size: 18),
                      label: Text(
                        _importing ? 'Opening picker…' : 'Add recordings',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const SectionHeading(title: 'Privacy'),
            _SettingsCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: palette.emerald.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: palette.gold.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      Icons.lock_outline_rounded,
                      size: 18,
                      color: palette.emerald,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Werenga is fully offline. There is no account, no '
                      'analytics and no upload. Your recordings, positions and '
                      'history stay inside this app on this device.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.inkMuted,
                        height: 1.55,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const SectionHeading(title: 'About Werenga'),
            _SettingsCard(
              child: Column(
                children: [
                  const BrandEmblem(size: 58),
                  const SizedBox(height: 10),
                  Text(
                    'Werenga',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: palette.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Qur'an · Chichewa",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.inkMuted,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'A quiet place to hear the recitation and its Chichewa '
                    'meaning, one recording at a time.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.inkMuted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Divider(color: palette.cardBorder, height: 1),
                  const SizedBox(height: 12),
                  Text(
                    'Version 1.0.0 · offline edition',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 0.6,
                      color: palette.inkMuted.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(height: 2),
                  TextButton(
                    onPressed: () {
                      showLicensePage(
                        context: context,
                        applicationName: 'Werenga',
                        applicationVersion: '1.0.0',
                        applicationLegalese:
                            'Quran recitation with its Chichewa meaning, '
                            'entirely offline.',
                      );
                    },
                    child: const Text('Open source licenses'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Recordings remain the property of their respective owners. '
              'Werenga does not generate, translate or alter any audio.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9.5,
                height: 1.5,
                color: palette.inkMuted.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _ThemeChoice extends StatelessWidget {
  const _ThemeChoice({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final ThemeMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final (icon, label) = switch (mode) {
      ThemeMode.system => (Icons.brightness_auto_rounded, 'System'),
      ThemeMode.light => (Icons.light_mode_outlined, 'Light'),
      ThemeMode.dark => (Icons.dark_mode_outlined, 'Dark'),
    };
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? palette.emerald.withValues(alpha: 0.09)
                : palette.surfaceMuted.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: selected
                  ? palette.gold.withValues(alpha: 0.65)
                  : palette.cardBorder,
              width: selected ? 1.3 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? palette.emerald : palette.inkMuted,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: selected ? palette.ink : palette.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: palette.cardBorder),
        boxShadow: [
          BoxShadow(
            color: palette.shadow.withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: palette.inkMuted),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: palette.inkMuted,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            color: palette.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
