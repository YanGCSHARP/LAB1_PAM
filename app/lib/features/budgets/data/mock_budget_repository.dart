import '../../../core/data/mock/mock_backend.dart';
import '../../../core/data/repository_exception.dart';
import '../../../core/utils/money.dart';
import '../domain/budget.dart';
import 'budget_repository.dart';

/// [BudgetRepository] over the in-memory [MockBackend], with the unique
/// index `(userId, category, month)` of the data model.
class MockBudgetRepository implements BudgetRepository {
  MockBudgetRepository(this._backend);

  final MockBackend _backend;

  @override
  Future<List<Budget>> fetchAll() {
    return _backend.request(() => _backend.budgets.values.toList());
  }

  @override
  Future<Budget> create({
    required String category,
    required double limitAmount,
    required String month,
  }) {
    return _backend.request(() {
      final budget = _normalize(
        Budget(
          id: _backend.newId('bud'),
          category: category,
          limitAmount: limitAmount,
          month: month,
        ),
      );
      _backend.budgets[budget.id] = budget;
      return budget;
    });
  }

  @override
  Future<Budget> update(Budget budget) {
    return _backend.request(() {
      if (!_backend.budgets.containsKey(budget.id)) {
        throw const NotFoundException('Бюджет не найден');
      }
      final updated = _normalize(budget);
      _backend.budgets[updated.id] = updated;
      return updated;
    });
  }

  @override
  Future<void> delete(String id) {
    return _backend.request(() {
      if (_backend.budgets.remove(id) == null) {
        throw const NotFoundException('Бюджет не найден');
      }
    });
  }

  Budget _normalize(Budget budget) {
    if (Money.toCents(budget.limitAmount) <= 0) {
      throw const ValidationException('Лимит должен быть больше нуля');
    }
    final duplicate = _backend.budgets.values.any(
      (other) =>
          other.id != budget.id &&
          other.category == budget.category &&
          other.month == budget.month,
    );
    if (duplicate) {
      throw const ConflictException(
        'На этот месяц бюджет по категории уже есть',
      );
    }
    return budget.copyWith(limitAmount: Money.round(budget.limitAmount));
  }
}
