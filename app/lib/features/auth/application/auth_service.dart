import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/cache/data_cache.dart';
import '../../../core/data/mock/mock_providers.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/token_storage.dart';
import '../../../core/state/app_session.dart';
import '../../accounts/application/accounts_providers.dart';
import '../../budgets/application/budgets_providers.dart';
import '../../profile/application/profile_providers.dart';
import '../../transactions/application/transactions_providers.dart';
import '../data/api_auth_repository.dart';
import '../data/auth_repository.dart';
import '../data/mock_auth_repository.dart';

/// The only place that decides which [AuthRepository] the app uses.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => ref.watch(useMockBackendProvider)
      ? MockAuthRepository(ref.watch(mockBackendProvider))
      : ApiAuthRepository(ref.watch(apiClientProvider)),
);

final authServiceProvider = Provider<AuthService>(AuthService.new);

/// Signs in, signs up, restores and ends the session.
///
/// Keeps four things in step: the token on the device ([TokenStorage]),
/// the in-memory [AuthSession] the router and the API client read, the
/// offline copy ([DataCache]) and the loaded data — the collections of one
/// user must never be shown to the next.
class AuthService {
  AuthService(this._ref);

  final Ref _ref;

  AuthRepository get _repository => _ref.read(authRepositoryProvider);
  TokenStorage get _storage => _ref.read(tokenStorageProvider);
  AuthSession get _session => _ref.read(authSessionProvider);

  Future<void> signIn({required String email, required String password}) async {
    final token = await _repository.login(email: email, password: password);
    await _start(token);
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final token = await _repository.register(
      name: name,
      email: email,
      password: password,
    );
    await _start(token);
  }

  /// Picks up the token of a previous launch, so the app opens signed in.
  /// An expired token is found out by the first request (401), which ends the
  /// session then.
  Future<void> restore() async {
    final token = await _storage.read();
    if (token != null) {
      _session.signIn(token);
    }
  }

  Future<void> signOut() async {
    await _storage.clear();
    await _ref.read(dataCacheProvider).clear();
    _end();
  }

  /// The server rejected the token mid-session.
  void expire() {
    _storage.clear();
    _ref.read(dataCacheProvider).clear();
    _end();
  }

  Future<void> _start(String token) async {
    await _storage.write(token);
    await _ref.read(dataCacheProvider).clear();
    _resetData();
    _session.signIn(token);
  }

  void _end() {
    _session.signOut();
    _ref.read(offlineProvider.notifier).set(offline: false);
    _resetData();
  }

  /// Drops the loaded collections; the next screen loads them for whoever is
  /// signed in now.
  void _resetData() {
    _ref
      ..invalidate(profileProvider)
      ..invalidate(accountsProvider)
      ..invalidate(transactionsProvider)
      ..invalidate(budgetsProvider);
  }
}
