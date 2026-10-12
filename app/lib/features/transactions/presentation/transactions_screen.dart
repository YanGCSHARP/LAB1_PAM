import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/category_catalog.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_filter_chip.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/category_badge.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/transaction_row.dart';
import '../domain/transaction_filter.dart';

/// All operations grouped by day, with search and filter chips.
///
/// The chip filters come from the URL ([filter]) and are changed by
/// navigating to a new URL; only the search text is local, so typing does not
/// flood the history with one entry per keystroke.
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({
    super.key,
    this.filter = const TransactionFilter(),
  });

  final TransactionFilter filter;

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  TransactionFilter get _filter => widget.filter;

  void _applyFilter(TransactionFilter filter) {
    context.go(AppRoutes.transactionsFiltered(filter));
  }

  void _resetAll() {
    _search.clear();
    _applyFilter(const TransactionFilter());
  }

  Future<void> _pickKind() async {
    final picked = await _pick<TransactionKind>(
      title: 'Тип операции',
      current: _filter.kind,
      options: [
        const _Option(label: 'Все операции', value: null),
        const _Option(label: 'Доходы', value: TransactionKind.income),
        const _Option(label: 'Расходы', value: TransactionKind.expense),
      ],
    );
    if (picked == null) {
      return;
    }
    final kind = picked.$1;
    // A category of the other direction would leave the list empty for no
    // visible reason, so it is dropped together with the type change.
    final category = _filter.category;
    final keepCategory =
        kind == null ||
        category == null ||
        CategoryCatalog.forKind(kind).any((c) => c.key == category);
    _applyFilter(
      _filter.copyWith(
        kind: () => kind,
        category: () => keepCategory ? category : null,
      ),
    );
  }

  Future<void> _pickCategory() async {
    final kind = _filter.kind;
    final categories = kind == null
        ? _uniqueByKey([
            ...CategoryCatalog.expenses,
            ...CategoryCatalog.incomes,
          ])
        : CategoryCatalog.forKind(kind);
    final picked = await _pick<String>(
      title: 'Категория',
      current: _filter.category,
      options: [
        const _Option(label: 'Все категории', value: null),
        for (final category in categories)
          _Option(
            label: category.label,
            value: category.key,
            leading: CategoryAvatar(
              category: category.key,
              kind: category.kind,
              size: 32,
            ),
          ),
      ],
    );
    if (picked != null) {
      _applyFilter(_filter.copyWith(category: () => picked.$1));
    }
  }

  Future<void> _pickMonth() async {
    final picked = await _pick<String>(
      title: 'Период',
      current: _filter.month,
      options: [
        const _Option(label: 'За всё время', value: null),
        for (final month in mockMonthsWithTransactions())
          _Option(
            label: Formatters.monthTitle(month),
            value: Formatters.monthKey(month),
          ),
      ],
    );
    if (picked != null) {
      _applyFilter(_filter.copyWith(month: () => picked.$1));
    }
  }

  /// Opens a picker sheet. Resolves to a one-field record with the choice —
  /// whose value may itself be `null` for "all" — or to `null` when the sheet
  /// was dismissed without choosing.
  Future<(T?,)?> _pick<T>({
    required String title,
    required T? current,
    required List<_Option<T>> options,
  }) {
    return showAppSheet<(T?,)>(
      context: context,
      title: title,
      builder: (sheetContext) => ListView(
        shrinkWrap: true,
        children: [
          for (final option in options)
            SheetOption(
              label: option.label,
              leading: option.leading,
              selected: option.value == current,
              onTap: () => Navigator.of(sheetContext).pop((option.value,)),
            ),
        ],
      ),
    );
  }

  static List<CategoryInfo> _uniqueByKey(List<CategoryInfo> categories) {
    final seen = <String>{};
    return [
      for (final category in categories)
        if (seen.add(category.key)) category,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final search = _search.text.trim();
    final effective = _filter.copyWith(
      query: () => search.isEmpty ? null : search,
    );
    final transactions = effective.apply(mockTransactions);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.navTransactions)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.transactionNew),
        icon: const Icon(Icons.add),
        label: const Text('Операция'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Insets.lg,
              Insets.xs,
              Insets.lg,
              Insets.sm,
            ),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Поиск по заметке или категории',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: search.isEmpty
                    ? null
                    : IconButton(
                        onPressed: _search.clear,
                        icon: const Icon(Icons.close),
                        tooltip: 'Очистить поиск',
                      ),
              ),
            ),
          ),
          _FilterBar(
            filter: _filter,
            onKind: _pickKind,
            onCategory: _pickCategory,
            onMonth: _pickMonth,
            onReset: () => _applyFilter(const TransactionFilter()),
          ),
          Expanded(
            child: transactions.isEmpty
                ? _buildEmpty(effective)
                : _GroupedList(transactions: transactions),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(TransactionFilter effective) {
    if (effective.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'Операций пока нет',
        message: 'Запишите первый доход или расход.',
        actionLabel: 'Добавить операцию',
        onAction: () => context.push(AppRoutes.transactionNew),
      );
    }
    return EmptyState(
      icon: Icons.search_off,
      title: 'Ничего не найдено',
      message: 'Под выбранные фильтры не подходит ни одна операция.',
      actionLabel: 'Сбросить фильтры',
      onAction: _resetAll,
    );
  }
}

