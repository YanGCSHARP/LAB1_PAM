import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import '../utils/category_catalog.dart';
import '../utils/formatters.dart';
import 'app_badge.dart';

/// One budget row: category, spent-of-limit, and a track colored by the
/// project thresholds — amber from 90%, red from 100%.
///
/// Above 90% the row also gets a text badge: at the two thresholds color alone
/// is not enough, amber and green collapse together for a deuteranope.
class BudgetProgressBar extends StatelessWidget {
  const BudgetProgressBar({
    required this.category,
    required this.spentAmount,
    required this.limitAmount,
    required this.currency,
    super.key,
    this.onTap,
  });

  final String category;
  final double spentAmount;
  final double limitAmount;
  final String currency;
  final VoidCallback? onTap;

  double get _progress => limitAmount <= 0 ? 0 : spentAmount / limitAmount;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semantic;
    final progress = _progress;
    final remaining = limitAmount - spentAmount;

    final Color trackColor;
    if (progress >= 1.0) {
      trackColor = semantic.danger;
    } else if (progress >= 0.9) {
      trackColor = semantic.warning;
    } else {
      trackColor = semantic.category(category);
    }

    final row = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                CategoryCatalog.labelOf(category),
                style: context.texts.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: Insets.sm),
            Text(
              Formatters.percent(progress),
              style: context.money.small.copyWith(color: trackColor),
            ),
          ],
        ),
        const SizedBox(height: Insets.sm),
        ClipRRect(
          borderRadius: Corners.pillRadius,
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: Strokes.progress,
            backgroundColor: context.colors.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(trackColor),
          ),
        ),
        const SizedBox(height: Insets.sm),
        // Both halves flex and ellipsize so the row survives a 360 px screen.
        Row(
          children: [
            Flexible(
              child: Text(
                '${Formatters.compactMoney(spentAmount, currency)} '
                'из ${Formatters.compactMoney(limitAmount, currency)}',
                style: context.texts.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: Insets.sm),
            if (progress >= 1.0)
              AppBadge(
                label:
                    'перерасход ${Formatters.compactMoney(-remaining, currency)}',
                tone: BadgeTone.danger,
                icon: Icons.priority_high,
              )
            else if (progress >= 0.9)
              AppBadge(
                label:
                    'осталось ${Formatters.compactMoney(remaining, currency)}',
                tone: BadgeTone.warning,
                icon: Icons.warning_amber_rounded,
              )
            else
              Flexible(
                child: Text(
                  'осталось ${Formatters.compactMoney(remaining, currency)}',
                  textAlign: TextAlign.end,
                  style: context.texts.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ],
    );

    if (onTap == null) {
      return row;
    }
    return InkWell(
      onTap: onTap,
      borderRadius: Corners.cardRadius,
      child: Padding(padding: const EdgeInsets.all(Insets.xs), child: row),
    );
  }
}
