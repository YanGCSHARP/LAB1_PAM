import 'package:flutter/material.dart';

import '../mock/mock_data.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import '../utils/category_catalog.dart';
import 'category_badge.dart';
import 'money_text.dart';

/// One transaction in a list: category avatar, note, account, amount.
///
/// The note is the primary line because that is what a person recognises an
/// operation by; the category and account sit under it as metadata.
class TransactionRow extends StatelessWidget {
  const TransactionRow({
    required this.transaction,
    super.key,
    this.accountName,
    this.onTap,
    this.showCategoryName = true,
  });

  final MockTransaction transaction;

  /// Shown after the category, when the list mixes several accounts.
  final String? accountName;

  final VoidCallback? onTap;

  /// Off when the list is already grouped by category.
  final bool showCategoryName;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semantic;
    final category = CategoryCatalog.byKey(
      transaction.category,
      kind: transaction.kind,
    );

    final title = transaction.note?.isNotEmpty == true
        ? transaction.note!
        : category.label;

    final metaParts = <String>[
      if (showCategoryName) category.label,
      ?accountName,
    ];

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.lg,
          vertical: Insets.md,
        ),
        child: Row(
          children: [
            CategoryAvatar(
              category: transaction.category,
              kind: transaction.kind,
            ),
            const SizedBox(width: Insets.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: context.texts.bodyLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (metaParts.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      metaParts.join(' · '),
                      style: context.texts.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: Insets.md),
            MoneyText(
              amount: transaction.amount,
              currency: accountCurrency(transaction.accountId),
              isIncome: transaction.isIncome,
              // An expense keeps the default text color: a list where every
              // second row is red is unreadable. Only income is tinted.
              color: transaction.isIncome ? semantic.income : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Currency of the account a transaction belongs to.
String accountCurrency(String accountId) => mockAccountById(accountId).currency;

/// Sticky-looking date header above a group of transactions.
class TransactionDateHeader extends StatelessWidget {
  const TransactionDateHeader({required this.label, super.key, this.trailing});

  final String label;

  /// Usually the day total.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Insets.lg,
        Insets.lg,
        Insets.lg,
        Insets.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: context.texts.labelMedium?.copyWith(
                color: context.semantic.textMuted,
                letterSpacing: 0.3,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
