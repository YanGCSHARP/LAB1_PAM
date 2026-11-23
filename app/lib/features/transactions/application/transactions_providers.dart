import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/cache/cached_repositories.dart';
import '../../../core/data/cache/data_cache.dart';
import '../../../core/data/mock/mock_providers.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/utils/category_catalog.dart';
import '../../accounts/application/accounts_providers.dart';
import '../../accounts/domain/account.dart';
import '../data/api_transaction_repository.dart';
import '../data/mock_transaction_repository.dart';
import '../data/transaction_repository.dart';
import '../domain/transaction.dart';

/// The only place that decides which [TransactionRepository] the app uses: the
/// backend behind the offline cache, or the in-memory mock with `USE_MOCKS`
/// and in tests.
final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => ref.watch(useMockBackendProvider)
      ? MockTransactionRepository(ref.watch(mockBackendProvider))
      : CachedTransactionRepository(
          ApiTransactionRepository(ref.watch(apiClientProvider)),
          ref.watch(dataCacheProvider),
          ({required offline}) =>
              ref.read(offlineProvider.notifier).set(offline: offline),
        ),
);

/// Every operation of the user, newest first.
///
/// Balances, the dashboard and budget progress are all derived from this
/// list, so one added operation updates every screen at once.
final transactionsProvider =
    AsyncNotifierProvider<TransactionsNotifier, List<Transaction>>(
      TransactionsNotifier.new,
    );

class TransactionsNotifier extends AsyncNotifier<List<Transaction>> {
  TransactionRepository get _repository =>
      ref.read(transactionRepositoryProvider);

  @override
  Future<List<Transaction>> build() {
    return ref.watch(transactionRepositoryProvider).fetchAll();
  }

  Future<Transaction> add({
    required String accountId,
    required double amount,
    required TransactionKind kind,
    required String category,
    required DateTime date,
    String? note,
  }) async {
    final transaction = await _repository.create(
      accountId: accountId,
      amount: amount,
      kind: kind,
      category: category,
      date: date,
      note: note,
    );
    _change((transactions) => [...transactions, transaction]);
    return transaction;
  }

  Future<Transaction> save(Transaction transaction) async {
    final updated = await _repository.update(transaction);
    _change(
      (transactions) => [
        for (final item in transactions) item.id == updated.id ? updated : item,
      ],
    );
    return updated;
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    _change(
      (transactions) => [
        for (final item in transactions)
          if (item.id != id) item,
      ],
    );
  }

  /// Applies a confirmed change, keeping the list newest first; reloads
  /// instead when the list has not loaded yet.
  void _change(
    List<Transaction> Function(List<Transaction> transactions) change,
  ) {
    final current = state.value;
    if (current == null) {
      ref.invalidateSelf();
      return;
    }
    state = AsyncData(
      change(current)..sort((a, b) => b.date.compareTo(a.date)),
    );
  }
}

/// The operations list together with the accounts it refers to, by id.
typedef TransactionListData = ({
  List<Transaction> transactions,
  Map<String, Account> accounts,
});

final transactionListProvider = FutureProvider<TransactionListData>((
  ref,
) async {
  final [
    transactions as List<Transaction>,
    accounts as List<Account>,
  ] = await Future.wait([
    ref.watch(transactionsProvider.future),
    ref.watch(accountsProvider.future),
  ]);
  return (
    transactions: transactions,
    accounts: {for (final account in accounts) account.id: account},
  );
});

/// One operation and its account; the account is `null` if it was deleted.
typedef TransactionDetails = ({Transaction transaction, Account? account});

/// Details of operation [id], or `null` when there is no such operation.
final transactionDetailsProvider = FutureProvider.autoDispose
    .family<TransactionDetails?, String>((ref, id) async {
      final [
        transactions as List<Transaction>,
        accounts as List<Account>,
      ] = await Future.wait([
        ref.watch(transactionsProvider.future),
        ref.watch(accountsProvider.future),
      ]);
      final transaction = transactions
          .where((item) => item.id == id)
          .firstOrNull;
      if (transaction == null) {
        return null;
      }
      final account = accounts
          .where((item) => item.id == transaction.accountId)
          .firstOrNull;
      return (transaction: transaction, account: account);
    });

/// What the operation form needs: the operation being edited (`null` for a
/// new one) and the accounts to choose from.
typedef TransactionFormData = ({
  Transaction? transaction,
  List<Account> accounts,
});

/// Form data for operation [id], or for a new operation when [id] is `null`.
/// Resolves to `null` when [id] matches no operation.
final transactionFormDataProvider = FutureProvider.autoDispose
    .family<TransactionFormData?, String?>((ref, id) async {
      if (id == null) {
        return (
          transaction: null,
          accounts: await ref.watch(accountsProvider.future),
        );
      }
      final [
        accounts as List<Account>,
        transactions as List<Transaction>,
      ] = await Future.wait([
        ref.watch(accountsProvider.future),
        ref.watch(transactionsProvider.future),
      ]);
      final transaction = transactions
          .where((item) => item.id == id)
          .firstOrNull;
      return transaction == null
          ? null
          : (transaction: transaction, accounts: accounts);
    });
