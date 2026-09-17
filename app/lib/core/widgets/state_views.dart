import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import 'app_buttons.dart';

/// Nothing to show yet.
///
/// Every empty state names what is missing and offers the action that fills
/// it — «нет данных» tells a person nothing about what to do next.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    super.key,
    this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Tighter variant for an empty block inside a card.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 48.0 : IconSizes.illustration;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: Insets.xxl,
          vertical: compact ? Insets.lg : Insets.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: size * 0.44,
                color: context.semantic.textMuted,
              ),
            ),
            SizedBox(height: compact ? Insets.md : Insets.lg),
            Text(
              title,
              style: compact
                  ? context.texts.titleSmall
                  : context.texts.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: Insets.sm),
              Text(
                message!,
                style: context.texts.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: compact ? Insets.lg : Insets.xl),
              SecondaryButton(label: actionLabel!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}

/// Something went wrong — always paired with a way to try again.
class ErrorState extends StatelessWidget {
  const ErrorState({
    required this.title,
    super.key,
    this.message,
    this.onRetry,
    this.icon = Icons.cloud_off_outlined,
  });

  final String title;
  final String? message;
  final VoidCallback? onRetry;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.xxl,
          vertical: Insets.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: IconSizes.illustration,
              height: IconSizes.illustration,
              decoration: BoxDecoration(
                color: context.colors.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: IconSizes.illustration * 0.44,
                color: context.colors.onErrorContainer,
              ),
            ),
            const SizedBox(height: Insets.lg),
            Text(
              title,
              style: context.texts.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: Insets.sm),
              Text(
                message!,
                style: context.texts.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: Insets.xl),
              SecondaryButton(
                label: 'Повторить',
                icon: Icons.refresh,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
