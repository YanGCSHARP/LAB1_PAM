import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';

/// Meaning of a toast; decides its leading icon and accent stripe.
enum ToastTone { neutral, success, error }

/// Floating confirmation at the bottom of the screen.
///
/// Wraps `SnackBar` so every message in the app has the same shape, and so a
/// success and a failure are told apart by an icon as well as by color.
void showAppToast(
  BuildContext context,
  String message, {
  ToastTone tone = ToastTone.neutral,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final semantic = context.semantic;
  final (Color color, IconData icon) = switch (tone) {
    ToastTone.neutral => (context.colors.primary, Icons.info_outline),
    ToastTone.success => (semantic.income, Icons.check_circle_outline),
    ToastTone.error => (semantic.danger, Icons.error_outline),
  };

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            Icon(icon, size: IconSizes.md, color: color),
            const SizedBox(width: Insets.md),
            Expanded(child: Text(message, style: context.texts.bodyMedium)),
          ],
        ),
        action: actionLabel == null || onAction == null
            ? null
            : SnackBarAction(label: actionLabel, onPressed: onAction),
      ),
    );
}

/// Persistent strip above the content — used for the offline banner later on.
class AppBanner extends StatelessWidget {
  const AppBanner({
    required this.message,
    super.key,
    this.icon = Icons.cloud_off_outlined,
    this.tone = ToastTone.neutral,
  });

  final String message;
  final IconData icon;
  final ToastTone tone;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semantic;
    final color = switch (tone) {
      ToastTone.neutral => semantic.textMuted,
      ToastTone.success => semantic.income,
      ToastTone.error => semantic.danger,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.lg,
        vertical: Insets.md,
      ),
      color: color.withValues(alpha: 0.12),
      child: Row(
        children: [
          Icon(icon, size: IconSizes.sm, color: color),
          const SizedBox(width: Insets.sm),
          Expanded(
            child: Text(
              message,
              style: context.texts.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
