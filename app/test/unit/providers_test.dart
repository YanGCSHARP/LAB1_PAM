import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walletmate/core/data/mock/mock_providers.dart';
import 'package:walletmate/core/data/repository_exception.dart';
import 'package:walletmate/core/utils/category_catalog.dart';
import 'package:walletmate/features/accounts/application/accounts_providers.dart';
import 'package:walletmate/features/budgets/application/budgets_providers.dart';
import 'package:walletmate/features/budgets/domain/budget_progress.dart';
import 'package:walletmate/features/dashboard/application/dashboard_providers.dart';
import 'package:walletmate/features/profile/application/profile_providers.dart';
import 'package:walletmate/features/transactions/application/transactions_providers.dart';

import '../helpers/test_app.dart';

/// Keeps an auto-disposed provider alive for the test and returns its value
/// once loaded.
Future<T> _load<T>(
  ProviderContainer container,
  FutureProvider<T> provider,
) async {
  final subscription = container.listen(provider, (_, _) {});
  addTearDown(subscription.close);
  return container.read(provider.future);
}

void main() {
  late ProviderContainer container;

  setUp(() => container = createTestContainer());

  Future<DashboardData> dashboard([String month = '2026-09']) =>
      _load(container, dashboardProvider(month));

  test('the dashboard of September matches the demo data', () async {
    final data = await dashboard();

    expect(data.currency, 'MDL');
    expect(data.accounts, hasLength(3));
    expect(data.summary.totalIncome, 9200);
    expect(data.summary.totalExpense, 4980);
    expect(data.budgets, hasLength(5));
  });

  test('an added expense updates balance, totals and budget at once', () async {
    final before = await dashboard();
    final foodBefore = before.budgets.firstWhere(
      (b) => b.budget.category == 'food',
    );
    expect(foodBefore.status, BudgetStatus.warning);

    await container
        .read(transactionsProvider.notifier)
        .add(
          accountId: 'acc-2',
          amount: 150,
          kind: TransactionKind.expense,
          category: 'food',
          date: testToday,
        );

    final after = await dashboard();
    final food = after.budgets.firstWhere((b) => b.budget.category == 'food');
    final cash = after.accounts.firstWhere((a) => a.account.id == 'acc-2');

    expect(after.summary.totalExpense, 5130);
    expect(cash.balance, 82.30);
    expect(food.spentAmount, 1350);
    expect(food.status, BudgetStatus.exceeded);
  });

  test('an edited operation moves between months', () async {
    final rent = testSeed.transactions.firstWhere((t) => t.id == 'tx-04');
    await container
        .read(transactionsProvider.notifier)
        .save(rent.copyWith(date: DateTime(2026, 8, 30, 10).toUtc()));

    expect((await dashboard()).summary.totalExpense, 3480);
    expect((await dashboard('2026-08')).summary.totalExpense, 5190.50);
  });

  test('deleting an account removes its operations everywhere', () async {
    await dashboard();
    await container.read(accountsProvider.notifier).delete('acc-2');

    final transactions = await container.read(transactionsProvider.future);
    expect(transactions.where((t) => t.accountId == 'acc-2'), isEmpty);

    final data = await dashboard();
    expect(data.accounts, hasLength(2));
    // 807,70 of September spending was on the cash account.
    expect(data.summary.totalExpense, 4172.30);
  });

  test('the default currency decides what the dashboard counts', () async {
    await container.read(profileProvider.notifier).changeCurrency('EUR');

    final august = await dashboard('2026-08');
    expect(august.currency, 'EUR');
    // Only the EUR savings account counts: the 100 EUR gift.
    expect(august.summary.totalIncome, 100);
    expect(august.summary.totalExpense, 0);
    // Budgets are in MDL and have no EUR spending.
    final september = await dashboard();
    expect(september.budgets.every((b) => b.spentAmount == 0), isTrue);
  });

  test('a created budget shows up with its progress', () async {
    await container
        .read(budgetsProvider.notifier)
        .create(category: 'education', limitAmount: 500, month: '2026-09');

    final overview = await _load(container, budgetsOverviewProvider('2026-09'));
    final education = overview.items.firstWhere(
      (b) => b.budget.category == 'education',
    );
    expect(education.spentAmount, 350);
    expect(education.progress, 0.7);
  });

  test('a failed change leaves the state as it was', () async {
    final before = await container.read(transactionsProvider.future);
    container.read(simulateOfflineProvider.notifier).set(offline: true);

    await expectLater(
      container.read(transactionsProvider.notifier).delete('tx-01'),
      throwsA(isA<NetworkException>()),
    );
    expect(container.read(transactionsProvider).value, before);
  });

  test('a load error surfaces, and a reload recovers', () async {
    container.read(simulateOfflineProvider.notifier).set(offline: true);

    await expectLater(
      container.read(accountsProvider.future),
      throwsA(isA<NetworkException>()),
    );
    expect(container.read(accountsProvider).hasError, isTrue);

    container.read(simulateOfflineProvider.notifier).set(offline: false);
    container.invalidate(accountsProvider);

    expect(await container.read(accountsProvider.future), hasLength(3));
  });

  test('form data resolves to null for an unknown id', () async {
    expect(await _load(container, transactionFormDataProvider('nope')), isNull);
    expect(await _load(container, budgetFormDataProvider('nope')), isNull);
    expect(await _load(container, accountFormDataProvider('nope')), isNull);
    expect(await _load(container, transactionDetailsProvider('nope')), isNull);

    final details = await _load(container, transactionDetailsProvider('tx-17'));
    expect(details!.account!.name, 'Наличные');
  });
}
