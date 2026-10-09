import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/mock/mock_data.dart';

/// Create / edit form for an account.
///
/// Static at this stage: the fields are pre-filled when editing, "Сохранить"
/// only reports success. Validation comes with the forms stage.
class AccountFormScreen extends StatelessWidget {
  const AccountFormScreen({super.key, this.account});

  /// `null` means "new account".
  final MockAccount? account;

  static const List<String> _currencies = ['MDL', 'EUR', 'USD'];

  bool get _isEditing => account != null;

  void _save(BuildContext context) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isEditing ? 'Счёт обновлён' : 'Счёт создан')),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удалить счёт?'),
        content: Text(
          'Вместе со счётом «${account!.name}» будут удалены все его '
          'транзакции. Действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Счёт удалён')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Изменить счёт' : 'Новый счёт')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          TextField(
            controller: TextEditingController(text: account?.name),
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Название',
              hintText: 'Например, Карта Maib',
              prefixIcon: Icon(Icons.account_balance_wallet_outlined),
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: account?.currency ?? _currencies.first,
            decoration: const InputDecoration(
              labelText: 'Валюта',
              prefixIcon: Icon(Icons.currency_exchange),
            ),
            items: [
              for (final currency in _currencies)
                DropdownMenuItem(value: currency, child: Text(currency)),
            ],
            onChanged: (_) {},
          ),
          const SizedBox(height: 14),
          TextField(
            controller: TextEditingController(
              text: account?.balance.toStringAsFixed(2),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Начальный баланс',
              hintText: '0,00',
              prefixIcon: Icon(Icons.numbers),
            ),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: () => _save(context),
            child: const Text(AppStrings.save),
          ),
          if (_isEditing) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _confirmDelete(context),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Удалить счёт'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
