import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../home/presentation/home_shell.dart';
import 'register_screen.dart';
import 'widgets/auth_header.dart';

/// Sign-in screen.
///
/// Stage L2 is static UI: the fields accept anything, "Войти" simply opens the
/// main shell. Validation arrives with the forms stage, real authentication
/// with the backend stage.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _openApp(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomeShell()),
    );
  }

  void _openRegister(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const RegisterScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AuthHeader(
                    title: AppStrings.loginTitle,
                    subtitle: AppStrings.loginSubtitle,
                  ),
                  const SizedBox(height: 28),
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
                  const PasswordField(label: AppStrings.password),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text(AppStrings.forgotPassword),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton(
                    onPressed: () => _openApp(context),
                    child: const Text(AppStrings.signIn),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        AppStrings.noAccountYet,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _openRegister(context),
                        child: Text(
                          AppStrings.signUpAction,
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
