import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/mock/mock_data.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_catalog.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/money_text.dart';
import '../../../../core/widgets/state_views.dart';

/// Donut chart of the month's expense structure with a legend underneath.
class ExpenseBreakdownCard extends StatelessWidget {
  const ExpenseBreakdownCard({
    required this.slices,
    required this.totalExpense,
    required this.currency,
    super.key,
  });

  final List<CategorySlice> slices;
  final double totalExpense;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Структура расходов', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Куда ушли деньги в этом месяце',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (slices.isEmpty)
              const EmptyState(
                icon: Icons.pie_chart_outline,
                title: 'Расходов пока нет',
                message: 'Добавьте первую трату, и здесь появится диаграмма.',
              )
            else ...[
              _Donut(
                slices: slices,
                totalExpense: totalExpense,
                currency: currency,
              ),
              const SizedBox(height: 20),
              _Legend(slices: slices, currency: currency),
            ],
          ],
        ),
      ),
    );
  }
}

class _Donut extends StatelessWidget {
  const _Donut({
    required this.slices,
    required this.totalExpense,
    required this.currency,
  });

  final List<CategorySlice> slices;
  final double totalExpense;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 62,
              startDegreeOffset: -90,
              sections: [
                for (final slice in slices)
                  PieChartSectionData(
                    value: slice.amount,
                    color: context.semantic.category(slice.category),
                    radius: 26,
                    showTitle: false,
                  ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Всего',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              MoneyText(
                amount: totalExpense,
                currency: currency,
                compact: true,
                size: MoneySize.large,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.slices, required this.currency});

  final List<CategorySlice> slices;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        for (final slice in slices)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: context.semantic.category(slice.category),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    CategoryCatalog.labelOf(slice.category),
                    style: theme.textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  Formatters.percent(slice.share),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                MoneyText(
                  amount: slice.amount,
                  currency: currency,
                  compact: true,
                  size: MoneySize.small,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
