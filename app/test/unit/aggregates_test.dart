import 'package:flutter_test/flutter_test.dart';
import 'package:walletmate/core/utils/category_catalog.dart';
import 'package:walletmate/core/utils/formatters.dart';
import 'package:walletmate/core/utils/money.dart';
import 'package:walletmate/features/accounts/domain/account.dart';
import 'package:walletmate/features/accounts/domain/balances.dart';
import 'package:walletmate/features/budgets/domain/budget.dart';
import 'package:walletmate/features/budgets/domain/budget_progress.dart';
import 'package:walletmate/features/dashboard/domain/month_summary.dart';
import 'package:walletmate/features/transactions/domain/transaction.dart';

import '../helpers/test_app.dart';

Transaction _expense(
  double amount, {
  String category = 'food',
  String accountId = 'acc-1',
  DateTime? date,
}) {
  return Transaction(
    id: 'tx-$amount-$category',
    accountId: accountId,
    amount: amount,
    kind: TransactionKind.expense,
    category: category,
    date: date ?? DateTime(2026, 9, 10).toUtc(),
  );
}

BudgetProgress _progress(double limit, List<double> spent) {
  final budget = Budget(
    id: 'bud',
    category: 'food',
    limitAmount: limit,
    month: '2026-09',
  );
  return computeBudgetProgress(
    [budget],
    [for (final amount in spent) _expense(amount)],
    '2026-09',
  ).single;
}

void main() {
  group('Money', () {
    test('sums to the cent where doubles drift', () {
      // 0.7 + 0.1 + 0.1 == 0.8999999999999999 in floating point.
      expect(0.7 + 0.1 + 0.1, isNot(0.9));
      expect(Money.sum([0.7, 0.1, 0.1]), 0.9);
    });

    test('ratio is 0 for a non-positive whole', () {
      expect(Money.ratio(10, 0), 0);
      expect(Money.ratio(10, -5), 0);
      expect(Money.ratio(45, 50), 0.9);
    });
  });

  test('Russian plural forms', () {
    String form(int n) =>
        Formatters.plural(n, 'операция', 'операции', 'операций');
    expect([1, 21, 101].map(form), everyElement('операция'));
    expect([2, 4, 22, 104].map(form), everyElement('операции'));
    expect([0, 5, 11, 12, 14, 111, 25].map(form), everyElement('операций'));
  });

  group('balances', () {
    test('opening balance plus income minus expenses, per account', () {
      final balances = computeBalances(
        testSeed.accounts,
        testSeed.transactions,
      );

      expect(balances.map((item) => item.account.id), [
        'acc-1',
        'acc-2',
        'acc-3',
      ]);
      // 1 250 + 17 000 income − 7 402,80 expenses.
      expect(balances[0].balance, 10847.20);
      // 1 500 − 1 267,70 expenses, no income.
      expect(balances[1].balance, 232.30);
      // 250 EUR + a 100 EUR gift.
      expect(balances[2].balance, 350);
    });

    test('an account without operations keeps its opening balance', () {
      const account = Account(
        id: 'acc-9',
        name: 'Кредитка',
        currency: 'MDL',
        openingBalance: -500,
      );
      expect(computeBalances([account], const []).single.balance, -500);
    });

    test('totals are kept apart per currency', () {
      final totals = totalsByCurrency(
        computeBalances(testSeed.accounts, testSeed.transactions),
      );
      expect(totals, {'MDL': 11079.50, 'EUR': 350});
    });

    test('transactionsInCurrency keeps only accounts in that currency', () {
      final eur = transactionsInCurrency(
        testSeed.transactions,
        testSeed.accounts,
        'EUR',
      );
      expect(eur.map((t) => t.id), ['tx-26']);
    });
  });

  group('MonthSummary', () {
    final mdl = transactionsInCurrency(
      testSeed.transactions,
      testSeed.accounts,
      'MDL',
    );

    test('totals of September', () {
      final summary = MonthSummary.of(mdl, '2026-09');

      expect(summary.totalIncome, 9200);
      expect(summary.totalExpense, 4980);
    });

    test('categories are sorted by amount and shares add up to 1', () {
      final slices = MonthSummary.of(mdl, '2026-09').byCategory;

      expect(slices.first.category, 'housing');
      expect(slices.first.amount, 1500);
      expect(slices[1].category, 'food');
      expect(slices[1].amount, 1200);
      final total = slices.fold<double>(0, (sum, s) => sum + s.share);
      expect(total, closeTo(1, 1e-9));
    });

    test('a month without operations is all zeros', () {
      final summary = MonthSummary.of(mdl, '2026-07');

      expect(summary.totalIncome, 0);
      expect(summary.totalExpense, 0);
      expect(summary.byCategory, isEmpty);
    });

    test('an operation counts in the month of its local date', () {
      // 1 October 00:30 local time is still 30 September in UTC east of
      // Greenwich; the dashboard groups by what the user saw on the clock.
      final late = _expense(50, date: DateTime(2026, 10, 1, 0, 30).toUtc());

      expect(MonthSummary.of([late], '2026-10').totalExpense, 50);
      expect(MonthSummary.of([late], '2026-09').totalExpense, 0);
    });
  });

  group('budget progress', () {
    test('September demo budgets: food warns, transport is over', () {
      final progress = computeBudgetProgress(
        testSeed.budgets,
        transactionsInCurrency(testSeed.transactions, testSeed.accounts, 'MDL'),
        '2026-09',
      );
      final byCategory = {for (final p in progress) p.budget.category: p};

      expect(byCategory['food']!.spentAmount, 1200);
      expect(byCategory['food']!.status, BudgetStatus.warning);
      expect(byCategory['transport']!.spentAmount, 640);
      expect(byCategory['transport']!.status, BudgetStatus.exceeded);
      expect(byCategory['transport']!.remaining, -40);
      // Most used first.
      expect(progress.first.budget.category, 'transport');
    });

    test('89.9 % is normal', () {
      expect(_progress(1000, [899]).status, BudgetStatus.normal);
    });

    test('exactly 90 % is a warning', () {
      expect(_progress(1000, [900]).status, BudgetStatus.warning);
    });

    test('99.99 % is still a warning', () {
      expect(_progress(1000, [999.99]).status, BudgetStatus.warning);
    });

    test('exactly 100 % is exceeded', () {
      expect(_progress(1000, [1000]).status, BudgetStatus.exceeded);
    });

    test('90 % reached by a sum that drifts in floating point', () {
      // 0.7 + 0.1 + 0.1 would be 89.99… % without summing in cents.
      expect(_progress(1, [0.7, 0.1, 0.1]).status, BudgetStatus.warning);
    });

    test('income, other categories and other months do not count', () {
      final budget = Budget(
        id: 'bud',
        category: 'food',
        limitAmount: 100,
        month: '2026-09',
      );
      final progress = computeBudgetProgress(
        [budget],
        [
          _expense(10),
          _expense(20, category: 'transport'),
          _expense(30, date: DateTime(2026, 8, 31, 12).toUtc()),
          Transaction(
            id: 'income',
            accountId: 'acc-1',
            amount: 40,
            kind: TransactionKind.income,
            category: 'other',
            date: DateTime(2026, 9, 5).toUtc(),
          ),
        ],
        '2026-09',
      ).single;

      expect(progress.spentAmount, 10);
    });

    test('budgets of other months are left out', () {
      final progress = computeBudgetProgress(
        testSeed.budgets,
        testSeed.transactions,
        '2026-08',
      );
      expect(progress, isEmpty);
    });
  });
}
