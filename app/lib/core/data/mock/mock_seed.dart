import '../../../features/accounts/domain/account.dart';
import '../../../features/budgets/domain/budget.dart';
import '../../../features/profile/domain/user_profile.dart';
import '../../../features/transactions/domain/transaction.dart';
import '../../utils/category_catalog.dart';
import '../../utils/formatters.dart';

/// Initial contents of the mock backend.
///
/// Operations are laid out relative to "today": a full previous month and the
/// current month up to today. The dashboard therefore always opens on a month
/// with data, whenever the app is launched. Entries of the current month that
/// would fall after today are left out, so nothing is ever dated in the
/// future. With today = 18 September 2026 (the date the tests pin) the data is
/// 18 operations in September and 9 in August.
class MockSeed {
  const MockSeed({
    required this.profile,
    required this.accounts,
    required this.transactions,
    required this.budgets,
  });

  factory MockSeed.relativeTo(DateTime today) {
    final month = DateTime(today.year, today.month);
    final previous = DateTime(today.year, today.month - 1);

    Transaction build(_Entry entry, DateTime base) => Transaction(
      id: entry.id,
      accountId: entry.accountId,
      amount: entry.amount,
      kind: entry.kind,
      category: entry.category,
      // Wall-clock time in the user's zone, stored in UTC like the API does.
      date: DateTime(
        base.year,
        base.month,
        entry.day,
        entry.hour,
        entry.minute,
      ).toUtc(),
      note: entry.note,
    );

    return MockSeed(
      profile: const UserProfile(
        id: 'user-1',
        email: 'ion.rusu@student.utm.md',
        displayName: 'Ion Rusu',
        defaultCurrency: 'MDL',
      ),
      accounts: const [
        Account(
          id: 'acc-1',
          name: 'Карта Maib',
          currency: 'MDL',
          openingBalance: 1250,
        ),
        Account(
          id: 'acc-2',
          name: 'Наличные',
          currency: 'MDL',
          kind: AccountKind.cash,
          openingBalance: 1500,
        ),
        Account(
          id: 'acc-3',
          name: 'Сбережения',
          currency: 'EUR',
          kind: AccountKind.savings,
          openingBalance: 250,
        ),
      ],
      transactions: [
        for (final entry in _currentMonth)
          if (entry.day <= today.day) build(entry, month),
        for (final entry in _previousMonth) build(entry, previous),
      ],
      budgets: [
        for (final (index, (category, limit)) in _budgets.indexed)
          Budget(
            id: 'bud-${index + 1}',
            category: category,
            limitAmount: limit,
            month: Formatters.monthKey(month),
          ),
      ],
    );
  }

  final UserProfile profile;
  final List<Account> accounts;
  final List<Transaction> transactions;
  final List<Budget> budgets;
}

/// A seed operation: day of month and wall-clock time instead of a date.
class _Entry {
  const _Entry(
    this.id,
    this.accountId,
    this.amount,
    this.kind,
    this.category,
    this.day,
    this.hour,
    this.minute,
    this.note,
  );

  final String id;
  final String accountId;
  final double amount;
  final TransactionKind kind;
  final String category;
  final int day;
  final int hour;
  final int minute;
  final String note;
}

const _in = TransactionKind.income;
const _out = TransactionKind.expense;

