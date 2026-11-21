import '../../../core/network/api_client.dart';
import '../../../core/utils/money.dart';
import '../domain/budget.dart';
import 'budget_repository.dart';

/// [BudgetRepository] over `/budgets` of the backend.
///
/// The server sends `spentAmount` with each budget; progress is still
/// computed on the client from the operations, the same way as with the mock
/// backend.
class ApiBudgetRepository implements BudgetRepository {
  ApiBudgetRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<Budget>> fetchAll() async {
    final items = await _api.getAll('/budgets');
    return items.map(Budget.fromJson).toList();
  }

  @override
  Future<Budget> create({
    required String category,
    required double limitAmount,
    required String month,
  }) async {
    final body = await _api.post('/budgets', {
      'category': category,
      'limitAmount': Money.round(limitAmount),
      'month': month,
    });
    return Budget.fromJson(body);
  }

  @override
  Future<Budget> update(Budget budget) async {
    final body = await _api.put('/budgets/${budget.id}', {
      'category': budget.category,
      'limitAmount': Money.round(budget.limitAmount),
      'month': budget.month,
    });
    return Budget.fromJson(body);
  }

  @override
  Future<void> delete(String id) => _api.delete('/budgets/$id');
}
