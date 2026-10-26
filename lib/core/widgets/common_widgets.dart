import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'brand_emblem.dart';
import 'ornaments.dart';

class SectionHeading extends StatelessWidget {
  const SectionHeading({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.only(bottom: AppSpace.sm),
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          EightPointStar(
            size: 9,
            color: palette.gold,
            innerRatio: 0.38,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: palette.ink),
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

class MetaPill extends StatelessWidget {
  const MetaPill({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.background,
    this.borderColor,
    this.dense = false,
  });

  final String label;
  final IconData? icon;
  final Color? color;
  final Color? background;
  final Color? borderColor;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final foreground = color ?? palette.inkMuted;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: background ?? palette.surfaceMuted.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: borderColor ?? palette.cardBorder.withValues(alpha: 0.8),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 11 : 12, color: foreground),
            SizedBox(width: dense ? 4 : 5),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: foreground,
                letterSpacing: dense ? 0.2 : 0.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CircleAction extends StatelessWidget {
  const CircleAction({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 44,
    this.iconSize = 21,
    this.tooltip,
    this.filled = false,
    this.color,
    this.backgroundColor,
    this.borderColor,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final String? tooltip;
  final bool filled;
  final Color? color;
  final Color? backgroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final foreground = color ?? palette.ink;
    final background =
        backgroundColor ??
        (filled ? palette.emerald : palette.surface.withValues(alpha: 0.6));
    final button = SizedBox(
      width: size,
      height: size,
      child: Material(
        color: background,
        shape: CircleBorder(
          side: BorderSide(
            color:
                borderColor ??
                (filled ? Colors.transparent : palette.cardBorder),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Icon(
            icon,
            size: iconSize,
            color: filled ? AppColors.ivory : foreground,
          ),
        ),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

class EmptyPanel extends StatelessWidget {
  const EmptyPanel({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.action,
    this.footnote,
  });

  final String title;
  final String message;
  final IconData? icon;
  final Widget? action;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: palette.cardBorder),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -16,
            top: -18,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.55,
                child: EightPointStar(
                  size: 86,
                  color: palette.gold.withValues(alpha: 0.10),
                  innerRatio: 0.38,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null)
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: palette.emerald.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: palette.gold.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Icon(icon, color: palette.emerald, size: 24),
                )
              else
                const BrandEmblem(size: 52),
              const SizedBox(height: AppSpace.md),
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: palette.ink,
                ),
              ),
              const SizedBox(height: AppSpace.xs),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: palette.inkMuted,
                ),
              ),
              if (action != null) ...[
                const SizedBox(height: AppSpace.lg),
                action!,
              ],
              if (footnote != null) ...[
                const SizedBox(height: AppSpace.sm),
                Text(
                  footnote!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.inkMuted.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.focusNode,
    this.hint = 'Search recordings',
    this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final FocusNode? focusNode;
  final String hint;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                onPressed: () {
                  controller.clear();
                  onChanged('');
                  onClear?.call();
                },
                icon: const Icon(Icons.close_rounded, size: 18),
              ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md,
          vertical: 13,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: palette.cardBorder),
        ),
      ),
    );
  }
}

class ErrorPanel extends StatelessWidget {
  const ErrorPanel({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.xl),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: palette.danger.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.cloud_off_rounded,
            color: palette.danger,
            size: 32,
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpace.md),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try again'),
            ),
          ],
        ],
      ),
    );
  }
}

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  bool destructive = false,
}) async {
  final palette = context.palette;
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: destructive
              ? FilledButton.styleFrom(backgroundColor: palette.danger)
              : null,
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
