import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_config.dart';

/// Where the JWT survives an app restart.
abstract interface class TokenStorage {
  Future<String?> read();

  Future<void> write(String token);

  Future<void> clear();
}

/// The platform keystore: Keychain on iOS, Keystore-backed encryption on
/// Android, encrypted local storage on the web. Never plain preferences —
/// the token opens the user's finances.
class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _key = 'walletmate.jwt';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);

  @override
  Future<void> clear() => _storage.delete(key: _key);
}

/// Keeps the token in memory only — the mock backend and tests.
class MemoryTokenStorage implements TokenStorage {
  String? _token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> write(String token) async => _token = token;

  @override
  Future<void> clear() async => _token = null;
}

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => ref.watch(useMockBackendProvider)
      ? MemoryTokenStorage()
      : SecureTokenStorage(),
);
