import 'package:flutter/material.dart';

import '../data/repository_exception.dart';
import 'app_toast.dart';

/// Runs a save or a delete started from a screen.
///
/// Returns `true` when [action] succeeded. A [RepositoryException] — no
/// network, a name already taken — is shown as an error toast and turns into
/// `false`, so the screen stays open with everything the user typed.
Future<bool> runRepositoryAction(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
    return true;
  } on RepositoryException catch (error) {
    if (context.mounted) {
      showAppToast(context, error.message, tone: ToastTone.error);
    }
    return false;
  }
}
