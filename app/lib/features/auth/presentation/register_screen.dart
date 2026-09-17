import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../home/presentation/home_shell.dart';
import 'widgets/auth_header.dart';

/// Sign-up screen. Like the login screen, it is static at this stage:
/// no validation, no account is actually created.
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  void _openApp(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const HomeShell()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AuthHeader(
                    title: AppStrings.registerTitle,
                    subtitle: AppStrings.registerSubtitle,
                  ),
                  const SizedBox(height: 28),
                  const TextField(
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: AppStrings.displayName,
                      hintText: AppStrings.displayNameHint,
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const TextField(
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: AppStrings.email,
                      hintText: AppStrings.emailHint,
                      prefixIcon: Icon(Icons.alternate_email),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const PasswordField(
                    label: AppStrings.password,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  const PasswordField(label: AppStrings.passwordConfirm),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => _openApp(context),
                    child: const Text(AppStrings.signUp),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        AppStrings.alreadyHaveAccount,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Text(
                          AppStrings.signInAction,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
