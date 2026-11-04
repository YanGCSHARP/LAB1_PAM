import 'package:flutter/material.dart';

import '../../../../core/widgets/account_card.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../accounts/domain/account.dart';

/// Horizontally scrolling row of account balance cards.
class AccountsStrip extends StatelessWidget {
  const AccountsStrip({required this.accounts, super.key, this.onAccountTap});

  final List<AccountBalance> accounts;
  final ValueChanged<Account>? onAccountTap;

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) {
      return const EmptyState(
        icon: Icons.account_balance_wallet_outlined,
        title: 'Счетов пока нет',
        message: 'Добавьте счёт в разделе «Мои счета».',
        compact: true,
      );
    }
    return SizedBox(
      height: 148,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: accounts.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = accounts[index];
          return AccountCard(
            account: item.account,
            balance: item.balance,
            width: 190,
            onTap: onAccountTap == null
                ? null
                : () => onAccountTap!(item.account),
          );
        },
      ),
    );
  }
}
