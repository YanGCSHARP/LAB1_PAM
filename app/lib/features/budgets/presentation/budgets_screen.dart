import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/category_catalog.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/budget_progress_bar.dart';
import '../../../core/widgets/money_text.dart';
import '../../../core/widgets/state_views.dart';
import '../../transactions/domain/transaction_filter.dart';

/// Monthly limits per category with their progress.
///
/// Tapping a budget opens its form; «Операции» under it jumps to the
/// transactions behind the number.
class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key, this.initialMonth});

  /// Month key `YYYY-MM` from the URL; the demo "today" when absent.
  final String? initialMonth;

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  late DateTime _month = _parseMonth(widget.initialMonth);

  static const String _currency = MockUser.defaultCurrency;

  static DateTime _parseMonth(String? key) {
    final parsed = key == null ? null : DateTime.tryParse('$key-01');
    final source = parsed ?? mockToday;
    return DateTime(source.year, source.month);
  }

  @override
  void didUpdateWidget(BudgetsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The dashboard links here with a month in the URL; follow it.
    if (widget.initialMonth != oldWidget.initialMonth &&
        widget.initialMonth != null) {
      _month = _parseMonth(widget.initialMonth);
    }
  }

  void _shiftMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  void _openTransactions(String category) {
    context.go(
      AppRoutes.transactionsFiltered(
        TransactionFilter(
          kind: TransactionKind.expense,
          category: category,
          month: Formatters.monthKey(_month),
        ),
      ),
    );
  }

  void _openNew() {
    context.push(AppRoutes.budgetNew(month: Formatters.monthKey(_month)));
  }

  @override
  Widget build(BuildContext context) {
    final budgets = mockBudgetProgress(_month);
    final totalLimit = budgets.fold<double>(
      0,
      (sum, item) => sum + item.budget.limitAmount,
    );
    final totalSpent = budgets.fold<double>(
      0,
      (sum, item) => sum + item.spentAmount,
    );

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.navBudgets)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNew,
        icon: const Icon(Icons.add),
        label: const Text('Бюджет'),
      ),
      body: Column(
        children: [
          _MonthSwitcher(
            month: _month,
            onPrevious: () => _shiftMonth(-1),
            onNext: () => _shiftMonth(1),
          ),
          Expanded(
            child: budgets.isEmpty
                ? EmptyState(
                    icon: Icons.savings_outlined,
                    title: 'Бюджетов на этот месяц нет',
                    message:
                        'Поставьте лимит по категории — прогресс появится '
                        'здесь и на панели.',
                    actionLabel: 'Создать бюджет',
                    onAction: _openNew,
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      Insets.lg,
                      Insets.xs,
                      Insets.lg,
                      96,
                    ),
                    children: [
                      AppCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Потрачено',
                                    style: context.texts.bodySmall,
                                  ),
                                  const SizedBox(height: Insets.xs),
                                  MoneyText(
                                    amount: totalSpent,
                                    currency: _currency,
                                    size: MoneySize.large,
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Лимит', style: context.texts.bodySmall),
                                const SizedBox(height: Insets.xs),
                                MoneyText(
                                  amount: totalLimit,
                                  currency: _currency,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: Insets.md),
                      for (final item in budgets) ...[
                        AppCard(
                          padding: const EdgeInsets.fromLTRB(
                            Insets.md,
                            Insets.md,
                            Insets.md,
                            Insets.xs,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              BudgetProgressBar(
                                category: item.budget.category,
                                spentAmount: item.spentAmount,
                                limitAmount: item.budget.limitAmount,
                                currency: _currency,
                                onTap: () => context.push(
                                  AppRoutes.budgetEdit(item.budget.id),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () =>
                                      _openTransactions(item.budget.category),
                                  icon: const Icon(
                                    Icons.receipt_long_outlined,
                                    size: IconSizes.sm,
                                  ),
                                  label: const Text('Операции'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: Insets.md),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _MonthSwitcher extends StatelessWidget {
  const _MonthSwitcher({
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Insets.sm),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Предыдущий месяц',
          ),
          Expanded(
            child: Text(
              Formatters.monthTitle(month),
              textAlign: TextAlign.center,
              style: context.texts.titleMedium,
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Следующий месяц',
          ),
        ],
      ),
    );
  }
}
