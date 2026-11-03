import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/mock/mock_providers.dart';
import '../../accounts/application/accounts_providers.dart';
import '../../accounts/domain/account.dart';
import '../../accounts/domain/balances.dart';
import '../../profile/application/profile_providers.dart';
import '../../profile/domain/user_profile.dart';
import '../../transactions/application/transactions_providers.dart';
import '../../transactions/domain/transaction.dart';
import '../data/budget_repository.dart';
import '../data/mock_budget_repository.dart';
import '../domain/budget.dart';
import '../domain/budget_progress.dart';

/// The only place that decides which [BudgetRepository] the app uses.
final budgetRepositoryProvider = Provider<BudgetRepository>(
  (ref) => MockBudgetRepository(ref.watch(mockBackendProvider)),
);

/// Every budget of the user, for all months.
final budgetsProvider = AsyncNotifierProvider<BudgetsNotifier, List<Budget>>(
  BudgetsNotifier.new,
);

class BudgetsNotifier extends AsyncNotifier<List<Budget>> {
  BudgetRepository get _repository => ref.read(budgetRepositoryProvider);

  @override
  Future<List<Budget>> build() {
    return ref.watch(budgetRepositoryProvider).fetchAll();
  }

  Future<Budget> create({
    required String category,
    required double limitAmount,
    required String month,
  }) async {
    final budget = await _repository.create(
      category: category,
      limitAmount: limitAmount,
      month: month,
    );
    _change((budgets) => [...budgets, budget]);
    return budget;
  }

  Future<Budget> save(Budget budget) async {
    final updated = await _repository.update(budget);
    _change(
      (budgets) => [
        for (final item in budgets) item.id == updated.id ? updated : item,
      ],
    );
    return updated;
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    _change(
      (budgets) => [
        for (final item in budgets)
          if (item.id != id) item,
      ],
    );
  }

  void _change(List<Budget> Function(List<Budget> budgets) change) {
    final current = state.value;
    if (current == null) {
      ref.invalidateSelf();
      return;
    }
    state = AsyncData(change(current));
  }
}

/// Budgets of one month with their progress, and the currency they are in.
typedef BudgetsOverview = ({List<BudgetProgress> items, String currency});

/// Budget progress for [month] (`YYYY-MM`), most used first.
///
/// Limits are in the user's default currency, so only operations on accounts
/// in that currency count towards them.
final budgetsOverviewProvider = FutureProvider.autoDispose
    .family<BudgetsOverview, String>((ref, month) async {
      final [
        profile as UserProfile,
        budgets as List<Budget>,
        accounts as List<Account>,
        transactions as List<Transaction>,
      ] = await Future.wait([
        ref.watch(profileProvider.future),
        ref.watch(budgetsProvider.future),
        ref.watch(accountsProvider.future),
        ref.watch(transactionsProvider.future),
      ]);
      final currency = profile.defaultCurrency;
      return (
        items: computeBudgetProgress(
          budgets,
          transactionsInCurrency(transactions, accounts, currency),
          month,
        ),
        currency: currency,
      );
    });

/// What the budget form needs: the budget being edited (`null` for a new
/// one), every budget for the uniqueness check, and the currency of limits.
typedef BudgetFormData = ({
  Budget? budget,
  List<Budget> budgets,
  String currency,
});

/// Form data for budget [id], or for a new budget when [id] is `null`.
/// Resolves to `null` when [id] matches no budget.
final budgetFormDataProvider = FutureProvider.autoDispose
    .family<BudgetFormData?, String?>((ref, id) async {
      final [
        budgets as List<Budget>,
        profile as UserProfile,
      ] = await Future.wait([
        ref.watch(budgetsProvider.future),
        ref.watch(profileProvider.future),
      ]);
      final currency = profile.defaultCurrency;
      if (id == null) {
        return (budget: null, budgets: budgets, currency: currency);
      }
      final budget = budgets.where((item) => item.id == id).firstOrNull;
      return budget == null
          ? null
          : (budget: budget, budgets: budgets, currency: currency);
    });
