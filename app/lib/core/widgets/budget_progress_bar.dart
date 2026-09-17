import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/category_catalog.dart';
import '../utils/formatters.dart';
import 'money_text.dart';

/// One budget row: category, spent-of-limit and a progress bar colored by the
/// project thresholds — amber from 90%, red from 100%.
class BudgetProgressBar extends StatelessWidget {
  const BudgetProgressBar({
    required this.category,
    required this.spentAmount,
    required this.limitAmount,
    required this.currency,
    super.key,
    this.onTap,
    this.showRemaining = true,
  });

  final String category;
  final double spentAmount;
  final double limitAmount;
  final String currency;
  final VoidCallback? onTap;

  /// Shows the "осталось" / "превышение" line under the bar.
  final bool showRemaining;

  double get _progress => limitAmount <= 0 ? 0 : spentAmount / limitAmount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semanticColors;
    final progress = _progress;

    final Color barColor;
    if (progress >= 1.0) {
      barColor = semantic.danger;
    } else if (progress >= 0.9) {
      barColor = semantic.warning;
    } else {
      barColor = theme.colorScheme.primary;
    }

    final remaining = limitAmount - spentAmount;

    final row = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                CategoryCatalog.labelOf(category),
                style: theme.textTheme.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              Formatters.percent(progress),
              style: theme.textTheme.labelLarge?.copyWith(color: barColor),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DefaultTextStyle.merge(
                style: theme.textTheme.bodySmall!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                child: Row(
                  children: [
                    MoneyText(
                      amount: spentAmount,
                      currency: currency,
                      compact: true,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(' из ', style: theme.textTheme.bodySmall),
                    Flexible(
                      child: MoneyText(
                        amount: limitAmount,
                        currency: currency,
                        compact: true,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (showRemaining) ...[
              const SizedBox(width: 8),
              Text(
                remaining >= 0
                    ? 'осталось ${Formatters.compactMoney(remaining, currency)}'
                    : 'перерасход ${Formatters.compactMoney(-remaining, currency)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: remaining >= 0
                      ? theme.colorScheme.onSurfaceVariant
                      : semantic.danger,
                ),
              ),
            ],
          ],
        ),
      ],
    );

    if (onTap == null) {
      return row;
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(padding: const EdgeInsets.all(4), child: row),
    );
  }
}
