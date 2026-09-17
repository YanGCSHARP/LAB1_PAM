import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// How large a money value is rendered. Maps onto the money type scale.
enum MoneySize { hero, large, medium, small }

/// Renders an amount with its currency symbol, optionally signed and colored
/// as income or expense.
///
/// Always goes through [Formatters], and the money styles carry tabular
/// figures, so a column of amounts lines up instead of jittering.
class MoneyText extends StatelessWidget {
  const MoneyText({
    required this.amount,
    required this.currency,
    super.key,
    this.isIncome,
    this.size = MoneySize.medium,
    this.compact = false,
    this.colored = true,
    this.color,
  });

  /// Always positive; the direction comes from [isIncome].
  final double amount;
  final String currency;

  /// `null` renders the value without a sign and without a semantic color.
  final bool? isIncome;

  final MoneySize size;

  /// Drops the decimals — for legends and other tight places.
  final bool compact;

  /// Set to `false` to keep the default text color while still showing a sign.
  final bool colored;

  /// Overrides the color entirely, e.g. on an accent-filled surface.
  final Color? color;

  TextStyle _style(BuildContext context) {
    final styles = context.money;
    return switch (size) {
      MoneySize.hero => styles.hero,
      MoneySize.large => styles.large,
      MoneySize.medium => styles.medium,
      MoneySize.small => styles.small,
    };
  }

  @override
  Widget build(BuildContext context) {
    final direction = isIncome;
    final text = direction == null
        ? (compact
              ? Formatters.compactMoney(amount, currency)
              : Formatters.money(amount, currency))
        : Formatters.signedMoney(
            amount,
            currency,
            isIncome: direction,
            compact: compact,
          );

    Color? resolved = color;
    if (resolved == null && colored && direction != null) {
      final semantic = context.semantic;
      resolved = direction ? semantic.income : semantic.expense;
    }

    return Text(
      text,
      style: _style(context).copyWith(color: resolved),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
