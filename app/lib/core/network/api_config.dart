import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `--dart-define=USE_MOCKS=true` runs the app on the in-memory mock backend
/// of L4, without a server — for demos away from the backend and for tests.
const bool useMocksByDefault = bool.fromEnvironment('USE_MOCKS');

/// `--dart-define=API_URL=http://192.168.1.10:8080` points the app at
/// a server elsewhere, e.g. the computer a physical phone talks to.
const String _apiUrlOverride = String.fromEnvironment('API_URL');

/// Whether the repositories talk to the mock backend instead of the server.
/// Tests override it with `true`.
final useMockBackendProvider = Provider<bool>((ref) => useMocksByDefault);

/// Root of the backend.
///
/// The Android emulator reaches the host computer at `10.0.2.2`; web,
/// desktop and the iOS simulator share the host's `localhost`.
final apiBaseUrlProvider = Provider<String>((ref) {
  if (_apiUrlOverride.isNotEmpty) {
    return _apiUrlOverride;
  }
  final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  return isAndroid ? 'http://10.0.2.2:8080' : 'http://localhost:8080';
});
