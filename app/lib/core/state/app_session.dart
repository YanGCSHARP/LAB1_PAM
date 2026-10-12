import 'package:flutter/material.dart';

/// Whether someone is signed in.
///
/// The router listens to it: signing in or out re-runs the redirect, which
/// moves the user between the auth screens and the app. At this stage the flag
/// lives in memory only — on L5 it is backed by a JWT in secure storage, and
/// nothing outside this class has to change.
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

/// Theme picked on the profile screen: system, light or dark.
///
/// A plain [ValueNotifier] until the state layer (L4) takes it over.
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController([super.value = ThemeMode.system]);
}
