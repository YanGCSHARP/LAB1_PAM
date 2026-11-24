import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/cache/data_cache.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/widgets/app_toast.dart';

/// Main frame of the app: four tabs in a [NavigationBar].
///
/// Each tab is a branch of the router's `StatefulShellRoute`, so a tab keeps
/// its own stack — open a transaction, switch to budgets and back, and the
/// transaction is still open.
///
/// While the server is out of reach the shell shows a banner over every tab:
/// the screens show the saved copy and changes cannot be saved.
class HomeShell extends ConsumerWidget {
  const HomeShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const List<NavigationDestination> _destinations = [
    NavigationDestination(
      icon: Icon(Icons.pie_chart_outline),
      selectedIcon: Icon(Icons.pie_chart),
      label: AppStrings.navDashboard,
    ),
    NavigationDestination(
      icon: Icon(Icons.receipt_long_outlined),
      selectedIcon: Icon(Icons.receipt_long),
      label: AppStrings.navTransactions,
    ),
    NavigationDestination(
      icon: Icon(Icons.savings_outlined),
      selectedIcon: Icon(Icons.savings),
      label: AppStrings.navBudgets,
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: AppStrings.navProfile,
    ),
  ];

  void _select(int index) {
    // Tapping the tab that is already open returns it to its root screen,
    // as in most mobile apps.
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = ref.watch(offlineProvider);
    return Scaffold(
      body: Column(
        children: [
          if (offline)
            const SafeArea(
              bottom: false,
              child: AppBanner(message: AppStrings.offlineBanner),
            ),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: offline,
              child: navigationShell,
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _select,
        destinations: _destinations,
      ),
    );
  }
}
