import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/state/app_session.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/validation/validators.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/confirm_dialog.dart';

/// User data, default currency, theme and sign-out.
///
/// The theme switch is live — it drives the app's [ThemeMode]. The name and
/// the currency change on screen only; they are persisted once the profile
/// has a repository (L4) and an endpoint (L5).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({required this.session, required this.theme, super.key});

  final AuthSession session;
  final ThemeController theme;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _displayName = MockUser.displayName;
  String _currency = MockUser.defaultCurrency;

  String get _initials {
    final parts = _displayName.trim().split(RegExp(r'\s+'));
    return parts
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
  }

  Future<void> _editName() async {
    final name = await showAppSheet<String>(
      context: context,
      title: 'Имя',
      builder: (_) => _NameForm(initial: _displayName),
    );
    if (name != null && name != _displayName && mounted) {
      setState(() => _displayName = name);
      showAppToast(context, 'Имя обновлено', tone: ToastTone.success);
    }
  }

  Future<void> _pickCurrency() async {
    final picked = await showAppSheet<String>(
      context: context,
      title: 'Валюта по умолчанию',
      builder: (sheetContext) => ListView(
        shrinkWrap: true,
        children: [
          for (final currency in Formatters.currencies)
            SheetOption(
              label: currency,
              selected: currency == _currency,
              trailing: Text(
                Formatters.currencySymbol(currency),
                style: sheetContext.texts.bodySmall,
              ),
              onTap: () => Navigator.of(sheetContext).pop(currency),
            ),
        ],
      ),
    );
    if (picked != null && picked != _currency) {
      setState(() => _currency = picked);
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showConfirmDialog(
      context,
      title: AppStrings.signOutTitle,
      message: AppStrings.signOutMessage,
      confirmLabel: AppStrings.signOut,
    );
    if (confirmed) {
      // The router's redirect sees the session change and opens /login.
      widget.session.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.navProfile)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Insets.lg,
          Insets.sm,
          Insets.lg,
          Insets.xxl,
        ),
        children: [
          AppCard(
            onTap: _editName,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: context.colors.primaryContainer,
                  foregroundColor: context.colors.onPrimaryContainer,
                  child: Text(_initials, style: context.texts.titleMedium),
                ),
                const SizedBox(width: Insets.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _displayName,
                        style: context.texts.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: Insets.xs),
                      Text(
                        MockUser.email,
                        style: context.texts.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.edit_outlined, color: context.semantic.textMuted),
              ],
            ),
          ),
          const SizedBox(height: Insets.lg),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: Insets.xs),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet_outlined),
                  title: const Text(AppStrings.accounts),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRoutes.accounts),
                ),
                ListTile(
                  leading: const Icon(Icons.currency_exchange),
                  title: const Text('Валюта по умолчанию'),
                  trailing: Text(_currency, style: context.texts.bodyMedium),
                  onTap: _pickCurrency,
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.lg),
          AppCard(
            title: 'Тема',
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: widget.theme,
              builder: (context, mode, _) => SizedBox(
                width: double.infinity,
                child: SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text('Система'),
                      icon: Icon(Icons.brightness_auto_outlined),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: Text('Светлая'),
                      icon: Icon(Icons.light_mode_outlined),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text('Тёмная'),
                      icon: Icon(Icons.dark_mode_outlined),
                    ),
                  ],
                  selected: {mode},
                  showSelectedIcon: false,
                  onSelectionChanged: (selection) =>
                      widget.theme.value = selection.single,
                ),
              ),
            ),
          ),
          const SizedBox(height: Insets.xl),
          DestructiveButton(
            label: AppStrings.signOut,
            icon: Icons.logout,
            onPressed: _signOut,
          ),
        ],
      ),
    );
  }
}

/// Name editor inside a bottom sheet. Pops the trimmed name on save.
class _NameForm extends StatefulWidget {
  const _NameForm({required this.initial});

  final String initial;

  @override
  State<_NameForm> createState() => _NameFormState();
}

class _NameFormState extends State<_NameForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(_name.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Lifts the form above the on-screen keyboard.
      padding: EdgeInsets.fromLTRB(
        Insets.lg,
        Insets.sm,
        Insets.lg,
        Insets.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _name,
              validator: Validators.displayName,
              autofocus: true,
              maxLength: Validators.displayNameMaxLength,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _save(),
              decoration: const InputDecoration(
                labelText: AppStrings.displayName,
                hintText: AppStrings.displayNameHint,
                prefixIcon: Icon(Icons.person_outline),
                counterText: '',
              ),
            ),
            const SizedBox(height: Insets.lg),
            PrimaryButton(label: AppStrings.save, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
