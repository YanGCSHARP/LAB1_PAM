import '../../../core/data/mock/mock_backend.dart';
import '../../../core/data/repository_exception.dart';
import '../../../core/utils/category_catalog.dart';
import '../../../core/utils/money.dart';
import '../domain/transaction.dart';
import 'transaction_repository.dart';

/// [TransactionRepository] over the in-memory [MockBackend].
///
/// Repeats the server-side checks of the data model — an existing account,
/// a positive amount, a category of the right direction — so a bug in a form
/// surfaces as an error now rather than as a 400 on L5.
class MockTransactionRepository implements TransactionRepository {
  MockTransactionRepository(this._backend);

  final MockBackend _backend;

  @override
  Future<List<Transaction>> fetchAll() {
    return _backend.request(
      () =>
          _backend.transactions.values.toList()
            ..sort((a, b) => b.date.compareTo(a.date)),
    );
  }

  @override
  Future<Transaction> create({
    required String accountId,
    required double amount,
    required TransactionKind kind,
    required String category,
    required DateTime date,
    String? note,
  }) {
    return _backend.request(() {
      final transaction = _normalize(
        Transaction(
          id: _backend.newId('tx'),
          accountId: accountId,
          amount: amount,
          kind: kind,
          category: category,
          date: date,
          note: note,
        ),
      );
      _backend.transactions[transaction.id] = transaction;
      return transaction;
    });
  }

  @override
  Future<Transaction> update(Transaction transaction) {
    return _backend.request(() {
      if (!_backend.transactions.containsKey(transaction.id)) {
        throw const NotFoundException('Операция не найдена');
      }
      final updated = _normalize(transaction);
      _backend.transactions[updated.id] = updated;
      return updated;
    });
  }

  @override
  Future<void> delete(String id) {
    return _backend.request(() {
      if (_backend.transactions.remove(id) == null) {
        throw const NotFoundException('Операция не найдена');
      }
    });
  }

  /// Validates [transaction] and brings it to the stored shape: amount
  /// rounded to cents, date in UTC, an empty note as `null`.
  Transaction _normalize(Transaction transaction) {
    if (!_backend.accounts.containsKey(transaction.accountId)) {
      throw const NotFoundException('Счёт не найден');
    }
    if (Money.toCents(transaction.amount) <= 0) {
      throw const ValidationException('Сумма должна быть больше нуля');
    }
    final categoryExists = CategoryCatalog.forKind(transaction.kind)
        .any((category) => category.key == transaction.category);
    if (!categoryExists) {
      throw const ValidationException('Категория не подходит к типу операции');
    }
    final note = transaction.note?.trim();
    return transaction.copyWith(
      amount: Money.round(transaction.amount),
      date: transaction.date.toUtc(),
      note: () => note == null || note.isEmpty ? null : note,
    );
  }
}
