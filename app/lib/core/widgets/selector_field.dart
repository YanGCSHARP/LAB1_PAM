import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';

/// A field-shaped button that opens a picker: category, account or date.
///
/// Looks exactly like a text field so a form reads as one column of controls,
/// but it is tappable and carries a chosen value instead of free input.
class SelectorField extends StatelessWidget {
  const SelectorField({
    required this.label,
    super.key,
    this.value,
    this.placeholder,
    this.leading,
    this.onTap,
    this.errorText,
  });

  /// Small caption above the value.
  final String label;

  /// Chosen value; `null` shows [placeholder] in the muted color.
  final String? value;
  final String? placeholder;

  /// Category avatar, account icon, calendar glyph.
  final Widget? leading;

  /// `null` disables the field.
  final VoidCallback? onTap;

  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final semantic = context.semantic;
    final enabled = onTap != null;
    final hasError = errorText != null;
    final hasValue = value != null && value!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: colors.surfaceContainerLow,
          borderRadius: Corners.fieldRadius,
          child: InkWell(
            onTap: onTap,
            borderRadius: Corners.fieldRadius,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Insets.lg,
                vertical: Insets.md,
              ),
              decoration: BoxDecoration(
                borderRadius: Corners.fieldRadius,
                border: Border.all(
                  color: hasError ? colors.error : semantic.border,
                ),
              ),
              child: Row(
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: Insets.md),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(label, style: context.texts.labelSmall),
                        const SizedBox(height: 2),
                        Text(
                          hasValue ? value! : (placeholder ?? 'Не выбрано'),
                          style: context.texts.bodyLarge?.copyWith(
                            color: !enabled
                                ? semantic.textMuted
                                : hasValue
                                ? colors.onSurface
                                : semantic.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: Insets.sm),
                  Icon(
                    Icons.expand_more,
                    size: IconSizes.md,
                    color: semantic.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: Insets.xs + 2),
          Text(
            errorText!,
            style: context.texts.bodySmall?.copyWith(color: colors.error),
          ),
        ],
      ],
    );
  }
}
