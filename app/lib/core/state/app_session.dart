import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether someone is signed in.
///
/// The router listens to it: signing in or out re-runs the redirect, which
/// moves the user between the auth screens and the app. At this stage the flag
/// lives in memory only — on L5 it is backed by a JWT in secure storage, and
/// nothing outside this class has to change.
///
/// It stays a [ChangeNotifier] rather than a Riverpod notifier because
/// `GoRouter.refreshListenable` takes a [Listenable].
class AuthSession extends ChangeNotifier {
  AuthSession([this._signedIn = false]);

  bool _signedIn;

  bool get isSignedIn => _signedIn;

  void signIn() {
    if (_signedIn) {
      return;
    }
    _signedIn = true;
    notifyListeners();
  }

  void signOut() {
    if (!_signedIn) {
      return;
    }
    _signedIn = false;
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
