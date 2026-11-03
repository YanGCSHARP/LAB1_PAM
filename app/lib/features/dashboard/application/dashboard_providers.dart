import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../accounts/application/accounts_providers.dart';
import '../../accounts/domain/account.dart';
import '../../accounts/domain/balances.dart';
import '../../budgets/application/budgets_providers.dart';
import '../../budgets/domain/budget.dart';
import '../../budgets/domain/budget_progress.dart';
import '../../profile/application/profile_providers.dart';
import '../../profile/domain/user_profile.dart';
import '../../transactions/application/transactions_providers.dart';
import '../../transactions/domain/transaction.dart';
import '../domain/month_summary.dart';

/// Everything the dashboard shows for one month.
typedef DashboardData = ({
  List<AccountBalance> accounts,
  MonthSummary summary,
  List<BudgetProgress> budgets,
  String currency,
});

/// The dashboard of [month] (`YYYY-MM`), derived from accounts, operations,
/// budgets and the profile — the client-side version of
/// `GET /dashboard/summary`.
///
/// Totals are in the user's default currency and count only accounts in that
/// currency; accounts in other currencies are listed with their own balances
/// and never converted.
final dashboardProvider = FutureProvider.autoDispose
    .family<DashboardData, String>((ref, month) async {
      // All four requests start at once; the first failure is reported as is.
      final [
        profile as UserProfile,
        accounts as List<AccountBalance>,
        transactions as List<Transaction>,
        budgets as List<Budget>,
      ] = await Future.wait([
        ref.watch(profileProvider.future),
        ref.watch(accountBalancesProvider.future),
        ref.watch(transactionsProvider.future),
        ref.watch(budgetsProvider.future),
      ]);
      final currency = profile.defaultCurrency;
      final counted = transactionsInCurrency(
        transactions,
        accounts.map((item) => item.account),
        currency,
      );
      return (
        accounts: accounts,
        summary: MonthSummary.of(counted, month),
        budgets: computeBudgetProgress(budgets, counted, month),
        currency: currency,
      );
    });
