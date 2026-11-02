import 'package:equatable/equatable.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/money.dart';
import '../../transactions/domain/transaction.dart';
import 'budget.dart';

/// How close a budget is to its limit.
enum BudgetStatus {
  /// Below 90 %.
  normal,

  /// From 90 % inclusive up to 100 % exclusive.
  warning,

  /// 100 % and above.
  exceeded;

  /// The thresholds of the data model; both bounds are inclusive.
  static BudgetStatus of(double progress) {
    if (progress >= 1.0) {
      return exceeded;
    }
    if (progress >= 0.9) {
      return warning;
    }
    return normal;
  }
}

/// A budget together with the amount already spent in its month.
class BudgetProgress extends Equatable {
  const BudgetProgress({required this.budget, required this.spentAmount});

  final Budget budget;
  final double spentAmount;

  /// `spentAmount / limitAmount`; above 1 when the limit is exceeded.
  double get progress => Money.ratio(spentAmount, budget.limitAmount);

  double get remaining => Money.sum([budget.limitAmount, -spentAmount]);

  BudgetStatus get status => BudgetStatus.of(progress);

  bool get isWarning => status == BudgetStatus.warning;

  bool get isExceeded => status == BudgetStatus.exceeded;

  @override
  List<Object?> get props => [budget, spentAmount];
}

/// Progress of the [budgets] set for [month] (`YYYY-MM`), most used first.
///
/// Spending is the sum of the month's expenses in the budget's category.
/// The caller passes only transactions in the budgets' currency.
List<BudgetProgress> computeBudgetProgress(
  Iterable<Budget> budgets,
  Iterable<Transaction> transactions,
  String month,
) {
  final spent = <String, List<double>>{};
  for (final transaction in transactions) {
    if (transaction.isIncome ||
        Formatters.monthKey(transaction.date.toLocal()) != month) {
      continue;
    }
    (spent[transaction.category] ??= []).add(transaction.amount);
  }

  return [
    for (final budget in budgets)
      if (budget.month == month)
        BudgetProgress(
          budget: budget,
          spentAmount: Money.sum(spent[budget.category] ?? const []),
        ),
  ]..sort((a, b) => b.progress.compareTo(a.progress));
}
