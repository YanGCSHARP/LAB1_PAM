import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import '../utils/formatters.dart';

/// The amount input of the transaction form — the one field a person actually
/// types into, so it is the largest element on the screen.
///
/// The currency sits next to the number as a static suffix; the value itself is
/// rendered in the hero money style with tabular figures.
class AmountField extends StatelessWidget {
  const AmountField({
    required this.currency,
    super.key,
    this.controller,
    this.isIncome,
    this.enabled = true,
    this.errorText,
    this.autofocus = false,
    this.onChanged,
  });

  final String currency;
  final TextEditingController? controller;

  /// Tints the value as income or expense; `null` keeps the default color.
  final bool? isIncome;

  final bool enabled;

  /// Rendered under the field; the owning form decides what it says.
  final String? errorText;

  final bool autofocus;

  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final semantic = context.semantic;

    Color valueColor = colors.onSurface;
    if (!enabled) {
      valueColor = semantic.textMuted;
    } else if (isIncome != null) {
      valueColor = isIncome! ? semantic.income : colors.onSurface;
    }

    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.lg,
            vertical: Insets.xl,
          ),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: Corners.cardRadius,
            border: Border.all(
              color: hasError ? colors.error : semantic.border,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  autofocus: autofocus,
                  onChanged: onChanged,
                  textAlign: TextAlign.center,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  style: context.money.hero.copyWith(color: valueColor),
                  cursorColor: colors.primary,
                  decoration: InputDecoration(
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                    hintText: '0',
                    hintStyle: context.money.hero.copyWith(
                      color: semantic.textMuted.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Insets.sm),
              Text(
                Formatters.currencySymbol(currency),
                style: context.money.large.copyWith(color: semantic.textMuted),
              ),
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: Insets.sm),
          Text(
            errorText!,
            style: context.texts.bodySmall?.copyWith(color: colors.error),
          ),
        ],
      ],
    );
  }
}
