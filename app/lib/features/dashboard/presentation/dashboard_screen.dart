import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/utils/formatters.dart';
import '../../accounts/presentation/accounts_screen.dart';
import 'widgets/accounts_strip.dart';
import 'widgets/dashboard_budgets_card.dart';
import 'widgets/expense_breakdown_card.dart';
import 'widgets/month_summary_card.dart';

/// Dashboard: balances, expense structure and budget progress for one month.
///
/// All numbers come from the mock data; the month is fixed at this stage —
/// picking a different one needs state the app does not have yet.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, this.onOpenBudgets});

  /// Switches the shell to the budgets tab.
  final VoidCallback? onOpenBudgets;

  /// Totals are shown in the user's default currency. Accounts in other
  /// currencies are listed separately and not converted — currency conversion
  /// is a separate, optional feature.
  static const String _displayCurrency = MockUser.defaultCurrency;

  void _openAccounts(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const AccountsScreen()));
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
            tooltip: 'Мои счета',
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
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DashboardBudgetsCard(
              budgets: mockBudgetProgress(month),
              currency: _displayCurrency,
              onSeeAll: onOpenBudgets,
            ),
          ),
        ],
      ),
    );
  }
}
