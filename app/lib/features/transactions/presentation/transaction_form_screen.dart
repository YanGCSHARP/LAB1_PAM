import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/state/clock.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/category_catalog.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/validation/validators.dart';
import '../../../core/widgets/account_card.dart';
import '../../../core/widgets/amount_field.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/category_badge.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/repository_action.dart';
import '../../../core/widgets/selector_field.dart';
import '../../../core/widgets/type_switch.dart';
import '../../accounts/domain/account.dart';
import '../application/transactions_providers.dart';
import '../domain/transaction.dart';

/// Create / edit form for an operation.
///
/// Every field is validated as it is edited, "Сохранить" stays disabled while
/// anything is invalid, and leaving with unsaved edits asks first. The picker
/// fields are [FormField]s too, so their errors render the same way as a text
/// field's.
class TransactionFormScreen extends ConsumerStatefulWidget {
  const TransactionFormScreen({
    required this.accounts,
    super.key,
    this.transaction,
  });

  /// Accounts the operation can be recorded on.
  final List<Account> accounts;

  /// `null` means "new operation".
  final Transaction? transaction;

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  final _categoryKey = GlobalKey<FormFieldState<String>>();

  late final Transaction? _initial = widget.transaction;

  late TransactionKind _kind = _initial?.kind ?? TransactionKind.expense;
  late final TextEditingController _amount = TextEditingController(
    text: _initial == null ? null : Formatters.amountInput(_initial.amount),
  );
  late String? _category = _initial?.category;
  late String? _accountId = _initial?.accountId ?? _defaultAccountId;
  late DateTime? _date = _initialDate;
  late final TextEditingController _note = TextEditingController(
    text: _initial?.note,
  );

  /// A save is in flight.
  bool _saving = false;

  bool get _isEditing => _initial != null;

  /// A new operation goes to the first account unless another is picked.
  String? get _defaultAccountId => widget.accounts.firstOrNull?.id;

  DateTime get _initialDate {
    final DateTime source =
        _initial?.date.toLocal() ?? ref.read<DateTime>(todayProvider);
    return DateTime(source.year, source.month, source.day);
  }

  Account? _accountById(String? id) =>
      widget.accounts.where((account) => account.id == id).firstOrNull;

