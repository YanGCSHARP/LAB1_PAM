import 'dart:convert';

import '../../../features/accounts/data/account_repository.dart';
import '../../../features/accounts/domain/account.dart';
import '../../../features/budgets/data/budget_repository.dart';
import '../../../features/budgets/domain/budget.dart';
import '../../../features/profile/data/profile_repository.dart';
import '../../../features/profile/domain/user_profile.dart';
import '../../../features/transactions/data/transaction_repository.dart';
import '../../../features/transactions/domain/transaction.dart';
import '../../utils/category_catalog.dart';
import '../repository_exception.dart';
import 'data_cache.dart';

/// Signature of [OfflineNotifier.set].
typedef OnSource = void Function({required bool offline});

/// [AccountRepository] that remembers the last server answer.
class CachedAccountRepository implements AccountRepository {
  CachedAccountRepository(this._inner, DataCache cache, OnSource onSource)
    : _list = CachedCollection(
        cache: cache,
        key: 'accounts',
        fromJson: Account.fromJson,
        toJson: (account) => account.toJson(),
        idOf: (account) => account.id,
        onSource: onSource,
      );

  final AccountRepository _inner;
  final CachedCollection<Account> _list;

  @override
  Future<List<Account>> fetchAll() => _list.fetch(_inner.fetchAll);

  @override
  Future<Account> create({
    required String name,
    required String currency,
    required AccountKind kind,
    double openingBalance = 0,
  }) async => _list.upsert(
    await _inner.create(
      name: name,
      currency: currency,
      kind: kind,
      openingBalance: openingBalance,
    ),
  );

  @override
  Future<Account> update(Account account) async =>
      _list.upsert(await _inner.update(account));

  @override
  Future<void> delete(String id) async {
    await _inner.delete(id);
    await _list.remove(id);
  }
}

/// [TransactionRepository] that remembers the last server answer.
class CachedTransactionRepository implements TransactionRepository {
  CachedTransactionRepository(this._inner, DataCache cache, OnSource onSource)
    : _list = CachedCollection(
        cache: cache,
        key: 'transactions',
        fromJson: Transaction.fromJson,
        toJson: (transaction) => transaction.toJson(),
        idOf: (transaction) => transaction.id,
        onSource: onSource,
      );

  final TransactionRepository _inner;
  final CachedCollection<Transaction> _list;

  @override
  Future<List<Transaction>> fetchAll() => _list.fetch(_inner.fetchAll);

  @override
  Future<Transaction> create({
    required String accountId,
    required double amount,
    required TransactionKind kind,
    required String category,
    required DateTime date,
    String? note,
  }) async => _list.upsert(
    await _inner.create(
      accountId: accountId,
      amount: amount,
      kind: kind,
      category: category,
      date: date,
      note: note,
    ),
  );

  @override
  Future<Transaction> update(Transaction transaction) async =>
      _list.upsert(await _inner.update(transaction));

  @override
  Future<void> delete(String id) async {
    await _inner.delete(id);
    await _list.remove(id);
  }
}

/// [BudgetRepository] that remembers the last server answer.
class CachedBudgetRepository implements BudgetRepository {
  CachedBudgetRepository(this._inner, DataCache cache, OnSource onSource)
    : _list = CachedCollection(
        cache: cache,
        key: 'budgets',
        fromJson: Budget.fromJson,
        toJson: (budget) => budget.toJson(),
        idOf: (budget) => budget.id,
        onSource: onSource,
      );

  final BudgetRepository _inner;
  final CachedCollection<Budget> _list;

  @override
  Future<List<Budget>> fetchAll() => _list.fetch(_inner.fetchAll);

  @override
  Future<Budget> create({
    required String category,
    required double limitAmount,
    required String month,
  }) async => _list.upsert(
    await _inner.create(
      category: category,
      limitAmount: limitAmount,
      month: month,
    ),
  );

  @override
  Future<Budget> update(Budget budget) async =>
      _list.upsert(await _inner.update(budget));

  @override
  Future<void> delete(String id) async {
    await _inner.delete(id);
    await _list.remove(id);
  }
}

/// [ProfileRepository] that remembers the last server answer.
class CachedProfileRepository implements ProfileRepository {
  CachedProfileRepository(this._inner, this._cache, this._onSource);

  static const String _key = 'profile';

  final ProfileRepository _inner;
  final DataCache _cache;
  final OnSource _onSource;

  @override
  Future<UserProfile> fetch() async {
    try {
      final profile = await _save(await _inner.fetch());
      _onSource(offline: false);
      return profile;
    } on NetworkException {
      final raw = await _cache.read(_key);
      if (raw == null) {
        rethrow;
      }
      _onSource(offline: true);
      return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    }
  }

  @override
  Future<UserProfile> update(UserProfile profile) async =>
      _save(await _inner.update(profile));

  @override
  Future<UserProfile> uploadAvatar({
    required List<int> bytes,
    required String filename,
    required String mimeType,
  }) async => _save(
    await _inner.uploadAvatar(
      bytes: bytes,
      filename: filename,
      mimeType: mimeType,
    ),
  );

  Future<UserProfile> _save(UserProfile profile) async {
    await _cache.write(_key, jsonEncode(profile.toJson()));
    return profile;
  }
}
