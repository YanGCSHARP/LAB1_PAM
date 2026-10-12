import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_strings.dart';
import '../theme/design_tokens.dart';
import '../widgets/app_buttons.dart';
import '../widgets/state_views.dart';
import 'app_routes.dart';

/// Shown for an unknown path and for an `:id` that matches nothing.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const EmptyState(
            icon: Icons.link_off,
            title: AppStrings.notFoundTitle,
            message: AppStrings.notFoundMessage,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Insets.xxl),
            child: PrimaryButton(
              label: AppStrings.toDashboard,
              icon: Icons.home_outlined,
              onPressed: () => context.go(AppRoutes.dashboard),
            ),
          ),
        ],
      ),
    );
  }
}
