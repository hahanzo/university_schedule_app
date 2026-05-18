import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/auth_validators.dart';
import '../blocs/auth_cubit.dart';
import '../blocs/auth_state.dart';
import 'auth_modal_shared.dart';
import 'forgot_password_modal.dart';
import 'sign_up_modal.dart';

class SignInModal extends StatefulWidget {
  const SignInModal({super.key});

  @override
  State<SignInModal> createState() => _SignInModalState();
}

class _SignInModalState extends State<SignInModal> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _emailController.text = AuthModalDrafts.signInEmail;
    _passwordController.text = AuthModalDrafts.signInPassword;
  }

  @override
  void dispose() {
    AuthModalDrafts.signInEmail = _emailController.text;
    AuthModalDrafts.signInPassword = _passwordController.text;
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    context.read<AuthCubit>().signIn(
      _emailController.text.trim(),
      _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        state.maybeWhen(
          authenticated: (_) {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
          error: (message) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(message)));
          },
          orElse: () {},
        );
      },
      child: AuthModalContainer(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sign In',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getAuthPrimaryColor(context),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Enter your details below',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              AuthTextField(
                hint: 'Email',
                controller: _emailController,
                keyboard: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (value) =>
                    AuthValidators.validateEmail(value, enforceDomain: true),
              ),
              AuthTextField(
                hint: 'Password',
                controller: _passwordController,
                obscure: true,
                textInputAction: TextInputAction.done,
                validator: AuthValidators.validateSignInPassword,
                onFieldSubmitted: (_) => _submit(),
              ),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    showAuthModal(context, const ForgotPasswordModal());
                  },
                  child: Text(
                    'Forgot password?',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.getAuthPrimaryColor(context),
                    foregroundColor: colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Sign In',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.surface,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Or sign in with',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 14),
              GoogleSignInButton(
                onPressed: () => context.read<AuthCubit>().signInWithGoogle(),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).pop();
                      showAuthModal(context, const SignUpModal());
                    },
                    child: Text(
                      'Create one!',
                      style: TextStyle(
                        color: AppTheme.getAuthPrimaryColor(context),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
