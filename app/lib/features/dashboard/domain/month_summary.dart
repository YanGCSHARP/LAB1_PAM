import 'package:equatable/equatable.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/money.dart';
import '../../transactions/domain/transaction.dart';

/// A slice of the dashboard expense chart.
class CategorySlice extends Equatable {
  const CategorySlice({
    required this.category,
    required this.amount,
    required this.share,
  });

  final String category;
  final double amount;

  /// Fraction of the month's total expenses, 0..1.
  final double share;

  @override
  List<Object?> get props => [category, amount, share];
}

/// Income, expense and expense structure of one month — the numbers behind
/// `GET /dashboard/summary`.
class MonthSummary extends Equatable {
  const MonthSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.byCategory,
  });

  /// Sums the [transactions] that fall into [month] (`YYYY-MM`, local time).
  ///
  /// The caller passes only transactions in one currency: amounts in
  /// different currencies are never added together.
  factory MonthSummary.of(Iterable<Transaction> transactions, String month) {
    final income = <double>[];
    final expenses = <String, List<double>>{};
    for (final transaction in transactions) {
      if (Formatters.monthKey(transaction.date.toLocal()) != month) {
        continue;
      }
      if (transaction.isIncome) {
        income.add(transaction.amount);
      } else {
        (expenses[transaction.category] ??= []).add(transaction.amount);
      }
    }

    final totalExpense = Money.sum(expenses.values.expand((list) => list));
    final slices = [
      for (final entry in expenses.entries)
        CategorySlice(
          category: entry.key,
          amount: Money.sum(entry.value),
          share: Money.ratio(Money.sum(entry.value), totalExpense),
        ),
    ]..sort((a, b) => b.amount.compareTo(a.amount));

    return MonthSummary(
      totalIncome: Money.sum(income),
      totalExpense: totalExpense,
      byCategory: slices,
    );
  }

  final double totalIncome;
  final double totalExpense;

  /// Largest expense category first.
  final List<CategorySlice> byCategory;

  @override
  List<Object?> get props => [totalIncome, totalExpense, byCategory];
}
