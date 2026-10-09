import 'package:flutter/foundation.dart';

import '../utils/category_catalog.dart';

/// Hard-coded data the static screens are built on.
///
/// This is the only source of numbers for stage L2: there is no repository, no
/// network and no database yet. The lightweight classes below carry just the
/// fields the screens display; real domain models with `copyWith`/`toJson`
/// arrive together with the repositories.
/// Account type — decides the icon and tint of an account card.
enum AccountKind { card, cash, savings }

@immutable
class MockAccount {
  const MockAccount({
    required this.id,
    required this.name,
    required this.currency,
    required this.balance,
    required this.kind,
  });

  final String id;
  final String name;
  final String currency;
  final AccountKind kind;

  /// Stored as a plain field while the data is static; computed from
  /// transactions once the repositories land.
  final double balance;
}

@immutable
class MockTransaction {
  const MockTransaction({
    required this.id,
    required this.accountId,
    required this.amount,
    required this.kind,
    required this.category,
    required this.date,
    this.note,
  });

  final String id;
  final String accountId;

  /// Always positive; the direction is carried by [kind].
  final double amount;
  final TransactionKind kind;
  final String category;

  /// Stored in UTC, formatted in local time.
  final DateTime date;
  final String? note;

  bool get isIncome => kind == TransactionKind.income;
}

@immutable
class MockBudget {
  const MockBudget({
    required this.id,
    required this.category,
    required this.limitAmount,
    required this.month,
  });

  final String id;
  final String category;
  final double limitAmount;

  /// Month key in `YYYY-MM` format.
  final String month;
}

/// A slice of the dashboard expense chart.
@immutable
class CategorySlice {
  const CategorySlice({
    required this.category,
    required this.amount,
    required this.share,
  });

  final String category;
  final double amount;

  /// Fraction of the month's total expenses, 0..1.
  final double share;
}

/// A budget together with the amount already spent in its month.
@immutable
class BudgetProgress {
  const BudgetProgress({required this.budget, required this.spentAmount});

  final MockBudget budget;
  final double spentAmount;

  double get progress =>
      budget.limitAmount <= 0 ? 0 : spentAmount / budget.limitAmount;

  double get remaining => budget.limitAmount - spentAmount;

  bool get isExceeded => progress >= 1.0;

  bool get isWarning => progress >= 0.9 && progress < 1.0;
}

/// The demo user shown on the profile screen.
abstract final class MockUser {
  static const String displayName = 'Ion Rusu';
  static const String email = 'ion.rusu@student.utm.md';
  static const String defaultCurrency = 'MDL';
  static const String initials = 'IR';
}

/// Fixed "today" for the static screens, so the demo data always looks fresh
/// and the grouped list always has a `Сегодня` section.
final DateTime mockToday = DateTime(2026, 9, 18);

const List<MockAccount> mockAccounts = [
  MockAccount(
    id: 'acc-1',
    name: 'Карта Maib',
    currency: 'MDL',
    balance: 4210.50,
    kind: AccountKind.card,
  ),
  MockAccount(
    id: 'acc-2',
    name: 'Наличные',
    currency: 'MDL',
    balance: 780.00,
    kind: AccountKind.cash,
  ),
  MockAccount(
    id: 'acc-3',
    name: 'Сбережения',
    currency: 'EUR',
    balance: 350.00,
    kind: AccountKind.savings,
  ),
];

