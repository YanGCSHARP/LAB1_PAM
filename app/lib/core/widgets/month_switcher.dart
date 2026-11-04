import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import '../utils/formatters.dart';

/// `‹ Сентябрь 2026 ›` — steps one month back or forward.
class MonthSwitcher extends StatelessWidget {
  const MonthSwitcher({
    required this.month,
    required this.onPrevious,
    required this.onNext,
    super.key,
  });

  /// Any day of the shown month.
  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Insets.sm),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Предыдущий месяц',
          ),
          Expanded(
            child: Text(
              Formatters.monthTitle(month),
              textAlign: TextAlign.center,
              style: context.texts.titleMedium,
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Следующий месяц',
          ),
        ],
      ),
    );
  }
}
