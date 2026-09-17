import 'package:flutter/material.dart';

import '../../../core/mock/mock_data.dart';
import '../../../core/widgets/account_card.dart';
import '../../../core/widgets/money_text.dart';
import '../../../core/widgets/state_views.dart';
import 'account_form_screen.dart';

/// List of the user's accounts with a per-currency total on top.
class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  void _openForm(BuildContext context, {MockAccount? account}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AccountFormScreen(account: account),
      ),
    );
  }

  /// Balances grouped by currency — accounts in different currencies are never
  /// summed together.
  Map<String, double> _totalsByCurrency(List<MockAccount> accounts) {
    final totals = <String, double>{};
    for (final account in accounts) {
      totals[account.currency] =
          (totals[account.currency] ?? 0) + account.balance;
    }
    return totals;
  }

  @override
  Widget build(BuildContext context) {
    final totals = _totalsByCurrency(mockAccounts);

    return Scaffold(
      appBar: AppBar(title: const Text('Мои счета')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Счёт'),
      ),
      body: mockAccounts.isEmpty
          ? EmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Счетов пока нет',
              message: 'Добавьте счёт, чтобы записывать по нему операции.',
              actionLabel: 'Добавить счёт',
              onAction: () => _openForm(context),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                _TotalsCard(totals: totals),
                const SizedBox(height: 20),
                for (final account in mockAccounts) ...[
                  AccountCard(
                    account: account,
                    onTap: () => _openForm(context, account: account),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.totals});

  final Map<String, double> totals;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Всего на счетах',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 10),
            for (final entry in totals.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: MoneyText(
                  amount: entry.value,
                  currency: entry.key,
                  size: MoneySize.large,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
