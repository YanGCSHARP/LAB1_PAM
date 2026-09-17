import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/money_text.dart';

/// Income and expense totals of the selected month, side by side.
class MonthSummaryCard extends StatelessWidget {
  const MonthSummaryCard({
    required this.totalIncome,
    required this.totalExpense,
    required this.currency,
    super.key,
  });

  final double totalIncome;
  final double totalExpense;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semantic;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: _SummaryCell(
                label: AppStrings.income,
                amount: totalIncome,
                currency: currency,
                color: semantic.income,
                icon: Icons.south_west,
              ),
            ),
            Container(
              width: 1,
              height: 44,
              color: theme.colorScheme.outlineVariant,
              margin: const EdgeInsets.symmetric(horizontal: 12),
            ),
            Expanded(
              child: _SummaryCell(
                label: AppStrings.expense,
                amount: totalExpense,
                currency: currency,
                color: semantic.expense,
                icon: Icons.north_east,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell({
    required this.label,
    required this.amount,
    required this.currency,
    required this.color,
    required this.icon,
  });

  final String label;
  final double amount;
  final String currency;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        MoneyText(amount: amount, currency: currency, color: color),
      ],
    );
  }
}
