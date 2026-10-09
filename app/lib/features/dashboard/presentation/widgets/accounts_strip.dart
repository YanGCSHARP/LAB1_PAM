import 'package:flutter/material.dart';

import '../../../../core/mock/mock_data.dart';
import '../../../../core/widgets/account_card.dart';

/// Horizontally scrolling row of account balance cards.
class AccountsStrip extends StatelessWidget {
  const AccountsStrip({required this.accounts, super.key, this.onAccountTap});

  final List<MockAccount> accounts;
  final ValueChanged<MockAccount>? onAccountTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 148,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: accounts.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final account = accounts[index];
          return AccountCard(
            account: account,
            width: 190,
            onTap: onAccountTap == null ? null : () => onAccountTap!(account),
          );
        },
      ),
    );
  }
}
