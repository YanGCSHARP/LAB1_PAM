import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/repository_exception.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/validation/validators.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_toast.dart';
import 'widgets/auth_header.dart';
import 'widgets/auth_switch_link.dart';

/// Sign-in screen.
///
/// The form is validated on the client, the credentials by the server.
/// Navigation after sign-in is the router's job: [onSignIn] starts the
/// session and the redirect moves the user to the dashboard. A wrong
/// password or a missing network is reported in a toast; the form keeps
/// what was typed.
class LoginScreen extends StatefulWidget {
  const LoginScreen({required this.onSignIn, super.key});

  final Future<void> Function({required String email, required String password})
  onSignIn;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  /// Errors appear only after the first submit attempt — a form that turns
  /// red while the person is still typing their email is hostile.
  bool _submitted = false;

  /// A request is in flight: the button shows a spinner and ignores taps.
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (_busy || !_formKey.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      await widget.onSignIn(
        email: _email.text.trim(),
        password: _password.text,
      );
    } on RepositoryException catch (error) {
      if (mounted) {
        showAppToast(context, error.message, tone: ToastTone.error);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
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
                        title: AppStrings.loginTitle,
                        subtitle: AppStrings.loginSubtitle,
                      ),
                      const SizedBox(height: 28),
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
                        validator: Validators.loginPassword,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => showAppToast(
                            context,
                            AppStrings.forgotPasswordUnavailable,
                          ),
                          child: const Text(AppStrings.forgotPassword),
                        ),
                      ),
                      const SizedBox(height: 10),
                      PrimaryButton(
                        label: AppStrings.signIn,
                        loading: _busy,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 20),
                      AuthSwitchLink(
                        prompt: AppStrings.noAccountYet,
                        action: AppStrings.signUpAction,
                        onTap: () => context.push(AppRoutes.register),
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
