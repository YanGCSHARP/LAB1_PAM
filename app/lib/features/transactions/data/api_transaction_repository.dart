import '../../../core/network/api_client.dart';
import '../../../core/utils/category_catalog.dart';
import '../../../core/utils/money.dart';
import '../domain/transaction.dart';
import 'transaction_repository.dart';

/// [TransactionRepository] over `/transactions` of the backend.
///
/// The server filters and paginates; the app needs every operation to derive
/// balances, the dashboard and budget progress, so [fetchAll] walks the pages
/// with the largest page size the template allows.
class ApiTransactionRepository implements TransactionRepository {
  ApiTransactionRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<Transaction>> fetchAll() async {
    final items = await _api.getAll('/transactions');
    return items.map(Transaction.fromJson).toList();
  }

  @override
  Future<Transaction> create({
    required String accountId,
    required double amount,
    required TransactionKind kind,
    required String category,
    required DateTime date,
    String? note,
  }) async {
    final body = await _api.post(
      '/transactions',
      _body(accountId, amount, kind, category, date, note),
    );
    return Transaction.fromJson(body);
  }

  @override
  Future<Transaction> update(Transaction transaction) async {
    final body = await _api.put(
      '/transactions/${transaction.id}',
      _body(
        transaction.accountId,
        transaction.amount,
        transaction.kind,
        transaction.category,
        transaction.date,
        transaction.note,
      ),
    );
    return Transaction.fromJson(body);
  }

  @override
  Future<void> delete(String id) => _api.delete('/transactions/$id');

  static Json _body(
    String accountId,
    double amount,
    TransactionKind kind,
    String category,
    DateTime date,
    String? note,
  ) => {
    // Ids are integers on the server and strings in the app.
    'accountId': int.tryParse(accountId) ?? accountId,
    'amount': Money.round(amount),
    'type': kind.name,
    'category': category,
    'date': date.toUtc().toIso8601String(),
    'note': note,
  };
}
