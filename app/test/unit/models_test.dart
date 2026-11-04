import 'package:flutter_test/flutter_test.dart';
import 'package:walletmate/core/data/mock/mock_seed.dart';
import 'package:walletmate/core/utils/category_catalog.dart';
import 'package:walletmate/core/utils/formatters.dart';
import 'package:walletmate/features/accounts/domain/account.dart';
import 'package:walletmate/features/budgets/domain/budget.dart';
import 'package:walletmate/features/profile/domain/user_profile.dart';
import 'package:walletmate/features/transactions/domain/transaction.dart';

import '../helpers/test_app.dart';

void main() {
  group('JSON', () {
    test('a transaction reads the API shape', () {
      final transaction = Transaction.fromJson({
        'id': '7a1c',
        'accountId': '1b8f',
        'amount': 249.90,
        'type': 'expense',
        'category': 'food',
        'date': '2026-09-14T18:25:00Z',
        'note': null,
      });

      expect(transaction.kind, TransactionKind.expense);
      expect(transaction.date, DateTime.utc(2026, 9, 14, 18, 25));
      expect(transaction.note, isNull);
      expect(transaction.signedAmount, -249.90);
    });

    test('models survive a round trip', () {
      for (final transaction in testSeed.transactions) {
        expect(Transaction.fromJson(transaction.toJson()), transaction);
      }
      for (final account in testSeed.accounts) {
        expect(Account.fromJson(account.toJson()), account);
      }
      for (final budget in testSeed.budgets) {
        expect(Budget.fromJson(budget.toJson()), budget);
      }
      expect(UserProfile.fromJson(testSeed.profile.toJson()), testSeed.profile);
    });

    test('an account from the API without a kind is a card', () {
      final account = Account.fromJson({
        'id': '1b8f',
        'name': 'Карта Maib',
        'currency': 'MDL',
      });
      expect(account.kind, AccountKind.card);
      expect(account.openingBalance, 0);
    });
  });

  test('copyWith can clear a note', () {
    final transaction = testSeed.transactions.first;
    expect(transaction.note, isNotNull);
    expect(transaction.copyWith(note: () => null).note, isNull);
    expect(transaction.copyWith(amount: 5).note, transaction.note);
  });

  test('initials take the first letters of two words', () {
    expect(testSeed.profile.initials, 'IR');
    expect(testSeed.profile.copyWith(displayName: '  ana  ').initials, 'A');
  });

  group('demo data', () {
    test('on 18 September: 18 operations this month, 9 the month before', () {
      final byMonth = <String, int>{};
      for (final transaction in testSeed.transactions) {
        final month = Formatters.monthKey(transaction.date.toLocal());
        byMonth[month] = (byMonth[month] ?? 0) + 1;
      }
      expect(byMonth, {'2026-09': 18, '2026-08': 9});
      expect(testSeed.budgets.every((b) => b.month == '2026-09'), isTrue);
    });

    test('early in a month nothing is dated after today', () {
      final today = DateTime(2026, 10, 5);
      final seed = MockSeed.relativeTo(today);
      final endOfToday = DateTime(2026, 10, 6);

      expect(
        seed.transactions.every((t) => t.date.toLocal().isBefore(endOfToday)),
        isTrue,
      );
      final october = seed.transactions
          .where((t) => Formatters.monthKey(t.date.toLocal()) == '2026-10')
          .map((t) => t.id);
      expect(october, ['tx-01', 'tx-02', 'tx-03', 'tx-04', 'tx-05']);
      expect(seed.budgets.first.month, '2026-10');
    });

    test('ids are unique and categories match the operation type', () {
      final ids = testSeed.transactions.map((t) => t.id).toSet();
      expect(ids, hasLength(testSeed.transactions.length));
      for (final transaction in testSeed.transactions) {
        final keys = CategoryCatalog.forKind(transaction.kind)
            .map((c) => c.key);
        expect(keys, contains(transaction.category));
      }
    });
  });
}
