import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import '../utils/category_catalog.dart';

/// Income / expense switch of the transaction form.
///
/// A two-option segmented control rather than a `Switch`: the two states are
/// equal choices, not on/off, and each one gets its own semantic color when
/// active.
class TypeSwitch extends StatelessWidget {
  const TypeSwitch({required this.value, super.key, this.onChanged});

  final TransactionKind value;

  /// `null` disables the control.
  final ValueChanged<TransactionKind>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Insets.xs),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: Corners.buttonRadius,
        border: Border.all(color: context.semantic.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Segment(
              label: AppStrings.expense,
              icon: Icons.north_east,
              selected: value == TransactionKind.expense,
              color: context.semantic.expense,
              onTap: onChanged == null
                  ? null
                  : () => onChanged!(TransactionKind.expense),
            ),
          ),
          const SizedBox(width: Insets.xs),
          Expanded(
            child: _Segment(
              label: AppStrings.income,
              icon: Icons.south_west,
              selected: value == TransactionKind.income,
              color: context.semantic.income,
              onTap: onChanged == null
                  ? null
                  : () => onChanged!(TransactionKind.income),
            ),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final foreground = !enabled
        ? context.semantic.textMuted.withValues(alpha: 0.5)
        : selected
        ? color
        : context.semantic.textMuted;

    return Material(
      color: selected ? color.withValues(alpha: 0.14) : Colors.transparent,
      borderRadius: Corners.chipRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: Corners.chipRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Insets.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: IconSizes.sm, color: foreground),
              const SizedBox(width: Insets.sm),
              Text(
                label,
                style: context.texts.labelLarge?.copyWith(color: foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
