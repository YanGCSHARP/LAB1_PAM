import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Who is signed in: the JWT of the current session, if any.
///
/// The router listens to it: signing in or out re-runs the redirect, which
/// moves the user between the auth screens and the app. The token itself is
/// kept on the device by `TokenStorage`; this object only holds it in memory
/// for the API client, which adds it to every request.
///
/// It stays a [ChangeNotifier] rather than a Riverpod notifier because
/// `GoRouter.refreshListenable` takes a [Listenable].
class AuthSession extends ChangeNotifier {
  AuthSession([this._signedIn = false]);

  bool _signedIn;
  String? _token;

  bool get isSignedIn => _signedIn;

  /// `Bearer` token for the API; `null` with the mock backend and in tests
  /// that start signed in.
  String? get token => _token;

  void signIn([String? token]) {
    if (_signedIn && token == _token) {
      return;
    }
    _signedIn = true;
    _token = token;
    notifyListeners();
  }

  void signOut() {
    if (!_signedIn) {
      return;
    }
    _signedIn = false;
    _token = null;
    notifyListeners();
  }
}

final authSessionProvider = Provider<AuthSession>((ref) {
  final session = AuthSession();
  ref.onDispose(session.dispose);
  return session;
});

/// Theme picked on the profile screen: system, light or dark.
///
/// Kept in memory; it survives switching tabs but not a restart — saving it
/// on the device is part of the offline storage of L6.
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void select(ThemeMode mode) => state = mode;
}
