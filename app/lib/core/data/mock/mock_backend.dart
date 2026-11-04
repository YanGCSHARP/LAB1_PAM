import '../../../features/accounts/domain/account.dart';
import '../../../features/budgets/domain/budget.dart';
import '../../../features/profile/domain/user_profile.dart';
import '../../../features/transactions/domain/transaction.dart';
import '../repository_exception.dart';
import 'mock_seed.dart';

/// In-memory stand-in for the REST backend of L5.
///
/// It holds the tables, answers after a short delay and can pretend to be
/// unreachable, so the app meets the same loading and error paths it will meet
/// over the network. The business rules that belong to the server — unique
/// names, cascade delete — are enforced in the mock repositories built on top
/// of it, not in the screens.
///
/// State lives as long as the app runs; a restart brings the seed back.
/// Persisting it is the job of the local database on L6.
class MockBackend {
  MockBackend({
    required MockSeed seed,
    this.latency = defaultLatency,
    bool Function()? isOffline,
  }) : _isOffline = isOffline ?? _neverOffline,
       profile = seed.profile {
    for (final account in seed.accounts) {
      accounts[account.id] = account;
    }
    for (final transaction in seed.transactions) {
      transactions[transaction.id] = transaction;
    }
    for (final budget in seed.budgets) {
      budgets[budget.id] = budget;
    }
  }

  /// Long enough to see the skeletons, short enough not to annoy.
  static const Duration defaultLatency = Duration(milliseconds: 350);

  static bool _neverOffline() => false;

  final Duration latency;
  final bool Function() _isOffline;

  // Tables, keyed by id. Map literals keep insertion order.
  final Map<String, Account> accounts = {};
  final Map<String, Transaction> transactions = {};
  final Map<String, Budget> budgets = {};
  UserProfile profile;

  int _nextId = 100;

  /// A fresh id with the table's prefix: `tx-100`, `acc-101`, …
  String newId(String prefix) => '$prefix-${_nextId++}';

  /// Runs [handler] the way a request would: after [latency], failing with
  /// [NetworkException] while offline. Handlers throw other
  /// [RepositoryException]s for the server's 4xx answers.
  Future<T> request<T>(T Function() handler) async {
    await Future<void>.delayed(latency);
    if (_isOffline()) {
      throw const NetworkException();
    }
    return handler();
  }
}
