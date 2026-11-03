import '../domain/account.dart';

/// Access to the user's accounts — `/accounts` in the API contract.
///
/// Screens never see an implementation: on L4 it is [MockAccountRepository],
/// on L5 a REST client takes its place behind this same interface.
/// Every method may throw a `RepositoryException`.
abstract interface class AccountRepository {
  /// `GET /accounts`, in creation order.
  Future<List<Account>> fetchAll();

  /// `POST /accounts`. Throws `ConflictException` when the name is taken.
  Future<Account> create({
    required String name,
    required String currency,
    required AccountKind kind,
    double openingBalance = 0,
  });

  /// `PUT /accounts/{id}`. Throws `NotFoundException`, `ConflictException`.
  Future<Account> update(Account account);

  /// `DELETE /accounts/{id}` — removes the account's transactions as well.
  Future<void> delete(String id);
}
