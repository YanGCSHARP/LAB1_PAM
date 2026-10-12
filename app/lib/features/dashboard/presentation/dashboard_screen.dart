import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/utils/category_catalog.dart';
import '../../../core/utils/formatters.dart';
import '../../transactions/domain/transaction_filter.dart';
import 'widgets/accounts_strip.dart';
import 'widgets/dashboard_budgets_card.dart';
import 'widgets/expense_breakdown_card.dart';
import 'widgets/month_summary_card.dart';

/// Dashboard: balances, expense structure and budget progress for one month.
///
/// All numbers come from the mock data; the month is fixed at this stage —
/// picking a different one needs state the app does not have yet.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  /// Totals are shown in the user's default currency. Accounts in other
  /// currencies are listed separately and not converted — currency conversion
  /// is a separate, optional feature.
  static const String _displayCurrency = MockUser.defaultCurrency;

  /// Accounts are pushed, not switched to: back returns to the dashboard.
  void _openAccounts(BuildContext context) {
    context.push(AppRoutes.accounts);
  }

  /// Jumps to the transactions tab, filtered to one expense category of the
  /// month — the answer to "what exactly did I spend on food?".
  void _openCategory(BuildContext context, String category, DateTime month) {
    context.go(
      AppRoutes.transactionsFiltered(
        TransactionFilter(
          kind: TransactionKind.expense,
          category: category,
          month: Formatters.monthKey(month),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final month = DateTime(mockToday.year, mockToday.month);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.navDashboard),
        actions: [
          IconButton(
            onPressed: () => _openAccounts(context),
            icon: const Icon(Icons.account_balance_wallet_outlined),
            tooltip: AppStrings.accounts,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Text(
              Formatters.monthTitle(month),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          AccountsStrip(
            accounts: mockAccounts,
            onAccountTap: (_) => _openAccounts(context),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: MonthSummaryCard(
              totalIncome: mockTotalIncome(month),
              totalExpense: mockTotalExpense(month),
              currency: _displayCurrency,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ExpenseBreakdownCard(
              slices: mockCategoryBreakdown(month),
              totalExpense: mockTotalExpense(month),
              currency: _displayCurrency,
              onCategoryTap: (category) =>
                  _openCategory(context, category, month),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DashboardBudgetsCard(
              budgets: mockBudgetProgress(month),
              currency: _displayCurrency,
              onSeeAll: () => context.go(
                AppRoutes.budgetsOfMonth(Formatters.monthKey(month)),
              ),
              onBudgetTap: (category) =>
                  _openCategory(context, category, month),
            ),
          ),
        ],
      ),
    );
  }
}
