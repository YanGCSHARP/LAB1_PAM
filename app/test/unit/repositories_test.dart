import 'package:flutter_test/flutter_test.dart';
import 'package:walletmate/core/data/mock/mock_backend.dart';
import 'package:walletmate/core/data/repository_exception.dart';
import 'package:walletmate/core/utils/category_catalog.dart';
import 'package:walletmate/features/accounts/data/mock_account_repository.dart';
import 'package:walletmate/features/accounts/domain/account.dart';
import 'package:walletmate/features/budgets/data/mock_budget_repository.dart';
import 'package:walletmate/features/profile/data/mock_profile_repository.dart';
import 'package:walletmate/features/transactions/data/mock_transaction_repository.dart';

import '../helpers/test_app.dart';

void main() {
  late bool offline;
  late MockBackend backend;
  late MockAccountRepository accounts;
  late MockTransactionRepository transactions;
  late MockBudgetRepository budgets;
  late MockProfileRepository profile;

  setUp(() {
    offline = false;
    backend = MockBackend(
      seed: testSeed,
      latency: Duration.zero,
      isOffline: () => offline,
    );
    accounts = MockAccountRepository(backend);
    transactions = MockTransactionRepository(backend);
    budgets = MockBudgetRepository(backend);
    profile = MockProfileRepository(backend);
  });

  group('accounts', () {
    test('a created account gets an id and is listed last', () async {
      final created = await accounts.create(
        name: '  Карта Victoriabank ',
        currency: 'EUR',
        kind: AccountKind.card,
        openingBalance: 100,
      );

      expect(created.id, isNotEmpty);
      expect(created.name, 'Карта Victoriabank');
      expect((await accounts.fetchAll()).last, created);
    });

    test('a name is unique regardless of case', () {
      expect(
        accounts.create(
          name: 'НАЛИЧНЫЕ',
          currency: 'MDL',
          kind: AccountKind.cash,
        ),
        throwsA(isA<ConflictException>()),
      );
    });

    test('an account may keep its own name when edited', () async {
      final cash = testSeed.accounts[1];
      final updated = await accounts.update(cash.copyWith(currency: 'USD'));
      expect(updated.name, cash.name);
      expect(updated.currency, 'USD');
    });

    test('deleting an account deletes its operations', () async {
      await accounts.delete('acc-2');

      final left = await transactions.fetchAll();
      expect(left.where((t) => t.accountId == 'acc-2'), isEmpty);
      expect(left.where((t) => t.accountId == 'acc-1'), isNotEmpty);
    });

    test('an unknown id is not found', () {
      expect(accounts.delete('acc-404'), throwsA(isA<NotFoundException>()));
    });
  });

  group('transactions', () {
    Future<void> createWith({
      String accountId = 'acc-1',
      double amount = 10,
      TransactionKind kind = TransactionKind.expense,
      String category = 'food',
    }) {
      return transactions.create(
        accountId: accountId,
        amount: amount,
        kind: kind,
        category: category,
        date: testToday,
      );
    }

    test('are listed newest first', () async {
      final list = await transactions.fetchAll();
      for (var i = 1; i < list.length; i++) {
        expect(list[i - 1].date.isBefore(list[i].date), isFalse);
      }
    });

    test('a created operation is stored in UTC with a trimmed note', () async {
      final created = await transactions.create(
        accountId: 'acc-1',
        amount: 99.999,
        kind: TransactionKind.expense,
        category: 'food',
        date: DateTime(2026, 9, 18, 12),
        note: '   ',
      );

      expect(created.date.isUtc, isTrue);
      expect(created.amount, 100);
      expect(created.note, isNull);
      expect(await transactions.fetchAll(), contains(created));
    });

    test('the account must exist', () {
      expect(
        createWith(accountId: 'acc-404'),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('the amount must be positive', () {
      expect(createWith(amount: 0), throwsA(isA<ValidationException>()));
    });

    test('the category must match the type', () {
      expect(
        createWith(kind: TransactionKind.income),
        throwsA(isA<ValidationException>()),
      );
    });

    test('an edit replaces the stored operation', () async {
      final original = testSeed.transactions.first;
      await transactions.update(original.copyWith(amount: 1700));

      final stored = (await transactions.fetchAll()).firstWhere(
        (t) => t.id == original.id,
      );
      expect(stored.amount, 1700);
    });

    test('a deleted operation is gone', () async {
      await transactions.delete('tx-17');
      final ids = (await transactions.fetchAll()).map((t) => t.id);
      expect(ids, isNot(contains('tx-17')));
      expect(transactions.delete('tx-17'), throwsA(isA<NotFoundException>()));
    });
  });

  group('budgets', () {
    test('one budget per category and month', () {
      expect(
        budgets.create(category: 'food', limitAmount: 500, month: '2026-09'),
        throwsA(isA<ConflictException>()),
      );
    });

    test('the same category is fine in another month', () async {
      final created = await budgets.create(
        category: 'food',
        limitAmount: 500,
        month: '2026-10',
      );
      expect(created.month, '2026-10');
    });

    test('an edit may not collide with another budget', () {
      final transport = testSeed.budgets[1];
      expect(
        budgets.update(transport.copyWith(category: 'food')),
        throwsA(isA<ConflictException>()),
      );
    });

    test('the limit must be positive', () {
      expect(
        budgets.create(category: 'other', limitAmount: 0, month: '2026-09'),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  test('the profile update keeps the id and email', () async {
    final current = await profile.fetch();
    final updated = await profile.update(
      current.copyWith(displayName: ' Ana Popa ', defaultCurrency: 'EUR'),
    );

    expect(updated.displayName, 'Ana Popa');
    expect(updated.defaultCurrency, 'EUR');
    expect(updated.email, current.email);
    expect(await profile.fetch(), updated);
  });

  test('offline, every call fails with a network error', () async {
    offline = true;

    await expectLater(accounts.fetchAll(), throwsA(isA<NetworkException>()));
    await expectLater(
      transactions.delete('tx-01'),
      throwsA(isA<NetworkException>()),
    );
    // Nothing was changed by the failed call.
    offline = false;
    expect((await transactions.fetchAll()).map((t) => t.id), contains('tx-01'));
  });

  test('errors carry a user-facing message', () {
    expect(errorMessage(const NetworkException()), contains('Нет связи'));
    expect(
      errorMessage(StateError('boom')),
      'Что-то пошло не так. Повторите попытку.',
    );
  });
}
