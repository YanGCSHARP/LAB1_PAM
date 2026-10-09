import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';

/// Meaning of a badge; decides its color.
enum BadgeTone { neutral, accent, income, warning, danger }

/// Small status label — «перерасход», «ожидает отправки», «сегодня».
///
/// Always carries text, never color alone: at the budget thresholds the amber
/// and the red must stay distinguishable for a viewer with color blindness.
class AppBadge extends StatelessWidget {
  const AppBadge({
    required this.label,
    super.key,
    this.tone = BadgeTone.neutral,
    this.icon,
  });

  final String label;
  final BadgeTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semantic;
    final color = switch (tone) {
      BadgeTone.neutral => semantic.textMuted,
      BadgeTone.accent => context.colors.primary,
      BadgeTone.income => semantic.income,
      BadgeTone.warning => semantic.warning,
      BadgeTone.danger => semantic.danger,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.sm,
        vertical: Insets.xs - 1,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: Corners.chipRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: Insets.xs),
          ],
          Text(
            label,
            style: context.texts.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
