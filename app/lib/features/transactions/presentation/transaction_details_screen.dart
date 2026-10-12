import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/category_badge.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/money_text.dart';

/// One operation in full: amount, type, category, account, date, note.
class TransactionDetailsScreen extends StatelessWidget {
  const TransactionDetailsScreen({required this.transaction, super.key});

  final MockTransaction transaction;

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Удалить операцию?',
      message: 'Операция пропадёт из списка и из расчёта бюджетов.',
      confirmLabel: AppStrings.delete,
      destructive: true,
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    showAppToast(context, 'Операция удалена');
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.transactions);
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = findMockAccount(transaction.accountId);
    final currency = account?.currency ?? MockUser.defaultCurrency;
    final isIncome = transaction.isIncome;
    final note = transaction.note;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Операция'),
        actions: [
          IconButton(
            onPressed: () =>
                context.push(AppRoutes.transactionEdit(transaction.id)),
            icon: const Icon(Icons.edit_outlined),
            tooltip: AppStrings.edit,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Insets.lg,
          Insets.lg,
          Insets.lg,
          Insets.xxl,
        ),
        children: [
          Center(
            child: CategoryAvatar(
              category: transaction.category,
              kind: transaction.kind,
              size: 56,
            ),
          ),
          const SizedBox(height: Insets.md),
          Center(
            child: MoneyText(
              amount: transaction.amount,
              currency: currency,
              isIncome: isIncome,
              size: MoneySize.hero,
              // Same rule as the list: only income is tinted.
              color: isIncome ? null : context.colors.onSurface,
            ),
          ),
          const SizedBox(height: Insets.sm),
          Center(
            child: AppBadge(
              label: isIncome ? AppStrings.income : AppStrings.expense,
              tone: isIncome ? BadgeTone.income : BadgeTone.neutral,
              icon: isIncome ? Icons.south_west : Icons.north_east,
            ),
          ),
          const SizedBox(height: Insets.xl),
          AppCard(
            child: Column(
              children: [
                _DetailRow(
                  label: 'Категория',
                  child: CategoryBadge(
                    category: transaction.category,
                    kind: transaction.kind,
                  ),
                ),
                _DetailRow(
                  label: 'Счёт',
                  child: Text(
                    account?.name ?? 'Счёт удалён',
                    style: context.texts.bodyLarge,
                  ),
                ),
                _DetailRow(
                  label: 'Дата',
                  child: Text(
                    Formatters.dateWithTime(transaction.date),
                    style: context.texts.bodyLarge,
                  ),
                ),
                _DetailRow(
                  label: 'Заметка',
                  isLast: true,
                  child: Text(
                    note == null || note.isEmpty ? '—' : note,
                    style: context.texts.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.xl),
          SecondaryButton(
            label: AppStrings.edit,
            icon: Icons.edit_outlined,
            onPressed: () =>
                context.push(AppRoutes.transactionEdit(transaction.id)),
          ),
          const SizedBox(height: Insets.md),
          DestructiveButton(
            label: 'Удалить операцию',
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.child,
    this.isLast = false,
  });

  final String label;
  final Widget child;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : Insets.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(label, style: context.texts.bodySmall),
          ),
          const SizedBox(width: Insets.md),
          Expanded(
            child: Align(alignment: Alignment.centerLeft, child: child),
          ),
        ],
      ),
    );
  }
}
