import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/category_catalog.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/validation/validators.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/category_badge.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/selector_field.dart';

/// Create / edit form for a monthly budget: category, limit, month.
///
/// Besides the per-field rules it enforces the data model's uniqueness — one
/// budget per category and month — so the 409 the backend would return on L5
/// is caught before the request is ever sent.
class BudgetFormScreen extends StatefulWidget {
  const BudgetFormScreen({super.key, this.budget, this.initialMonth});

  /// `null` means "new budget".
  final MockBudget? budget;

  /// Month key `YYYY-MM` a new budget starts with — the month the budgets
  /// screen was showing.
  final String? initialMonth;

  @override
  State<BudgetFormScreen> createState() => _BudgetFormScreenState();
}

class _BudgetFormScreenState extends State<BudgetFormScreen> {
  final _categoryKey = GlobalKey<FormFieldState<String>>();

  late String? _category = widget.budget?.category;
  late final TextEditingController _limit = TextEditingController(
    text: widget.budget == null
        ? null
        : Formatters.amountInput(widget.budget!.limitAmount),
  );
  late String _month = _initialMonth;

  static const String _currency = MockUser.defaultCurrency;

  bool get _isEditing => widget.budget != null;

  String get _initialMonth {
    final requested = widget.budget?.month ?? widget.initialMonth;
    if (requested != null && DateTime.tryParse('$requested-01') != null) {
      return requested;
    }
    return Formatters.monthKey(mockToday);
  }

  /// `category|month` of every other budget.
  late final Set<String> _taken = {
    for (final budget in mockBudgets)
      if (budget.id != widget.budget?.id)
        Validators.budgetKey(budget.category, budget.month),
  };

  /// Months offered by the picker: two back, the current one, nine ahead.
  List<String> get _monthOptions {
    final base = DateTime(mockToday.year, mockToday.month);
    final options = [
      for (var offset = -2; offset <= 9; offset++)
        Formatters.monthKey(DateTime(base.year, base.month + offset)),
    ];
    // An edited budget may sit outside that window; keep its month pickable.
    if (!options.contains(_month)) {
      options.insert(0, _month);
    }
    return options;
  }

  @override
  void initState() {
    super.initState();
    _limit.addListener(_refresh);
  }

  @override
  void dispose() {
    _limit.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  String? _validateCategory(String? value) =>
      Validators.selected(value, 'Выберите категорию') ??
      Validators.budgetUnique(value, _month, taken: _taken);

  bool get _isValid =>
      _validateCategory(_category) == null &&
      Validators.budgetLimit(_limit.text) == null;

  bool get _hasChanges {
    final budget = widget.budget;
    if (budget == null) {
      return _category != null ||
          _limit.text.trim().isNotEmpty ||
          _month != _initialMonth;
    }
    return _category != budget.category ||
        _month != budget.month ||
        Validators.parseAmount(_limit.text) != budget.limitAmount;
  }

  Future<void> _pickCategory(FormFieldState<String> field) async {
    final picked = await showAppSheet<String>(
      context: context,
      title: 'Категория расходов',
      builder: (sheetContext) => ListView(
        shrinkWrap: true,
        children: [
          for (final category in CategoryCatalog.expenses)
            SheetOption(
              label: category.label,
              selected: category.key == _category,
              leading: CategoryAvatar(
                category: category.key,
                kind: TransactionKind.expense,
                size: 32,
              ),
              onTap: () => Navigator.of(sheetContext).pop(category.key),
            ),
        ],
      ),
    );
    if (picked != null) {
      setState(() => _category = picked);
      field.didChange(picked);
    }
  }

  Future<void> _pickMonth() async {
    final picked = await showAppSheet<String>(
      context: context,
      title: 'Месяц',
      builder: (sheetContext) => ListView(
        shrinkWrap: true,
        children: [
          for (final month in _monthOptions)
            SheetOption(
              label: _monthLabel(month),
              selected: month == _month,
              onTap: () => Navigator.of(sheetContext).pop(month),
            ),
        ],
      ),
    );
    if (picked != null) {
      setState(() => _month = picked);
      // Uniqueness depends on the month, so the category verdict may change.
      if (_category != null) {
        _categoryKey.currentState?.validate();
      }
    }
  }

  static String _monthLabel(String key) =>
      Formatters.monthTitle(DateTime.parse('$key-01'));

  void _close() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go(AppRoutes.budgets);
    }
  }

  void _save() {
    showAppToast(
      context,
      _isEditing ? 'Бюджет обновлён' : 'Бюджет создан',
      tone: ToastTone.success,
    );
    _close();
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Удалить бюджет?',
      message:
          'Лимит по категории «${CategoryCatalog.labelOf(widget.budget!.category)}» '
          'на ${_monthLabel(widget.budget!.month).toLowerCase()} будет удалён. '
          'Операции останутся.',
      confirmLabel: AppStrings.delete,
      destructive: true,
    );
    if (!confirmed || !mounted) {
      return;
    }
    showAppToast(context, 'Бюджет удалён');
    _close();
  }

  @override
  Widget build(BuildContext context) {
    final category = _category;

    return UnsavedChangesGuard(
      hasChanges: _hasChanges,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Изменить бюджет' : 'Новый бюджет'),
        ),
        // Each field validates itself once touched; a form-wide mode would
        // light up every untouched field as soon as the first one changes.
        body: Form(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              Insets.lg,
              Insets.lg,
              Insets.lg,
              Insets.xxl,
            ),
            children: [
              FormField<String>(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                key: _categoryKey,
                initialValue: _category,
                validator: _validateCategory,
                builder: (field) => SelectorField(
                  label: 'Категория',
                  value: category == null
                      ? null
                      : CategoryCatalog.labelOf(
                          category,
                          kind: TransactionKind.expense,
                        ),
                  placeholder: 'Выберите категорию',
                  leading: category == null
                      ? const Icon(Icons.category_outlined)
                      : CategoryAvatar(
                          category: category,
                          kind: TransactionKind.expense,
                          size: 32,
                        ),
                  errorText: field.errorText,
                  onTap: () => _pickCategory(field),
                ),
              ),
              const SizedBox(height: Insets.md),
              SelectorField(
                label: 'Месяц',
                value: _monthLabel(_month),
                leading: const Icon(Icons.calendar_month_outlined),
                onTap: _pickMonth,
              ),
              const SizedBox(height: Insets.lg),
              TextFormField(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                controller: _limit,
                validator: Validators.budgetLimit,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Лимит на месяц',
                  hintText: '1 000,00',
                  prefixIcon: const Icon(Icons.savings_outlined),
                  suffixText: Formatters.currencySymbol(_currency),
                ),
              ),
              const SizedBox(height: Insets.xl),
              PrimaryButton(
                label: AppStrings.save,
                onPressed: _isValid ? _save : null,
              ),
              if (_isEditing) ...[
                const SizedBox(height: Insets.md),
                DestructiveButton(
                  label: 'Удалить бюджет',
                  onPressed: _confirmDelete,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
