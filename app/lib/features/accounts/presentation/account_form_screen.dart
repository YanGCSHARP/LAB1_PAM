import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/validation/validators.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/confirm_dialog.dart';

/// Create / edit form for an account.
///
/// Fields are validated as they are edited and "Сохранить" stays disabled
/// until the form is valid. Nothing is persisted yet — the mock data is
/// read-only until the repositories of L4.
class AccountFormScreen extends StatefulWidget {
  const AccountFormScreen({super.key, this.account});

  /// `null` means "new account".
  final MockAccount? account;

  @override
  State<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends State<AccountFormScreen> {
  late final TextEditingController _name = TextEditingController(
    text: widget.account?.name,
  );
  late final TextEditingController _balance = TextEditingController(
    text: widget.account == null
        ? null
        : Formatters.amountInput(widget.account!.balance),
  );
  late String _currency =
      widget.account?.currency ?? Formatters.currencies.first;

  bool get _isEditing => widget.account != null;

  /// Names of the user's other accounts — a name must be unique among them.
  late final List<String> _takenNames = [
    for (final account in mockAccounts)
      if (account.id != widget.account?.id) account.name,
  ];

  @override
  void initState() {
    super.initState();
    _name.addListener(_refresh);
    _balance.addListener(_refresh);
  }

  @override
  void dispose() {
    _name.dispose();
    _balance.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  String? _validateName(String? value) =>
      Validators.accountName(value, takenNames: _takenNames);

  bool get _isValid =>
      _validateName(_name.text) == null &&
      Validators.openingBalance(_balance.text) == null;

  bool get _hasChanges {
    final account = widget.account;
    if (account == null) {
      return _name.text.trim().isNotEmpty ||
          _balance.text.trim().isNotEmpty ||
          _currency != Formatters.currencies.first;
    }
    return _name.text.trim() != account.name ||
        _currency != account.currency ||
        (Validators.parseAmount(_balance.text) ?? 0) != account.balance;
  }

  void _save() {
    showAppToast(
      context,
      _isEditing ? 'Счёт обновлён' : 'Счёт создан',
      tone: ToastTone.success,
    );
    Navigator.of(context).pop();
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Удалить счёт?',
      message:
          'Вместе со счётом «${widget.account!.name}» будут удалены все его '
          'транзакции. Действие нельзя отменить.',
      confirmLabel: AppStrings.delete,
      destructive: true,
    );
    if (!confirmed || !mounted) {
      return;
    }
    showAppToast(context, 'Счёт удалён');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return UnsavedChangesGuard(
      hasChanges: _hasChanges,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Изменить счёт' : 'Новый счёт'),
        ),
        // Each field validates itself once touched; a form-wide mode would
        // light up every untouched field as soon as the first one changes.
        body: Form(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              TextFormField(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                controller: _name,
                validator: _validateName,
                maxLength: Validators.accountNameMaxLength,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Название',
                  hintText: 'Например, Карта Maib',
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _currency,
                decoration: const InputDecoration(
                  labelText: 'Валюта',
                  prefixIcon: Icon(Icons.currency_exchange),
                ),
                items: [
                  for (final currency in Formatters.currencies)
                    DropdownMenuItem(value: currency, child: Text(currency)),
                ],
                onChanged: (value) => setState(() => _currency = value!),
              ),
              const SizedBox(height: 14),
              TextFormField(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                controller: _balance,
                validator: Validators.openingBalance,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Начальный баланс',
                  hintText: '0,00',
                  helperText: 'Можно оставить пустым — будет 0',
                  prefixIcon: const Icon(Icons.numbers),
                  suffixText: Formatters.currencySymbol(_currency),
                ),
              ),
              const SizedBox(height: 28),
              PrimaryButton(
                label: AppStrings.save,
                onPressed: _isValid ? _save : null,
              ),
              if (_isEditing) ...[
                const SizedBox(height: 12),
                DestructiveButton(
                  label: 'Удалить счёт',
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
