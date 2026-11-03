import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../accounts/application/accounts_providers.dart';
import '../../budgets/application/budgets_providers.dart';
import '../../profile/application/profile_providers.dart';
import '../../transactions/application/transactions_providers.dart';

/// Reloads every collection from the repositories.
///
/// Backs pull-to-refresh and the «Повторить» button of the error states.
/// Only the source collections are invalidated: every derived provider
/// (balances, dashboard, budget progress) depends on them and recomputes by
/// itself. Completes once the requests have finished; a failure is not
/// rethrown — it lands in the providers' state, where the screen shows it.
Future<void> refreshAllData(WidgetRef ref) async {
  ref
    ..invalidate(profileProvider)
    ..invalidate(accountsProvider)
    ..invalidate(transactionsProvider)
    ..invalidate(budgetsProvider);
  try {
    await Future.wait([
      ref.read(profileProvider.future),
      ref.read(accountsProvider.future),
      ref.read(transactionsProvider.future),
      ref.read(budgetsProvider.future),
    ]);
  } on Object {
    // Shown by the screen's error state.
  }
}
