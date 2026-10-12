import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/validation/validators.dart';
import 'widgets/auth_header.dart';
import 'widgets/auth_switch_link.dart';

/// Sign-up screen.
///
/// Validates name, email, password strength and the confirmation. No account
/// is stored until the backend stage — [onRegistered] signs the session in and
/// the router takes the user to the dashboard.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({required this.onRegistered, super.key});

  final VoidCallback onRegistered;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _submitted = true);
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      widget.onRegistered();
    }
  }

  void _openLogin() {
    // Normally the login screen is right underneath; after a deep link to
    // /register it is not, so fall back to navigating there.
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                autovalidateMode: _submitted
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AuthHeader(
                        title: AppStrings.registerTitle,
                        subtitle: AppStrings.registerSubtitle,
                      ),
                      const SizedBox(height: 28),
                      TextFormField(
                        controller: _name,
                        validator: Validators.displayName,
                        maxLength: Validators.displayNameMaxLength,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                        decoration: const InputDecoration(
                          labelText: AppStrings.displayName,
                          hintText: AppStrings.displayNameHint,
                          prefixIcon: Icon(Icons.person_outline),
                          // The limit is 100 — a counter would be noise.
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _email,
                        validator: Validators.email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: AppStrings.email,
                          hintText: AppStrings.emailHint,
                          prefixIcon: Icon(Icons.alternate_email),
                        ),
                      ),
                      const SizedBox(height: 14),
                      PasswordField(
                        label: AppStrings.password,
                        controller: _password,
                        validator: Validators.newPassword,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.newPassword],
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'Минимум ${Validators.passwordMinLength} символов, '
                          'буквы и цифры',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      const SizedBox(height: 14),
                      PasswordField(
                        label: AppStrings.passwordConfirm,
                        controller: _confirmation,
                        validator: (value) => Validators.passwordConfirmation(
                          value,
                          _password.text,
                        ),
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _submit,
                        child: const Text(AppStrings.signUp),
                      ),
                      const SizedBox(height: 20),
                      AuthSwitchLink(
                        prompt: AppStrings.alreadyHaveAccount,
                        action: AppStrings.signInAction,
                        onTap: _openLogin,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