/// 27 transactions across September and August 2026.
final List<MockTransaction> mockTransactions = [
  // ---------- September 2026 ----------
  MockTransaction(
    id: 'tx-01',
    accountId: 'acc-1',
    amount: 1600.00,
    kind: TransactionKind.income,
    category: 'scholarship',
    date: DateTime.utc(2026, 9, 1, 8, 30),
    note: 'Стипендия за сентябрь',
  ),
  MockTransaction(
    id: 'tx-02',
    accountId: 'acc-1',
    amount: 249.90,
    kind: TransactionKind.expense,
    category: 'food',
    date: DateTime.utc(2026, 9, 2, 17, 40),
    note: 'Продукты, Linella',
  ),
  MockTransaction(
    id: 'tx-03',
    accountId: 'acc-2',
    amount: 200.00,
    kind: TransactionKind.expense,
    category: 'transport',
    date: DateTime.utc(2026, 9, 3, 7, 15),
    note: 'Проездной на троллейбус',
  ),
  MockTransaction(
    id: 'tx-04',
    accountId: 'acc-1',
    amount: 1500.00,
    kind: TransactionKind.expense,
    category: 'housing',
    date: DateTime.utc(2026, 9, 4, 10),
    note: 'Аренда квартиры',
  ),
  MockTransaction(
    id: 'tx-05',
    accountId: 'acc-1',
    amount: 6400.00,
    kind: TransactionKind.income,
    category: 'salary',
    date: DateTime.utc(2026, 9, 5, 9),
    note: 'Зарплата за август',
  ),
  MockTransaction(
    id: 'tx-06',
    accountId: 'acc-1',
    amount: 420.00,
    kind: TransactionKind.expense,
    category: 'food',
    date: DateTime.utc(2026, 9, 6, 15, 20),
    note: 'Закупка на неделю, Kaufland',
  ),
  MockTransaction(
    id: 'tx-07',
    accountId: 'acc-1',
    amount: 480.00,
    kind: TransactionKind.expense,
    category: 'utilities',
    date: DateTime.utc(2026, 9, 7, 12, 5),
    note: 'Свет, вода, интернет',
  ),
  MockTransaction(
    id: 'tx-08',
    accountId: 'acc-1',
    amount: 140.00,
    kind: TransactionKind.expense,
    category: 'transport',
    date: DateTime.utc(2026, 9, 8, 21, 50),
    note: 'Такси домой',
  ),
  MockTransaction(
    id: 'tx-09',
    accountId: 'acc-2',
    amount: 85.00,
    kind: TransactionKind.expense,
    category: 'food',
    date: DateTime.utc(2026, 9, 9, 11, 30),
    note: 'Обед в столовой',
  ),
  MockTransaction(
    id: 'tx-10',
    accountId: 'acc-2',
    amount: 180.00,
    kind: TransactionKind.expense,
    category: 'entertainment',
    date: DateTime.utc(2026, 9, 10, 19),
    note: 'Кино с друзьями',
  ),
  MockTransaction(
    id: 'tx-11',
    accountId: 'acc-2',
    amount: 120.00,
    kind: TransactionKind.expense,
    category: 'health',
    date: DateTime.utc(2026, 9, 11, 13, 25),
    note: 'Аптека',
  ),
  MockTransaction(
    id: 'tx-12',
    accountId: 'acc-1',
    amount: 300.00,
    kind: TransactionKind.expense,
    category: 'transport',
    date: DateTime.utc(2026, 9, 12, 8, 45),
    note: 'Бензин',
  ),
  MockTransaction(
    id: 'tx-13',
    accountId: 'acc-1',
    amount: 312.40,
    kind: TransactionKind.expense,
    category: 'food',
    date: DateTime.utc(2026, 9, 13, 18, 10),
    note: 'Продукты, Nr.1',
  ),
  MockTransaction(
    id: 'tx-14',
    accountId: 'acc-1',
    amount: 420.00,
    kind: TransactionKind.expense,
    category: 'shopping',
    date: DateTime.utc(2026, 9, 14, 16),
    note: 'Кроссовки',
  ),
  MockTransaction(
    id: 'tx-15',
    accountId: 'acc-1',
    amount: 350.00,
    kind: TransactionKind.expense,
    category: 'education',
    date: DateTime.utc(2026, 9, 15, 14, 30),
    note: 'Курс английского',
  ),
  MockTransaction(
    id: 'tx-16',
    accountId: 'acc-2',
    amount: 90.00,
    kind: TransactionKind.expense,
    category: 'other',
    date: DateTime.utc(2026, 9, 16, 20, 15),
    note: 'Подарочная открытка и цветы',
  ),
  MockTransaction(
    id: 'tx-17',
    accountId: 'acc-2',
    amount: 132.70,
    kind: TransactionKind.expense,
    category: 'food',
    date: DateTime.utc(2026, 9, 17, 9, 50),
    note: 'Кофе и выпечка',
  ),
  MockTransaction(
    id: 'tx-18',
    accountId: 'acc-1',
    amount: 1200.00,
    kind: TransactionKind.income,
    category: 'freelance',
    date: DateTime.utc(2026, 9, 18, 11),
    note: 'Вёрстка лендинга',
  ),

  // ---------- August 2026 ----------
  MockTransaction(
    id: 'tx-19',
    accountId: 'acc-1',
    amount: 1600.00,
    kind: TransactionKind.income,
    category: 'scholarship',
    date: DateTime.utc(2026, 8, 1, 8, 30),
    note: 'Стипендия за август',
  ),
  MockTransaction(
    id: 'tx-20',
    accountId: 'acc-1',
    amount: 380.50,
    kind: TransactionKind.expense,
    category: 'food',
    date: DateTime.utc(2026, 8, 3, 17),
    note: 'Продукты, Kaufland',
  ),
  MockTransaction(
    id: 'tx-21',
    accountId: 'acc-1',
    amount: 6200.00,
    kind: TransactionKind.income,
    category: 'salary',
    date: DateTime.utc(2026, 8, 5, 9),
    note: 'Зарплата за июль',
  ),
  MockTransaction(
    id: 'tx-22',
    accountId: 'acc-1',
    amount: 1500.00,
    kind: TransactionKind.expense,
    category: 'housing',
    date: DateTime.utc(2026, 8, 7, 10),
    note: 'Аренда квартиры',
  ),
  MockTransaction(
    id: 'tx-23',
    accountId: 'acc-2',
    amount: 200.00,
    kind: TransactionKind.expense,
    category: 'transport',
    date: DateTime.utc(2026, 8, 10, 7, 20),
    note: 'Проездной на троллейбус',
  ),
  MockTransaction(
    id: 'tx-24',
    accountId: 'acc-2',
    amount: 260.00,
    kind: TransactionKind.expense,
    category: 'entertainment',
    date: DateTime.utc(2026, 8, 14, 20, 30),
    note: 'Концерт в парке',
  ),
  MockTransaction(
    id: 'tx-25',
    accountId: 'acc-1',
    amount: 890.00,
    kind: TransactionKind.expense,
    category: 'shopping',
    date: DateTime.utc(2026, 8, 18, 15, 45),
    note: 'Осенняя куртка',
  ),
  MockTransaction(
    id: 'tx-26',
    accountId: 'acc-3',
    amount: 100.00,
    kind: TransactionKind.income,
    category: 'gift',
    date: DateTime.utc(2026, 8, 20, 12),
    note: 'Подарок на день рождения',
  ),
  MockTransaction(
    id: 'tx-27',
    accountId: 'acc-1',
    amount: 460.00,
    kind: TransactionKind.expense,
    category: 'utilities',
    date: DateTime.utc(2026, 8, 28, 11, 10),
    note: 'Свет, вода, интернет',
  ),
];

