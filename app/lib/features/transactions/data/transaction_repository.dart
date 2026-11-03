import '../../../core/utils/category_catalog.dart';
import '../domain/transaction.dart';

/// Access to the user's operations — `/transactions` in the API contract.
///
/// On L4 the whole list is loaded at once; the server-side filters and
/// pagination of the contract arrive with the REST implementation on L5.
/// Every method may throw a `RepositoryException`.
abstract interface class TransactionRepository {
  /// `GET /transactions`, newest first.
  Future<List<Transaction>> fetchAll();

  /// `POST /transactions`. Throws `NotFoundException` for an unknown
  /// account, `ValidationException` for an amount or category the data
  /// model does not allow.
  Future<Transaction> create({
    required String accountId,
    required double amount,
    required TransactionKind kind,
    required String category,
    required DateTime date,
    String? note,
  });

  /// `PUT /transactions/{id}`.
  Future<Transaction> update(Transaction transaction);

  /// `DELETE /transactions/{id}`.
  Future<void> delete(String id);
}
