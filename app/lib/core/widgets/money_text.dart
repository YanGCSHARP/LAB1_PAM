import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// Renders an amount with the currency symbol and, optionally, a direction
/// sign colored as income or expense.
///
/// Amounts are always formatted through [Formatters] — never concatenated —
/// so grouping and the decimal separator stay consistent across the app.
class MoneyText extends StatelessWidget {
  const MoneyText({
    required this.amount,
    required this.currency,
    super.key,
    this.isIncome,
    this.style,
    this.compact = false,
    this.colored = true,
  });

  /// Always positive; the sign comes from [isIncome].
  final double amount;
  final String currency;

  /// `null` renders the amount without a sign and without a semantic color.
  final bool? isIncome;

  final TextStyle? style;

  /// Drops the decimal part — for chart legends and other tight places.
  final bool compact;

  /// Set to `false` to keep the default text color while still showing a sign.
  final bool colored;

  @override
  Widget build(BuildContext context) {
    final direction = isIncome;
    final text = direction == null
        ? (compact
              ? Formatters.compactMoney(amount, currency)
              : Formatters.money(amount, currency))
        : Formatters.signedMoney(amount, currency, isIncome: direction);

    Color? color;
    if (colored && direction != null) {
      final semantic = context.semanticColors;
      color = direction ? semantic.income : semantic.expense;
    }

    return Text(
      text,
      style: (style ?? DefaultTextStyle.of(context).style).copyWith(
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
