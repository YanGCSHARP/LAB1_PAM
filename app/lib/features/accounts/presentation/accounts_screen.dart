import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/account_card.dart';
import '../../../core/widgets/async_views.dart';
import '../../../core/widgets/money_text.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/state_views.dart';
import '../../home/application/data_refresh.dart';
import '../application/accounts_providers.dart';
import '../domain/account.dart';
import '../domain/balances.dart';

/// List of the user's accounts with a per-currency total on top.
class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  void _openForm(BuildContext context, {Account? account}) {
    context.push(
      account == null
          ? AppRoutes.accountNew
          : AppRoutes.accountEdit(account.id),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balances = ref.watch(accountBalancesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.accounts)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Счёт'),
      ),
      body: AsyncValueView(
        value: balances,
        loading: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          children: const [
            CardSkeleton(height: 96),
            SizedBox(height: 20),
            CardSkeleton(height: 120),
            SizedBox(height: 12),
            CardSkeleton(height: 120),
          ],
        ),
        data: (accounts) {
          if (accounts.isEmpty) {
            return EmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Счетов пока нет',
              message: 'Добавьте счёт, чтобы записывать по нему операции.',
              actionLabel: 'Добавить счёт',
              onAction: () => _openForm(context),
            );
          }
          return RefreshIndicator(
            onRefresh: () => refreshAllData(ref),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                _TotalsCard(totals: totalsByCurrency(accounts)),
                const SizedBox(height: 20),
                for (final item in accounts) ...[
                  AccountCard(
                    account: item.account,
                    balance: item.balance,
                    onTap: () => _openForm(context, account: item.account),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          );
        },
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
