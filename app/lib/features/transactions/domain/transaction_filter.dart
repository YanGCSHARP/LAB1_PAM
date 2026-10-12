import 'package:flutter/foundation.dart';

import '../../../core/mock/mock_data.dart';
import '../../../core/utils/category_catalog.dart';
import '../../../core/utils/formatters.dart';

/// Filters of the transactions list.
///
/// The filter lives in the URL query (`/transactions?category=food&month=2026-09`)
/// rather than in widget state: the dashboard chart and the budget rows link
/// straight into a filtered list, and the back button restores it.
@immutable
class TransactionFilter {
  const TransactionFilter({this.kind, this.category, this.month, this.query});

  /// Reads the filter from a route's query parameters. Unknown or malformed
  /// values are dropped rather than rejected — a hand-edited link still opens
  /// the list, just less filtered.
  factory TransactionFilter.fromQuery(Map<String, String> params) {
    final kind = switch (params['type']) {
      'income' => TransactionKind.income,
      'expense' => TransactionKind.expense,
      _ => null,
    };
    final month = params['month'];
    final query = params['q']?.trim();
    return TransactionFilter(
      kind: kind,
      category: _nonEmpty(params['category']),
      month: month != null && _monthKey.hasMatch(month) ? month : null,
      query: _nonEmpty(query),
    );
  }

  static final RegExp _monthKey = RegExp(r'^\d{4}-(0[1-9]|1[0-2])$');

  static String? _nonEmpty(String? value) =>
      value == null || value.isEmpty ? null : value;

  final TransactionKind? kind;

  /// Category key from [CategoryCatalog].
  final String? category;

  /// Month key `YYYY-MM`.
  final String? month;

  /// Free-text search over the note and the category label.
  final String? query;

  bool get isEmpty =>
      kind == null && category == null && month == null && query == null;

  /// Number of chip filters set — the search box is not counted.
  int get activeCount =>
      [kind, category, month].where((value) => value != null).length;

  Map<String, String> toQuery() => {
    if (kind != null) 'type': kind!.name,
    'category': ?category,
    'month': ?month,
    'q': ?query,
  };

  TransactionFilter copyWith({
    ValueGetter<TransactionKind?>? kind,
    ValueGetter<String?>? category,
    ValueGetter<String?>? month,
    ValueGetter<String?>? query,
  }) {
    return TransactionFilter(
      kind: kind == null ? this.kind : kind(),
      category: category == null ? this.category : category(),
      month: month == null ? this.month : month(),
      query: query == null ? this.query : query(),
    );
  }

  bool matches(MockTransaction transaction) {
    if (kind != null && transaction.kind != kind) {
      return false;
    }
    if (category != null && transaction.category != category) {
      return false;
    }
    if (month != null &&
        Formatters.monthKey(transaction.date.toLocal()) != month) {
      return false;
    }
    final text = query?.toLowerCase();
    if (text != null) {
      final label = CategoryCatalog.labelOf(
        transaction.category,
        kind: transaction.kind,
      ).toLowerCase();
      final note = transaction.note?.toLowerCase() ?? '';
      if (!note.contains(text) && !label.contains(text)) {
        return false;
      }
    }
    return true;
  }

  /// Matching transactions, newest first.
  List<MockTransaction> apply(Iterable<MockTransaction> transactions) {
    return transactions.where(matches).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  bool operator ==(Object other) =>
      other is TransactionFilter &&
      other.kind == kind &&
      other.category == category &&
      other.month == month &&
      other.query == query;

  @override
  int get hashCode => Object.hash(kind, category, month, query);
}
