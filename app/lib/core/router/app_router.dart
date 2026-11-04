import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/accounts/application/accounts_providers.dart';
import '../../features/accounts/presentation/account_form_screen.dart';
import '../../features/accounts/presentation/accounts_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/budgets/application/budgets_providers.dart';
import '../../features/budgets/presentation/budget_form_screen.dart';
import '../../features/budgets/presentation/budgets_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/home/presentation/home_shell.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/transactions/application/transactions_providers.dart';
import '../../features/transactions/domain/transaction_filter.dart';
import '../../features/transactions/presentation/transaction_details_screen.dart';
import '../../features/transactions/presentation/transaction_form_screen.dart';
import '../../features/transactions/presentation/transactions_screen.dart';
import '../state/app_session.dart';
import '../widgets/async_views.dart';
import 'app_routes.dart';
import 'not_found_screen.dart';

/// Where an auth state and a location should lead, or `null` to stay.
///
/// Signed out, every private route bounces to the login screen; signed in,
/// the auth screens bounce to the dashboard, so the back button can never
/// return to the login form after a successful sign-in.
String? authRedirect({required bool signedIn, required String location}) {
  final isPublic = AppRoutes.public.contains(location);
  if (!signedIn && !isPublic) {
    return AppRoutes.login;
  }
  if (signedIn && isPublic) {
    return AppRoutes.dashboard;
  }
  return null;
}

/// Builds the app's route tree.
///
/// The four tabs are branches of a [StatefulShellRoute]: each keeps its own
/// navigation stack and scroll position while another tab is open. Forms are
/// placed on the root navigator, so they cover the bottom bar — a half-filled
/// form should not be one tap away from switching tabs.
///
/// Routes with an `:id` hand the id to a [RecordPage], which loads the record
/// through its provider and shows "not found" for an id that matches nothing.
GoRouter createAppRouter({
  required AuthSession session,
  String initialLocation = AppRoutes.login,
}) {
  final rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: initialLocation,
    refreshListenable: session,
    redirect: (context, state) =>
        authRedirect(signedIn: session.isSignedIn, location: state.uri.path),
    errorBuilder: (context, state) => const NotFoundScreen(),
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => LoginScreen(onSignedIn: session.signIn),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) =>
            RegisterScreen(onRegistered: session.signIn),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.transactions,
                builder: (context, state) => TransactionsScreen(
                  filter: TransactionFilter.fromQuery(
                    state.uri.queryParameters,
                  ),
                ),
                routes: [
                  // Declared before `:id`, otherwise "new" is read as an id.
                  GoRoute(
                    path: 'new',
                    parentNavigatorKey: rootKey,
                    builder: (context, state) =>
                        RecordPage<TransactionFormData>(
                          provider: transactionFormDataProvider(null),
                          builder: (context, data) =>
                              TransactionFormScreen(accounts: data.accounts),
                        ),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => RecordPage<TransactionDetails>(
                      provider: transactionDetailsProvider(
                        state.pathParameters['id']!,
                      ),
                      builder: (context, details) =>
                          TransactionDetailsScreen(details: details),
                    ),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        parentNavigatorKey: rootKey,
                        builder: (context, state) =>
                            RecordPage<TransactionFormData>(
                              provider: transactionFormDataProvider(
                                state.pathParameters['id'],
                              ),
                              builder: (context, data) => TransactionFormScreen(
                                accounts: data.accounts,
                                transaction: data.transaction,
                              ),
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.budgets,
                builder: (context, state) => BudgetsScreen(
                  initialMonth: state.uri.queryParameters['month'],
                ),
                routes: [
                  GoRoute(
                    path: 'new',
                    parentNavigatorKey: rootKey,
                    builder: (context, state) => RecordPage<BudgetFormData>(
                      provider: budgetFormDataProvider(null),
                      builder: (context, data) => BudgetFormScreen(
                        budgets: data.budgets,
                        currency: data.currency,
                        initialMonth: state.uri.queryParameters['month'],
                      ),
                    ),
                  ),
                  GoRoute(
                    path: ':id/edit',
                    parentNavigatorKey: rootKey,
                    builder: (context, state) => RecordPage<BudgetFormData>(
                      provider: budgetFormDataProvider(
                        state.pathParameters['id'],
                      ),
                      builder: (context, data) => BudgetFormScreen(
                        budgets: data.budgets,
                        currency: data.currency,
                        budget: data.budget,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      // Accounts are reached from two tabs (dashboard and profile), so they
      // sit outside the shell and are pushed on top of whichever tab opened
      // them; back returns to that tab.
      GoRoute(
        path: AppRoutes.accounts,
        builder: (context, state) => const AccountsScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => RecordPage<AccountFormData>(
              provider: accountFormDataProvider(null),
              builder: (context, data) =>
                  AccountFormScreen(accounts: data.accounts),
            ),
          ),
          GoRoute(
            path: ':id/edit',
            builder: (context, state) => RecordPage<AccountFormData>(
              provider: accountFormDataProvider(state.pathParameters['id']),
              builder: (context, data) => AccountFormScreen(
                accounts: data.accounts,
                account: data.account,
                operationCount: data.operationCount,
              ),
            ),
          ),
        ],
      ),
    ],
  );
}
