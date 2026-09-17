import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/widgets/empty_state.dart';
import '../../dashboard/presentation/dashboard_screen.dart';

/// Main frame of the app: four tabs in a [NavigationBar].
///
/// The selected index is local widget state; tab switching is plain
/// [IndexedStack] swapping, so each tab keeps its scroll position.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _index = widget.initialIndex;

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

  void _select(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          DashboardScreen(onOpenBudgets: () => _select(2)),
          const _PendingTab(title: AppStrings.navTransactions),
          const _PendingTab(title: AppStrings.navBudgets),
          const _PendingTab(title: AppStrings.navProfile),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: _destinations,
      ),
    );
  }
}

/// Temporary content of a tab whose screen is built later in this same lab.
/// Every one of these is replaced before the stage is finished.
class _PendingTab extends StatelessWidget {
  const _PendingTab({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const EmptyState(
        icon: Icons.construction_outlined,
        title: 'Экран в работе',
        message: 'Появится в этой же лабораторной — вёрстка идёт по очереди.',
      ),
    );
  }
}
