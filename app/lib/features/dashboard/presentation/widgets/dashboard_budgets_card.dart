import 'package:flutter/material.dart';

import '../../../../core/mock/mock_data.dart';
import '../../../../core/widgets/budget_progress_bar.dart';
import '../../../../core/widgets/state_views.dart';

/// Budgets block of the dashboard: one progress row per category, the most
/// used first, so an exceeded limit is the first thing visible.
class DashboardBudgetsCard extends StatelessWidget {
  const DashboardBudgetsCard({
    required this.budgets,
    required this.currency,
    super.key,
    this.onSeeAll,
  });

  final List<BudgetProgress> budgets;
  final String currency;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final warned = budgets.where((b) => b.isWarning || b.isExceeded).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Бюджеты', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        warned == 0
                            ? 'Все лимиты в норме'
                            : 'Требуют внимания: $warned',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onSeeAll != null)
                  TextButton(onPressed: onSeeAll, child: const Text('Все')),
              ],
            ),
            const SizedBox(height: 12),
            if (budgets.isEmpty)
              const EmptyState(
                icon: Icons.savings_outlined,
                title: 'Бюджетов нет',
                message: 'Поставьте лимит по категории, чтобы видеть прогресс.',
              )
            else
              for (final item in budgets) ...[
                BudgetProgressBar(
                  category: item.budget.category,
                  spentAmount: item.spentAmount,
                  limitAmount: item.budget.limitAmount,
                  currency: currency,
                ),
                if (item != budgets.last) const SizedBox(height: 18),
              ],
          ],
        ),
      ),
    );
  }
}
