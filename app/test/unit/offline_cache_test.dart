import 'package:flutter_test/flutter_test.dart';
import 'package:walletmate/core/data/cache/cached_repositories.dart';
import 'package:walletmate/core/data/cache/data_cache.dart';
import 'package:walletmate/core/data/repository_exception.dart';
import 'package:walletmate/features/accounts/data/account_repository.dart';
import 'package:walletmate/features/accounts/domain/account.dart';

/// A server that can be switched off.
class _Server implements AccountRepository {
  bool online = true;
  List<Account> accounts = const [
    Account(id: '1', name: 'Карта Maib', currency: 'MDL'),
  ];

  Future<T> _call<T>(T Function() body) async =>
      online ? body() : throw const NetworkException();

  @override
  Future<List<Account>> fetchAll() => _call(() => accounts);

  @override
  Future<Account> create({
    required String name,
    required String currency,
    required AccountKind kind,
    double openingBalance = 0,
  }) => _call(() => Account(id: '2', name: name, currency: currency));

  @override
  Future<Account> update(Account account) => _call(() => account);

  @override
  Future<void> delete(String id) => _call(() {});
}

void main() {
  late _Server server;
  late bool fromCopy;
  late CachedAccountRepository repository;

  setUp(() {
    server = _Server();
    fromCopy = false;
    repository = CachedAccountRepository(
      server,
      MemoryDataCache(),
      ({required bool offline}) => fromCopy = offline,
    );
  });

  test('without the server the last loaded copy is shown', () async {
    await repository.fetchAll();
    await repository.create(
      name: 'Наличные',
      currency: 'MDL',
      kind: AccountKind.cash,
    );

    server.online = false;
    final saved = await repository.fetchAll();

    expect(saved.map((a) => a.name), ['Карта Maib', 'Наличные']);
    expect(fromCopy, isTrue);
  });

  test('nothing saved yet: the network error stays visible', () async {
    server.online = false;
    expect(repository.fetchAll, throwsA(isA<NetworkException>()));
  });

  test('writes still need the server and leave the copy as it was', () async {
    await repository.fetchAll();
    server.online = false;

    await expectLater(repository.delete('1'), throwsA(isA<NetworkException>()));
    expect((await repository.fetchAll()).single.id, '1');
  });
}
