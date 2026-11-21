import '../../../core/network/api_client.dart';
import '../../../core/utils/money.dart';
import '../domain/account.dart';
import 'account_repository.dart';

/// [AccountRepository] over `/accounts` of the backend.
///
/// The server also sends each account's `balance`; the app keeps deriving
/// balances from the operations itself, so one rule serves the mock backend
/// and the server alike.
class ApiAccountRepository implements AccountRepository {
  ApiAccountRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<Account>> fetchAll() async {
    final items = await _api.getAll('/accounts');
    return items.map(Account.fromJson).toList();
  }

  @override
  Future<Account> create({
    required String name,
    required String currency,
    required AccountKind kind,
    double openingBalance = 0,
  }) async {
    final body = await _api.post('/accounts', {
      'name': name.trim(),
      'currency': currency,
      'kind': kind.name,
      'initialBalance': Money.round(openingBalance),
    });
    return Account.fromJson(body);
  }

  @override
  Future<Account> update(Account account) async {
    // The opening balance is set once, on creation — see the API contract.
    final body = await _api.put('/accounts/${account.id}', {
      'name': account.name.trim(),
      'currency': account.currency,
      'kind': account.kind.name,
    });
    return Account.fromJson(body);
  }

  @override
  Future<void> delete(String id) => _api.delete('/accounts/$id');
}
