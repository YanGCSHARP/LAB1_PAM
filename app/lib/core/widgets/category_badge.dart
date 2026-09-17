import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import '../utils/category_catalog.dart';

/// Round category icon — the leading element of a transaction row.
class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar({
    required this.category,
    super.key,
    this.kind,
    this.size = IconSizes.avatar,
  });

  final String category;
  final TransactionKind? kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    final info = CategoryCatalog.byKey(category, kind: kind);
    final color = context.semantic.category(category);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        shape: BoxShape.circle,
      ),
      child: Icon(info.icon, size: size * 0.48, color: color),
    );
  }
}

/// Static category label with icon and category color. Not interactive —
/// filters use `AppFilterChip`.
class CategoryBadge extends StatelessWidget {
  const CategoryBadge({
    required this.category,
    super.key,
    this.kind,
    this.dense = false,
  });

  final String category;
  final TransactionKind? kind;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final info = CategoryCatalog.byKey(category, kind: kind);
    final color = context.semantic.category(category);
    final label = dense ? context.texts.labelSmall : context.texts.labelMedium;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? Insets.sm : Insets.md,
        vertical: dense ? Insets.xs : Insets.xs + 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: Corners.chipRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(info.icon, size: dense ? 13 : IconSizes.sm, color: color),
          const SizedBox(width: Insets.xs + 2),
          Flexible(
            child: Text(
              info.label,
              style: label?.copyWith(color: color, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
