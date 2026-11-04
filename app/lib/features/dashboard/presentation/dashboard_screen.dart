import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/state/clock.dart';
import '../../../core/utils/category_catalog.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_views.dart';
import '../../../core/widgets/month_switcher.dart';
import '../../../core/widgets/skeleton.dart';
import '../../home/application/data_refresh.dart';
import '../../transactions/domain/transaction_filter.dart';
import '../application/dashboard_providers.dart';
import 'widgets/accounts_strip.dart';
import 'widgets/dashboard_budgets_card.dart';
import 'widgets/expense_breakdown_card.dart';
import 'widgets/month_summary_card.dart';

/// Dashboard: balances, expense structure and budget progress for one month.
///
/// Opens on the current month; the switcher steps through earlier ones.
/// Everything shown comes from [dashboardProvider], so an operation added or
/// edited anywhere in the app is reflected here at once.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  late DateTime _month = _currentMonth;

  DateTime get _currentMonth {
    final today = ref.read(todayProvider);
    return DateTime(today.year, today.month);
  }

  void _shiftMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  /// Accounts are pushed, not switched to: back returns to the dashboard.
  void _openAccounts() {
    context.push(AppRoutes.accounts);
  }

  /// Jumps to the transactions tab, filtered to one expense category of the
  /// month — the answer to "what exactly did I spend on food?".
  void _openCategory(String category) {
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

  @override
  Widget build(BuildContext context) {
    final month = Formatters.monthKey(_month);
    final dashboard = ref.watch(dashboardProvider(month));

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.navDashboard),
        actions: [
          IconButton(
            onPressed: _openAccounts,
            icon: const Icon(Icons.account_balance_wallet_outlined),
            tooltip: AppStrings.accounts,
          ),
        ],
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
              value: dashboard,
              loading: const _DashboardSkeleton(),
              data: (data) => RefreshIndicator(
                onRefresh: () => refreshAllData(ref),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(top: 4, bottom: 24),
                  children: [
                    AccountsStrip(
                      accounts: data.accounts,
                      onAccountTap: (_) => _openAccounts(),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: MonthSummaryCard(
                        totalIncome: data.summary.totalIncome,
                        totalExpense: data.summary.totalExpense,
                        currency: data.currency,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ExpenseBreakdownCard(
                        slices: data.summary.byCategory,
                        totalExpense: data.summary.totalExpense,
                        currency: data.currency,
                        onCategoryTap: _openCategory,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DashboardBudgetsCard(
                        budgets: data.budgets,
                        currency: data.currency,
                        onSeeAll: () =>
                            context.go(AppRoutes.budgetsOfMonth(month)),
                        onBudgetTap: _openCategory,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// First-load placeholder in the shape of the dashboard.
class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: const [
        Row(
          children: [
            Expanded(child: CardSkeleton(height: 132)),
            SizedBox(width: 12),
            Expanded(child: CardSkeleton(height: 132)),
          ],
        ),
        SizedBox(height: 16),
        CardSkeleton(height: 76),
        SizedBox(height: 16),
        CardSkeleton(height: 280),
      ],
    );
  }
}