/// Five budgets for September 2026: `food` lands in the warning band and
/// `transport` is over the limit, so both thresholds are visible on screen.
const List<MockBudget> mockBudgets = [
  MockBudget(
    id: 'bud-1',
    category: 'food',
    limitAmount: 1300.00,
    month: '2026-09',
  ),
  MockBudget(
    id: 'bud-2',
    category: 'transport',
    limitAmount: 600.00,
    month: '2026-09',
  ),
  MockBudget(
    id: 'bud-3',
    category: 'entertainment',
    limitAmount: 500.00,
    month: '2026-09',
  ),
  MockBudget(
    id: 'bud-4',
    category: 'shopping',
    limitAmount: 800.00,
    month: '2026-09',
  ),
  MockBudget(
    id: 'bud-5',
    category: 'health',
    limitAmount: 400.00,
    month: '2026-09',
  ),
];

// ---------------------------------------------------------------------------
// Derived numbers.
//
// These are plain summations over the constant lists above, kept here so that
// the screens never recompute anything themselves and the displayed totals can
// never drift apart from the transactions they came from.
// ---------------------------------------------------------------------------

MockAccount mockAccountById(String id) =>
    mockAccounts.firstWhere((account) => account.id == id);

bool _isInMonth(DateTime date, DateTime month) {
  final local = date.toLocal();
  return local.year == month.year && local.month == month.month;
}

/// Transactions of the given month, newest first.
List<MockTransaction> mockTransactionsOfMonth(DateTime month) {
  final result =
      mockTransactions
          .where((transaction) => _isInMonth(transaction.date, month))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
  return result;
}

/// All transactions, newest first.
List<MockTransaction> mockTransactionsSorted() {
  return [...mockTransactions]..sort((a, b) => b.date.compareTo(a.date));
}

double mockTotalIncome(DateTime month) {
  return mockTransactionsOfMonth(month)
      .where((transaction) => transaction.isIncome)
      .fold(0, (sum, transaction) => sum + transaction.amount);
}

double mockTotalExpense(DateTime month) {
  return mockTransactionsOfMonth(month)
      .where((transaction) => !transaction.isIncome)
      .fold(0, (sum, transaction) => sum + transaction.amount);
}

/// Expense structure of the month, largest share first.
List<CategorySlice> mockCategoryBreakdown(DateTime month) {
  final totals = <String, double>{};
  for (final transaction in mockTransactionsOfMonth(month)) {
    if (transaction.isIncome) {
      continue;
    }
    totals[transaction.category] =
        (totals[transaction.category] ?? 0) + transaction.amount;
  }

  final total = totals.values.fold<double>(0, (sum, amount) => sum + amount);
  final slices =
      totals.entries
          .map(
            (entry) => CategorySlice(
              category: entry.key,
              amount: entry.value,
              share: total == 0 ? 0 : entry.value / total,
            ),
          )
          .toList()
        ..sort((a, b) => b.amount.compareTo(a.amount));
  return slices;
}

/// Spent amount per category for the month.
double mockSpentInCategory(String category, DateTime month) {
  return mockTransactionsOfMonth(month)
      .where(
        (transaction) =>
            !transaction.isIncome && transaction.category == category,
      )
      .fold(0, (sum, transaction) => sum + transaction.amount);
}

/// Budgets of the month with their spending filled in, most used first.
List<BudgetProgress> mockBudgetProgress(DateTime month) {
  final key =
      '${month.year.toString().padLeft(4, '0')}-'
      '${month.month.toString().padLeft(2, '0')}';
  final result =
      mockBudgets
          .where((budget) => budget.month == key)
          .map(
            (budget) => BudgetProgress(
              budget: budget,
              spentAmount: mockSpentInCategory(budget.category, month),
            ),
          )
          .toList()
        ..sort((a, b) => b.progress.compareTo(a.progress));
  return result;
}
