import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/mock/mock_providers.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../transactions/application/transactions_providers.dart';
import '../../transactions/domain/transaction.dart';
import '../data/account_repository.dart';
import '../data/api_account_repository.dart';
import '../data/mock_account_repository.dart';
import '../domain/account.dart';
import '../domain/balances.dart';

/// The only place that decides which [AccountRepository] the app uses: the
/// backend, or the in-memory mock with `USE_MOCKS` and in tests.
final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => ref.watch(useMockBackendProvider)
      ? MockAccountRepository(ref.watch(mockBackendProvider))
      : ApiAccountRepository(ref.watch(apiClientProvider)),
);

/// The user's accounts, loaded once and kept in sync with every change made
/// through [AccountsNotifier].
final accountsProvider = AsyncNotifierProvider<AccountsNotifier, List<Account>>(
  AccountsNotifier.new,
);

class AccountsNotifier extends AsyncNotifier<List<Account>> {
  AccountRepository get _repository => ref.read(accountRepositoryProvider);

  @override
  Future<List<Account>> build() {
    return ref.watch(accountRepositoryProvider).fetchAll();
  }

  /// Creates an account. A failure is thrown to the caller — the form shows
  /// it — and the list stays as it was.
  Future<Account> create({
    required String name,
    required String currency,
    required AccountKind kind,
    double openingBalance = 0,
  }) async {
    final account = await _repository.create(
      name: name,
      currency: currency,
      kind: kind,
      openingBalance: openingBalance,
    );
    _change((accounts) => [...accounts, account]);
    return account;
  }

  Future<Account> save(Account account) async {
    final updated = await _repository.update(account);
    _change(
      (accounts) => [
        for (final item in accounts) item.id == updated.id ? updated : item,
      ],
    );
    return updated;
  }

  /// Deletes the account. The server removes its operations too, so the
  /// operations list is reloaded.
  Future<void> delete(String id) async {
    await _repository.delete(id);
    _change(
      (accounts) => [
        for (final item in accounts)
          if (item.id != id) item,
      ],
    );
    ref.invalidate(transactionsProvider);
  }

  /// Applies a confirmed change to the loaded list, or reloads it when it
  /// has not loaded yet.
  void _change(List<Account> Function(List<Account> accounts) change) {
    final current = state.value;
    if (current == null) {
      ref.invalidateSelf();
      return;
    }
    state = AsyncData(change(current));
  }
}

/// Every account with its balance, computed from the operations.
final accountBalancesProvider = FutureProvider<List<AccountBalance>>((
  ref,
) async {
  // Both requests start at once; the first failure is reported as is.
  final [
    accounts as List<Account>,
    transactions as List<Transaction>,
  ] = await Future.wait([
    ref.watch(accountsProvider.future),
    ref.watch(transactionsProvider.future),
  ]);
  return computeBalances(accounts, transactions);
});

/// What the account form needs: the account being edited (`null` for a new
/// one), every account for the unique-name check, and how many operations
/// deleting the account would take along.
typedef AccountFormData = ({
  Account? account,
  List<Account> accounts,
  int operationCount,
});

/// Form data for account [id], or for a new account when [id] is `null`.
/// Resolves to `null` when [id] matches no account.
final accountFormDataProvider = FutureProvider.autoDispose
    .family<AccountFormData?, String?>((ref, id) async {
      if (id == null) {
        return (
          account: null,
          accounts: await ref.watch(accountsProvider.future),
          operationCount: 0,
        );
      }
      final [
        accounts as List<Account>,
        transactions as List<Transaction>,
      ] = await Future.wait([
        ref.watch(accountsProvider.future),
        ref.watch(transactionsProvider.future),
      ]);
      final account = accounts.where((item) => item.id == id).firstOrNull;
      if (account == null) {
        return null;
      }
      return (
        account: account,
        accounts: accounts,
        operationCount: transactions.where((t) => t.accountId == id).length,
      );
    });
