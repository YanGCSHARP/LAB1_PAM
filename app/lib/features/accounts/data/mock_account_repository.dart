import '../../../core/data/mock/mock_backend.dart';
import '../../../core/data/repository_exception.dart';
import '../domain/account.dart';
import 'account_repository.dart';

/// [AccountRepository] over the in-memory [MockBackend], with the server's
/// rules: names are unique per user (case-insensitive), deleting an account
/// cascades to its transactions.
class MockAccountRepository implements AccountRepository {
  MockAccountRepository(this._backend);

  final MockBackend _backend;

  @override
  Future<List<Account>> fetchAll() {
    return _backend.request(() => _backend.accounts.values.toList());
  }

  @override
  Future<Account> create({
    required String name,
    required String currency,
    required AccountKind kind,
    double openingBalance = 0,
  }) {
    return _backend.request(() {
      _checkNameIsFree(name);
      final account = Account(
        id: _backend.newId('acc'),
        name: name.trim(),
        currency: currency,
        kind: kind,
        openingBalance: openingBalance,
      );
      _backend.accounts[account.id] = account;
      return account;
    });
  }

  @override
  Future<Account> update(Account account) {
    return _backend.request(() {
      if (!_backend.accounts.containsKey(account.id)) {
        throw const NotFoundException('Счёт не найден');
      }
      _checkNameIsFree(account.name, exceptId: account.id);
      final updated = account.copyWith(name: account.name.trim());
      _backend.accounts[account.id] = updated;
      return updated;
    });
  }

  @override
  Future<void> delete(String id) {
    return _backend.request(() {
      if (_backend.accounts.remove(id) == null) {
        throw const NotFoundException('Счёт не найден');
      }
      // ON DELETE CASCADE from the data model.
      _backend.transactions.removeWhere(
        (_, transaction) => transaction.accountId == id,
      );
    });
  }

  void _checkNameIsFree(String name, {String? exceptId}) {
    final normalized = name.trim().toLowerCase();
    final taken = _backend.accounts.values.any(
      (account) =>
          account.id != exceptId &&
          account.name.trim().toLowerCase() == normalized,
    );
    if (taken) {
      throw const ConflictException('Счёт с таким названием уже есть');
    }
  }
}
