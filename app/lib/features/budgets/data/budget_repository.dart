import '../domain/budget.dart';

/// Access to the user's monthly budgets — `/budgets` in the API contract.
///
/// The repository returns bare budgets; the spent amount and progress are
/// computed on the client from the transactions (the server's `/budgets`
/// aggregate takes over on L5). Every method may throw a
/// `RepositoryException`.
abstract interface class BudgetRepository {
  /// `GET /budgets` for every month.
  Future<List<Budget>> fetchAll();

  /// `POST /budgets`. Throws `ConflictException` when the category already
  /// has a budget in that month.
  Future<Budget> create({
    required String category,
    required double limitAmount,
    required String month,
  });

  /// `PUT /budgets/{id}`.
  Future<Budget> update(Budget budget);

  /// `DELETE /budgets/{id}`. Operations are not touched.
  Future<void> delete(String id);
}
