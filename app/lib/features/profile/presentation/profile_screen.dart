import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/mock/mock_providers.dart';
import '../../../core/l10n/app_strings.dart';
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
import '../../../core/widgets/async_views.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/repository_action.dart';
import '../../../core/widgets/skeleton.dart';
import '../application/profile_providers.dart';
import '../domain/user_profile.dart';

/// User data, default currency, theme and sign-out.
///
/// The name and the currency are saved through the profile repository; the
/// currency also re-computes the dashboard and the budgets, which count only
/// accounts in it. The theme is applied at once and kept for the session.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _editName(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) async {
    final name = await showAppSheet<String>(
      context: context,
      title: 'Имя',
      builder: (_) => _NameForm(initial: profile.displayName),
    );
    if (name == null || name == profile.displayName || !context.mounted) {
      return;
    }
    final saved = await runRepositoryAction(
      context,
      () => ref.read(profileProvider.notifier).rename(name),
    );
    if (saved && context.mounted) {
      showAppToast(context, 'Имя обновлено', tone: ToastTone.success);
    }
  }

  Future<void> _pickCurrency(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) async {
    final picked = await showAppSheet<String>(
      context: context,
      title: 'Валюта по умолчанию',
      builder: (sheetContext) => ListView(
        shrinkWrap: true,
        children: [
          for (final currency in Formatters.currencies)
            SheetOption(
              label: currency,
              selected: currency == profile.defaultCurrency,
              trailing: Text(
                Formatters.currencySymbol(currency),
                style: sheetContext.texts.bodySmall,
              ),
              onTap: () => Navigator.of(sheetContext).pop(currency),
            ),
        ],
      ),
    );
    if (picked == null ||
        picked == profile.defaultCurrency ||
        !context.mounted) {
      return;
    }
    await runRepositoryAction(
      context,
      () => ref.read(profileProvider.notifier).changeCurrency(picked),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: AppStrings.signOutTitle,
      message: AppStrings.signOutMessage,
      confirmLabel: AppStrings.signOut,
    );
    if (confirmed) {
      // The router's redirect sees the session change and opens /login.
      ref.read(authSessionProvider).signOut();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

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
          AsyncValueView(
            value: profile,
            loading: const CardSkeleton(height: 168),
            data: (profile) => Column(
              children: [
                AppCard(
                  onTap: () => _editName(context, ref, profile),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: context.colors.primaryContainer,
                        foregroundColor: context.colors.onPrimaryContainer,
                        child: Text(
                          profile.initials,
                          style: context.texts.titleMedium,
                        ),
                      ),
                      const SizedBox(width: Insets.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.displayName,
                              style: context.texts.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: Insets.xs),
                            Text(
                              profile.email,
                              style: context.texts.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.edit_outlined,
                        color: context.semantic.textMuted,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Insets.lg),
                AppCard(
                  padding: const EdgeInsets.symmetric(vertical: Insets.xs),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.account_balance_wallet_outlined,
                        ),
                        title: const Text(AppStrings.accounts),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(AppRoutes.accounts),
                      ),
                      ListTile(
                        leading: const Icon(Icons.currency_exchange),
                        title: const Text('Валюта по умолчанию'),
                        trailing: Text(
                          profile.defaultCurrency,
                          style: context.texts.bodyMedium,
                        ),
                        onTap: () => _pickCurrency(context, ref, profile),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.lg),
          AppCard(
            title: 'Тема',
            child: SizedBox(
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
                selected: {ref.watch(themeModeProvider)},
                showSelectedIcon: false,
                onSelectionChanged: (selection) => ref
                    .read(themeModeProvider.notifier)
                    .select(selection.single),
              ),
            ),
          ),
          // Lets a demo show the error states without pulling the cable.
          // Debug builds only; it goes away with the mock backend on L5.
          if (kDebugMode) ...[
            const SizedBox(height: Insets.lg),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: Insets.xs),
              child: SwitchListTile(
                secondary: const Icon(Icons.wifi_off_outlined),
                title: const Text('Имитировать сбой сети'),
                subtitle: const Text(
                  'Для разработчика: запросы к данным будут падать',
                ),
                value: ref.watch(simulateOfflineProvider),
                onChanged: (offline) => ref
                    .read(simulateOfflineProvider.notifier)
                    .set(offline: offline),
              ),
            ),
          ],
          const SizedBox(height: Insets.xl),
          DestructiveButton(
            label: AppStrings.signOut,
            icon: Icons.logout,
            onPressed: () => _signOut(context, ref),
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
