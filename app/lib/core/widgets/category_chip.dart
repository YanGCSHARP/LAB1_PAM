import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/category_catalog.dart';

/// Compact category label with its icon, tinted with the category color.
///
/// Used both as a static badge in lists and as a selectable filter chip.
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    required this.category,
    super.key,
    this.kind,
    this.selected = false,
    this.onTap,
    this.dense = false,
  });

  /// Category key from the built-in dictionary.
  final String category;

  /// Narrows the lookup when the same key exists for income and expense.
  final TransactionKind? kind;

  final bool selected;
  final VoidCallback? onTap;

  /// Smaller paddings, for dense list rows.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final info = CategoryCatalog.byKey(category, kind: kind);
    final color = AppColors.categoryColor(category);
    final theme = Theme.of(context);

    final background = selected
        ? color.withValues(alpha: 0.22)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);
    final foreground = selected ? color : theme.colorScheme.onSurfaceVariant;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(info.icon, size: dense ? 14 : 16, color: foreground),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            info.label,
            style:
                (dense
                        ? theme.textTheme.labelSmall
                        : theme.textTheme.labelMedium)
                    ?.copyWith(
                      color: foreground,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: dense ? 8 : 10,
            vertical: dense ? 4 : 7,
          ),
          child: content,
        ),
      ),
    );
  }
}

/// Round category icon used as a leading avatar in transaction rows.
class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar({
    required this.category,
    super.key,
    this.kind,
    this.size = 40,
  });

  final String category;
  final TransactionKind? kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    final info = CategoryCatalog.byKey(category, kind: kind);
    final color = AppColors.categoryColor(category);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        shape: BoxShape.circle,
      ),
      child: Icon(info.icon, size: size * 0.5, color: color),
    );
  }
}