  @override
  void initState() {
    super.initState();
    _amount.addListener(_refresh);
    _note.addListener(_refresh);
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  String get _currency => _accountById(_accountId)?.currency ?? '';

  String? _validateCategory(String? value) =>
      Validators.selected(value, 'Выберите категорию');

  String? _validateAccount(String? value) =>
      Validators.selected(value, 'Выберите счёт');

  bool get _isValid =>
      Validators.amount(_amount.text) == null &&
      _validateCategory(_category) == null &&
      _validateAccount(_accountId) == null &&
      Validators.transactionDate(_date) == null &&
      Validators.note(_note.text) == null;

  bool get _hasChanges {
    final initial = _initial;
    final note = _note.text.trim();
    if (initial == null) {
      return _amount.text.trim().isNotEmpty ||
          _category != null ||
          note.isNotEmpty ||
          _kind != TransactionKind.expense ||
          _accountId != _defaultAccountId ||
          _date != _initialDate;
    }
    return Validators.parseAmount(_amount.text) != initial.amount ||
        _kind != initial.kind ||
        _category != initial.category ||
        _accountId != initial.accountId ||
        _date != _initialDate ||
        note != (initial.note ?? '');
  }

  void _changeKind(TransactionKind kind) {
    setState(() => _kind = kind);
    // Categories are per direction; one that does not exist on the other
    // side is cleared, and the field immediately says why save is disabled.
    final category = _category;
    if (category != null &&
        !CategoryCatalog.forKind(kind).any((c) => c.key == category)) {
      setState(() => _category = null);
      _categoryKey.currentState?.didChange(null);
    }
  }

  Future<void> _pickCategory(FormFieldState<String> field) async {
    final picked = await showAppSheet<String>(
      context: context,
      title: 'Категория',
      builder: (sheetContext) => ListView(
        shrinkWrap: true,
        children: [
          for (final category in CategoryCatalog.forKind(_kind))
            SheetOption(
              label: category.label,
              selected: category.key == _category,
              leading: CategoryAvatar(
                category: category.key,
                kind: category.kind,
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

  Future<void> _pickAccount(FormFieldState<String> field) async {
    final picked = await showAppSheet<String>(
      context: context,
      title: 'Счёт',
      builder: (sheetContext) => ListView(
        shrinkWrap: true,
        children: [
          for (final account in widget.accounts)
            SheetOption(
              label: account.name,
              selected: account.id == _accountId,
              leading: Icon(accountVisual(sheetContext, account.kind).icon),
              trailing: Text(
                account.currency,
                style: sheetContext.texts.bodySmall,
              ),
              onTap: () => Navigator.of(sheetContext).pop(account.id),
            ),
        ],
      ),
    );
    if (picked != null) {
      setState(() => _accountId = picked);
      field.didChange(picked);
    }
  }

  Future<void> _pickDate(FormFieldState<DateTime> field) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(2000),
      // The validator allows tomorrow; the picker allows exactly the same.
      lastDate: DateTime(now.year, now.month, now.day + 1),
    );
    if (picked != null) {
      setState(() => _date = picked);
      field.didChange(picked);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final transactions = ref.read(transactionsProvider.notifier);
    final initial = _initial;
    final amount = Validators.parseAmount(_amount.text)!;
    final note = _note.text.trim();
    // The picked day keeps the original time of an edited operation; a new
    // one gets the current time, so operations of one day stay in order.
    final time = initial?.date.toLocal() ?? DateTime.now();
    final day = _date!;
    final date = DateTime(
      day.year,
      day.month,
      day.day,
      time.hour,
      time.minute,
    ).toUtc();

    final saved = await runRepositoryAction(context, () async {
      if (initial == null) {
        await transactions.add(
          accountId: _accountId!,
          amount: amount,
          kind: _kind,
          category: _category!,
          date: date,
          note: note.isEmpty ? null : note,
        );
      } else {
        await transactions.save(
          initial.copyWith(
            accountId: _accountId,
            amount: amount,
            kind: _kind,
            category: _category,
            date: date,
            note: () => note.isEmpty ? null : note,
          ),
        );
      }
    });
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    if (!saved) {
      return;
    }
    showAppToast(
      context,
      _isEditing ? 'Изменения сохранены' : 'Операция добавлена',
      tone: ToastTone.success,
    );
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go(AppRoutes.transactions);
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = _category;

    return UnsavedChangesGuard(
      hasChanges: _hasChanges,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Изменить операцию' : 'Новая операция'),
        ),
        // Each field validates itself once touched; a form-wide mode would
        // light up every untouched field as soon as the first one changes.
        body: Form(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              Insets.lg,
              Insets.sm,
              Insets.lg,
              Insets.xxl,
            ),
            children: [
              TypeSwitch(value: _kind, onChanged: _changeKind),
              const SizedBox(height: Insets.lg),
              FormField<String>(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                initialValue: _amount.text,
                validator: (_) => Validators.amount(_amount.text),
                builder: (field) => AmountField(
                  controller: _amount,
                  currency: _currency,
                  isIncome: _kind == TransactionKind.income,
                  autofocus: !_isEditing,
                  errorText: field.errorText,
                  onChanged: field.didChange,
                ),
              ),
              const SizedBox(height: Insets.lg),
              FormField<String>(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                key: _categoryKey,
                initialValue: _category,
                validator: _validateCategory,
                builder: (field) => SelectorField(
                  label: 'Категория',
                  value: category == null
                      ? null
                      : CategoryCatalog.labelOf(category, kind: _kind),
                  placeholder: 'Выберите категорию',
                  leading: category == null
                      ? const Icon(Icons.category_outlined)
                      : CategoryAvatar(
                          category: category,
                          kind: _kind,
                          size: 32,
                        ),
                  errorText: field.errorText,
                  onTap: () => _pickCategory(field),
                ),
              ),
              const SizedBox(height: Insets.md),
              FormField<String>(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                initialValue: _accountId,
                validator: _validateAccount,
                builder: (field) {
                  final account = _accountById(_accountId);
                  return SelectorField(
                    label: 'Счёт',
                    value: account == null
                        ? null
                        : '${account.name} · ${account.currency}',
                    placeholder: 'Выберите счёт',
                    leading: Icon(
                      account == null
                          ? Icons.account_balance_wallet_outlined
                          : accountVisual(context, account.kind).icon,
                    ),
                    errorText: field.errorText,
                    onTap: () => _pickAccount(field),
                  );
                },
              ),
              const SizedBox(height: Insets.md),
              FormField<DateTime>(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                initialValue: _date,
                validator: (value) => Validators.transactionDate(value),
                builder: (field) => SelectorField(
                  label: 'Дата',
                  value: _date == null ? null : Formatters.fullDate(_date!),
                  placeholder: 'Выберите дату',
                  leading: const Icon(Icons.event_outlined),
                  errorText: field.errorText,
                  onTap: () => _pickDate(field),
                ),
              ),
              const SizedBox(height: Insets.lg),
              TextFormField(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                controller: _note,
                validator: Validators.note,
                maxLength: Validators.noteMaxLength,
                maxLines: 3,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Заметка',
                  hintText: 'Например, продукты в Linella',
                  prefixIcon: Icon(Icons.notes),
                ),
              ),
              const SizedBox(height: Insets.xl),
              PrimaryButton(
                label: AppStrings.save,
                loading: _saving,
                onPressed: _isValid ? _save : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
