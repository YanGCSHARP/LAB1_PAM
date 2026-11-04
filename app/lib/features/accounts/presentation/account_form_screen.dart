import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/validation/validators.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/repository_action.dart';
import '../application/accounts_providers.dart';
import '../domain/account.dart';

/// Create / edit form for an account.
///
/// Fields are validated as they are edited and "Сохранить" stays disabled
/// until the form is valid. The opening balance is set once, at creation —
/// afterwards the balance follows the operations (`PUT /accounts/{id}` takes
/// only the name and the currency).
class AccountFormScreen extends ConsumerStatefulWidget {
  const AccountFormScreen({
    required this.accounts,
    super.key,
    this.account,
    this.operationCount = 0,
  });

  /// Every account of the user, for the unique-name check.
  final List<Account> accounts;

  /// `null` means "new account".
  final Account? account;

  /// Operations on [account] — deleted together with it.
  final int operationCount;

  @override
  ConsumerState<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends ConsumerState<AccountFormScreen> {
  late final Account? _initial = widget.account;

  late final TextEditingController _name = TextEditingController(
    text: _initial?.name,
  );
  final TextEditingController _balance = TextEditingController();
  late String _currency = _initial?.currency ?? Formatters.currencies.first;
  late AccountKind _kind = _initial?.kind ?? AccountKind.card;

  /// A save or a delete is in flight.
  bool _busy = false;

  bool get _isEditing => _initial != null;

  /// Names of the user's other accounts — a name must be unique among them.
  late final List<String> _takenNames = [
    for (final account in widget.accounts)
      if (account.id != _initial?.id) account.name,
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
    final account = _initial;
    if (account == null) {
      return _name.text.trim().isNotEmpty ||
          _balance.text.trim().isNotEmpty ||
          _currency != Formatters.currencies.first ||
          _kind != AccountKind.card;
    }
    return _name.text.trim() != account.name ||
        _currency != account.currency ||
        _kind != account.kind;
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final accounts = ref.read(accountsProvider.notifier);
    final initial = _initial;
    final saved = await runRepositoryAction(context, () async {
      if (initial == null) {
        await accounts.create(
          name: _name.text.trim(),
          currency: _currency,
          kind: _kind,
          openingBalance: Validators.parseAmount(_balance.text) ?? 0,
        );
      } else {
        await accounts.save(
          initial.copyWith(
            name: _name.text.trim(),
            currency: _currency,
            kind: _kind,
          ),
        );
      }
    });
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    if (saved) {
      showAppToast(
        context,
        _isEditing ? 'Счёт обновлён' : 'Счёт создан',
        tone: ToastTone.success,
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _confirmDelete() async {
    final account = _initial!;
    final count = widget.operationCount;
    final operations = count == 0
        ? 'Операций по счёту нет.'
        : 'Вместе с ним будут удалены $count '
              '${Formatters.plural(count, 'операция', 'операции', 'операций')}.';
    final confirmed = await showConfirmDialog(
      context,
      title: 'Удалить счёт?',
      message:
          'Счёт «${account.name}» будет удалён. $operations '
          'Действие нельзя отменить.',
      confirmLabel: AppStrings.delete,
      destructive: true,
    );
    if (!confirmed || !mounted) {
      return;
    }
    setState(() => _busy = true);
    final deleted = await runRepositoryAction(
      context,
      () => ref.read(accountsProvider.notifier).delete(account.id),
    );
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    if (deleted) {
      showAppToast(context, 'Счёт удалён');
      Navigator.of(context).pop();
    }
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
              SegmentedButton<AccountKind>(
                segments: const [
                  ButtonSegment(
                    value: AccountKind.card,
                    label: Text('Карта'),
                    icon: Icon(Icons.credit_card),
                  ),
                  ButtonSegment(
                    value: AccountKind.cash,
                    label: Text('Наличные'),
                    icon: Icon(Icons.payments_outlined),
                  ),
                  ButtonSegment(
                    value: AccountKind.savings,
                    label: Text('Вклад'),
                    icon: Icon(Icons.savings_outlined),
                  ),
                ],
                selected: {_kind},
                showSelectedIcon: false,
                onSelectionChanged: (selection) =>
                    setState(() => _kind = selection.single),
              ),
              const SizedBox(height: 20),
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
              if (!_isEditing) ...[
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
              ],
              const SizedBox(height: 28),
              PrimaryButton(
                label: AppStrings.save,
                loading: _busy,
                onPressed: _isValid ? _save : null,
              ),
              if (_isEditing) ...[
                const SizedBox(height: 12),
                DestructiveButton(
                  label: 'Удалить счёт',
                  onPressed: _busy ? null : _confirmDelete,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