const List<_Entry> _currentMonth = [
  _Entry('tx-01', 'acc-1', 1600, _in, 'scholarship', 1, 8, 30, 'Стипендия УТМ'),
  _Entry(
    'tx-02',
    'acc-1',
    249.90,
    _out,
    'food',
    2,
    17,
    40,
    'Продукты, Linella',
  ),
  _Entry(
    'tx-03',
    'acc-2',
    200,
    _out,
    'transport',
    3,
    7,
    15,
    'Проездной на троллейбус',
  ),
  _Entry('tx-04', 'acc-1', 1500, _out, 'housing', 4, 10, 0, 'Аренда квартиры'),
  _Entry(
    'tx-05',
    'acc-1',
    6400,
    _in,
    'salary',
    5,
    9,
    0,
    'Зарплата за прошлый месяц',
  ),
  _Entry(
    'tx-06',
    'acc-1',
    420,
    _out,
    'food',
    6,
    15,
    20,
    'Закупка на неделю, Kaufland',
  ),
  _Entry(
    'tx-07',
    'acc-1',
    480,
    _out,
    'utilities',
    7,
    12,
    5,
    'Свет, вода, интернет',
  ),
  _Entry('tx-08', 'acc-1', 140, _out, 'transport', 8, 21, 50, 'Такси домой'),
  _Entry('tx-09', 'acc-2', 85, _out, 'food', 9, 11, 30, 'Обед в столовой'),
  _Entry(
    'tx-10',
    'acc-2',
    180,
    _out,
    'entertainment',
    10,
    19,
    0,
    'Кино с друзьями',
  ),
  _Entry('tx-11', 'acc-2', 120, _out, 'health', 11, 13, 25, 'Аптека'),
  _Entry('tx-12', 'acc-1', 300, _out, 'transport', 12, 8, 45, 'Бензин'),
  _Entry('tx-13', 'acc-1', 312.40, _out, 'food', 13, 18, 10, 'Продукты, Nr.1'),
  _Entry('tx-14', 'acc-1', 420, _out, 'shopping', 14, 16, 0, 'Кроссовки'),
  _Entry(
    'tx-15',
    'acc-1',
    350,
    _out,
    'education',
    15,
    14,
    30,
    'Курс английского',
  ),
  _Entry(
    'tx-16',
    'acc-2',
    90,
    _out,
    'other',
    16,
    20,
    15,
    'Подарочная открытка и цветы',
  ),
  _Entry('tx-17', 'acc-2', 132.70, _out, 'food', 17, 9, 50, 'Кофе и выпечка'),
  _Entry(
    'tx-18',
    'acc-1',
    1200,
    _in,
    'freelance',
    18,
    11,
    0,
    'Вёрстка лендинга',
  ),
];

const List<_Entry> _previousMonth = [
  _Entry('tx-19', 'acc-1', 1600, _in, 'scholarship', 1, 8, 30, 'Стипендия УТМ'),
  _Entry(
    'tx-20',
    'acc-1',
    380.50,
    _out,
    'food',
    3,
    17,
    0,
    'Продукты, Kaufland',
  ),
  _Entry(
    'tx-21',
    'acc-1',
    6200,
    _in,
    'salary',
    5,
    9,
    0,
    'Зарплата за позапрошлый месяц',
  ),
  _Entry('tx-22', 'acc-1', 1500, _out, 'housing', 7, 10, 0, 'Аренда квартиры'),
  _Entry(
    'tx-23',
    'acc-2',
    200,
    _out,
    'transport',
    10,
    7,
    20,
    'Проездной на троллейбус',
  ),
  _Entry(
    'tx-24',
    'acc-2',
    260,
    _out,
    'entertainment',
    14,
    20,
    30,
    'Концерт в парке',
  ),
  _Entry('tx-25', 'acc-1', 890, _out, 'shopping', 18, 15, 45, 'Осенняя куртка'),
  _Entry(
    'tx-26',
    'acc-3',
    100,
    _in,
    'gift',
    20,
    12,
    0,
    'Подарок на день рождения',
  ),
  _Entry(
    'tx-27',
    'acc-1',
    460,
    _out,
    'utilities',
    28,
    11,
    10,
    'Свет, вода, интернет',
  ),
];

/// Budgets of the current month. With the full month of data `food` lands in
/// the warning band and `transport` over the limit, so both thresholds show.
const List<(String, double)> _budgets = [
  ('food', 1300),
  ('transport', 600),
  ('entertainment', 500),
  ('shopping', 800),
  ('health', 400),
];
