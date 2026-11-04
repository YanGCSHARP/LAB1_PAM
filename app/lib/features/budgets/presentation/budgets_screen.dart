import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/state/clock.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/category_catalog.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_views.dart';
import '../../../core/widgets/budget_progress_bar.dart';
import '../../../core/widgets/money_text.dart';
import '../../../core/widgets/month_switcher.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/state_views.dart';
import '../../home/application/data_refresh.dart';
import '../../transactions/domain/transaction_filter.dart';
import '../application/budgets_providers.dart';

/// Monthly limits per category with their progress.
///
/// Tapping a budget opens its form; «Операции» under it jumps to the
/// transactions behind the number.
class BudgetsScreen extends ConsumerStatefulWidget {
  const BudgetsScreen({super.key, this.initialMonth});

  /// Month key `YYYY-MM` from the URL; the current month when absent.
  final String? initialMonth;

  @override
  ConsumerState<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends ConsumerState<BudgetsScreen> {
  late DateTime _month = _parseMonth(widget.initialMonth);

  DateTime _parseMonth(String? key) {
    final parsed = key == null ? null : DateTime.tryParse('$key-01');
    final DateTime source = parsed ?? ref.read(todayProvider);
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
    final overview = ref.watch(
      budgetsOverviewProvider(Formatters.monthKey(_month)),
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
          MonthSwitcher(
            month: _month,
            onPrevious: () => _shiftMonth(-1),
            onNext: () => _shiftMonth(1),
          ),
          Expanded(
            child: AsyncValueView(
              value: overview,
              loading: ListView(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  Insets.lg,
                  Insets.xs,
                  Insets.lg,
                  0,
                ),
                children: const [
                  CardSkeleton(height: 76),
                  SizedBox(height: Insets.md),
                  CardSkeleton(height: 112),
                  SizedBox(height: Insets.md),
                  CardSkeleton(height: 112),
                ],
              ),
              data: (overview) => _buildList(overview),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BudgetsOverview overview) {
    final budgets = overview.items;
    final currency = overview.currency;
    final totalLimit = Money.sum(
      budgets.map((item) => item.budget.limitAmount),
    );
    final totalSpent = Money.sum(budgets.map((item) => item.spentAmount));

    return budgets.isEmpty
        ? EmptyState(
            icon: Icons.savings_outlined,
            title: 'Бюджетов на этот месяц нет',
            message:
                'Поставьте лимит по категории — прогресс появится '
                'здесь и на панели.',
            actionLabel: 'Создать бюджет',
            onAction: _openNew,
          )
        : RefreshIndicator(
            onRefresh: () => refreshAllData(ref),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
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
                            Text('Потрачено', style: context.texts.bodySmall),
                            const SizedBox(height: Insets.xs),
                            MoneyText(
                              amount: totalSpent,
                              currency: currency,
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
                          MoneyText(amount: totalLimit, currency: currency),
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
                          currency: currency,
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
          );
  }
}
