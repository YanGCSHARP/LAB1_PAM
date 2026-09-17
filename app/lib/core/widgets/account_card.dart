import 'package:flutter/material.dart';

import '../mock/mock_data.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import 'money_text.dart';

/// Icon and tint for an account type, so three accounts no longer look like
/// three identical squares.
({IconData icon, Color color}) accountVisual(
  BuildContext context,
  AccountKind kind,
) {
  final semantic = context.semantic;
  return switch (kind) {
    AccountKind.card => (
      icon: Icons.credit_card,
      color: context.colors.primary,
    ),
    AccountKind.cash => (icon: Icons.payments_outlined, color: semantic.income),
    AccountKind.savings => (
      icon: Icons.savings_outlined,
      color: semantic.category('utilities'),
    ),
  };
}

/// Balance card of one account.
///
/// [width] fixed — the horizontal strip on the dashboard; [width] null — a
/// full-width tile on the accounts screen.
class AccountCard extends StatelessWidget {
  const AccountCard({required this.account, super.key, this.onTap, this.width});

  final MockAccount account;
  final VoidCallback? onTap;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final visual = accountVisual(context, account.kind);

    final card = Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: Insets.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: visual.color.withValues(alpha: 0.14),
                      borderRadius: Corners.chipRadius,
                    ),
                    child: Icon(
                      visual.icon,
                      size: IconSizes.md,
                      color: visual.color,
                    ),
                  ),
                  const SizedBox(width: Insets.sm + 2),
                  Expanded(
                    child: Text(
                      account.name,
                      style: context.texts.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Insets.lg),
              MoneyText(
                amount: account.balance,
                currency: account.currency,
                size: MoneySize.large,
              ),
              const SizedBox(height: 2),
              Text(account.currency, style: context.texts.labelSmall),
            ],
          ),
        ),
      ),
    );

    return width == null ? card : SizedBox(width: width, child: card);
  }
}
