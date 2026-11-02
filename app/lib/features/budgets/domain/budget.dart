import 'package:equatable/equatable.dart';

import '../../../core/utils/money.dart';

/// A monthly spending limit for one expense category.
class Budget extends Equatable {
  const Budget({
    required this.id,
    required this.category,
    required this.limitAmount,
    required this.month,
  });

  factory Budget.fromJson(Map<String, dynamic> json) => Budget(
    id: json['id'] as String,
    category: json['category'] as String,
    limitAmount: (json['limitAmount'] as num).toDouble(),
    month: json['month'] as String,
  );

  final String id;

  /// Expense category key.
  final String category;

  /// Strictly positive, in the user's default currency.
  final double limitAmount;

  /// Month key in `YYYY-MM` format.
  final String month;

  Budget copyWith({String? category, double? limitAmount, String? month}) {
    return Budget(
      id: id,
      category: category ?? this.category,
      limitAmount: limitAmount ?? this.limitAmount,
      month: month ?? this.month,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'limitAmount': Money.round(limitAmount),
    'month': month,
  };

  @override
  List<Object?> get props => [id, category, limitAmount, month];
}