@immutable
class _Option<T> {
  const _Option({required this.label, required this.value, this.leading});

  final String label;
  final T? value;
  final Widget? leading;
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.filter,
    required this.onKind,
    required this.onCategory,
    required this.onMonth,
    required this.onReset,
  });

  final TransactionFilter filter;
  final VoidCallback onKind;
  final VoidCallback onCategory;
  final VoidCallback onMonth;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final kind = filter.kind;
    final category = filter.category;
    final month = filter.month;

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: Insets.pageHorizontal,
        children: [
          AppFilterChip(
            label: switch (kind) {
              null => 'Тип',
              TransactionKind.income => 'Доходы',
              TransactionKind.expense => 'Расходы',
            },
            icon: Icons.swap_vert,
            selected: kind != null,
            trailing: Icons.expand_more,
            onTap: onKind,
          ),
          const SizedBox(width: Insets.sm),
          AppFilterChip(
            label: category == null
                ? 'Категория'
                : CategoryCatalog.labelOf(category, kind: kind),
            icon: Icons.category_outlined,
            selected: category != null,
            trailing: Icons.expand_more,
            onTap: onCategory,
          ),
          const SizedBox(width: Insets.sm),
          AppFilterChip(
            label: month == null
                ? 'Период'
                : Formatters.monthTitle(DateTime.parse('$month-01')),
            icon: Icons.calendar_month_outlined,
            selected: month != null,
            trailing: Icons.expand_more,
            onTap: onMonth,
          ),
          if (filter.activeCount > 0) ...[
            const SizedBox(width: Insets.sm),
            AppFilterChip(label: 'Сбросить', icon: Icons.close, onTap: onReset),
          ],
        ],
      ),
    );
  }
}

class _GroupedList extends StatelessWidget {
  const _GroupedList({required this.transactions});

  /// Already sorted newest first.
  final List<MockTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    DateTime? currentDay;
    for (final transaction in transactions) {
      final local = transaction.date.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      if (day != currentDay) {
        currentDay = day;
        children.add(
          TransactionDateHeader(
            label: Formatters.dayHeader(day, today: mockToday),
          ),
        );
      }
      children.add(
        TransactionRow(
          transaction: transaction,
          accountName: findMockAccount(transaction.accountId)?.name,
          onTap: () => context.push(AppRoutes.transaction(transaction.id)),
        ),
      );
    }

    // Bottom padding keeps the last row clear of the floating button.
    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: children,
    );
  }
}
