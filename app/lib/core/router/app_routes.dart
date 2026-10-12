import '../../features/transactions/domain/transaction_filter.dart';

/// Every path of the app, in one place.
///
/// Screens never spell a path out by hand — they call these, so renaming a
/// route is a one-line change and a typo is a compile error, not a 404.
/// The table of routes lives in `docs/screens.md`.
abstract final class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';

  // The four tabs.
  static const String dashboard = '/dashboard';
  static const String transactions = '/transactions';
  static const String budgets = '/budgets';
  static const String profile = '/profile';

  static const String transactionNew = '/transactions/new';
  static String transaction(String id) => '/transactions/$id';
  static String transactionEdit(String id) => '/transactions/$id/edit';

  /// The transactions tab with filters applied, e.g.
  /// `/transactions?category=food&month=2026-09`.
  static String transactionsFiltered(TransactionFilter filter) =>
      _withQuery(transactions, filter.toQuery());

  static String budgetsOfMonth(String month) =>
      _withQuery(budgets, {'month': month});
  static String budgetNew({String? month}) =>
      _withQuery('/budgets/new', {'month': ?month});
  static String budgetEdit(String id) => '/budgets/$id/edit';

  static const String accounts = '/accounts';
  static const String accountNew = '/accounts/new';
  static String accountEdit(String id) => '/accounts/$id/edit';

  /// Routes reachable without signing in.
  static const Set<String> public = {login, register};

  static String _withQuery(String path, Map<String, String> query) {
    if (query.isEmpty) {
      return path;
    }
    return Uri(path: path, queryParameters: query).toString();
  }
}
