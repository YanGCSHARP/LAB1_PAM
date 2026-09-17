import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';

/// Selectable filter chip for the transactions screen.
///
/// Four states share one shape: default, selected, pressed (ripple) and
/// disabled. Selection is marked by the accent fill and a heavier label, not
/// by color alone.
class AppFilterChip extends StatelessWidget {
  const AppFilterChip({
    required this.label,
    super.key,
    this.icon,
    this.selected = false,
    this.onTap,
    this.trailing,
  });

  final String label;
  final IconData? icon;
  final bool selected;

  /// `null` disables the chip.
  final VoidCallback? onTap;

  /// Usually a dropdown caret or a clear button.
  final IconData? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final semantic = context.semantic;
    final enabled = onTap != null;

    final Color background;
    final Color foreground;
    final Color outline;
    if (!enabled) {
      background = colors.surfaceContainerLow;
      foreground = semantic.textMuted.withValues(alpha: 0.5);
      outline = semantic.border;
    } else if (selected) {
      background = colors.primaryContainer;
      foreground = colors.onPrimaryContainer;
      outline = colors.primary.withValues(alpha: 0.5);
    } else {
      background = colors.surfaceContainerLow;
      foreground = colors.onSurface;
      outline = semantic.border;
    }

    return Material(
      color: background,
      borderRadius: Corners.chipRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: Corners.chipRadius,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: Corners.chipRadius,
            border: Border.all(color: outline),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.md,
            vertical: Insets.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: IconSizes.sm, color: foreground),
                const SizedBox(width: Insets.xs + 2),
              ],
              Text(
                label,
                style: context.texts.labelMedium?.copyWith(
                  color: foreground,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: Insets.xs),
                Icon(trailing, size: IconSizes.sm, color: foreground),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
