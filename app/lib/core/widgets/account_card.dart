import 'package:flutter/material.dart';

import '../mock/mock_data.dart';
import 'money_text.dart';

/// Balance card of a single account.
///
/// Used on the dashboard in a horizontally scrolling row ([width] fixed) and
/// on the accounts screen as a full-width tile ([width] left null).
class AccountCard extends StatelessWidget {
  const AccountCard({required this.account, super.key, this.onTap, this.width});

  final MockAccount account;
  final VoidCallback? onTap;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final card = Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 20,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      account.name,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              MoneyText(
                amount: account.balance,
                currency: account.currency,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 2),
              Text(
                account.currency,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (width == null) {
      return card;
    }
    return SizedBox(width: width, child: card);
  }
}
