import 'package:equatable/equatable.dart';

import '../../../core/utils/category_catalog.dart';
import '../../../core/utils/money.dart';

/// One income or expense operation on an account.
class Transaction extends Equatable {
  const Transaction({
    required this.id,
    required this.accountId,
    required this.amount,
    required this.kind,
    required this.category,
    required this.date,
    this.note,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    id: json['id'] as String,
    accountId: json['accountId'] as String,
    amount: (json['amount'] as num).toDouble(),
    kind: TransactionKind.values.byName(json['type'] as String),
    category: json['category'] as String,
    date: DateTime.parse(json['date'] as String).toUtc(),
    note: json['note'] as String?,
  );

  final String id;
  final String accountId;

  /// Always positive; the direction is carried by [kind].
  final double amount;

  /// `type` in the API.
  final TransactionKind kind;

  /// Key from [CategoryCatalog], matching [kind].
  final String category;

  /// Stored in UTC, shown in local time.
  final DateTime date;

  final String? note;

  bool get isIncome => kind == TransactionKind.income;

  /// The amount with its direction: positive for income, negative for
  /// an expense.
  double get signedAmount => isIncome ? amount : -amount;

  Transaction copyWith({
    String? accountId,
    double? amount,
    TransactionKind? kind,
    String? category,
    DateTime? date,
    String? Function()? note,
  }) {
    return Transaction(
      id: id,
      accountId: accountId ?? this.accountId,
      amount: amount ?? this.amount,
      kind: kind ?? this.kind,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note == null ? this.note : note(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'accountId': accountId,
    'amount': Money.round(amount),
    'type': kind.name,
    'category': category,
    'date': date.toUtc().toIso8601String(),
    'note': note,
  };

  @override
  List<Object?> get props => [
    id,
    accountId,
    amount,
    kind,
    category,
    date,
    note,
  ];
}
