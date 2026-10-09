import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';

/// Opens a bottom sheet with the app's title row and safe-area padding.
///
/// Used for the category, account and other pickers: on a phone a sheet beats
/// a dropdown — the list is reachable by thumb and can be as long as needed.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required String title,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) {
      return SheetScaffold(title: title, child: builder(sheetContext));
    },
  );
}

/// Title row plus content of a bottom sheet.
class SheetScaffold extends StatelessWidget {
  const SheetScaffold({required this.title, required this.child, super.key});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Insets.lg,
              0,
              Insets.sm,
              Insets.sm,
            ),
            child: Row(
              children: [
                Expanded(child: Text(title, style: context.texts.titleMedium)),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  tooltip: AppStrings.cancel,
                ),
              ],
            ),
          ),
          Flexible(child: child),
          const SizedBox(height: Insets.sm),
        ],
      ),
    );
  }
}

/// One selectable row inside a picker sheet.
class SheetOption extends StatelessWidget {
  const SheetOption({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
    this.leading,
    this.trailing,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.lg,
          vertical: Insets.md,
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: Insets.md),
            ],
            Expanded(
              child: Text(
                label,
                style: context.texts.bodyLarge?.copyWith(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            ?trailing,
            if (selected && trailing == null)
              Icon(
                Icons.check,
                size: IconSizes.md,
                color: context.colors.primary,
              ),
          ],
        ),
      ),
    );
  }
}
