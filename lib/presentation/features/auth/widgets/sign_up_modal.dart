import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/auth_validators.dart';
import '../blocs/auth_cubit.dart';
import '../blocs/auth_state.dart';
import 'auth_modal_shared.dart';
import 'sign_in_modal.dart';

class SignUpModal extends StatefulWidget {
  const SignUpModal({super.key});

  @override
  State<SignUpModal> createState() => _SignUpModalState();
}

class _SignUpModalState extends State<SignUpModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = AuthModalDrafts.signUpName;
    _emailController.text = AuthModalDrafts.signUpEmail;
    _passwordController.text = AuthModalDrafts.signUpPassword;
  }

  @override
  void dispose() {
    AuthModalDrafts.signUpName = _nameController.text;
    AuthModalDrafts.signUpEmail = _emailController.text;
    AuthModalDrafts.signUpPassword = _passwordController.text;
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    context.read<AuthCubit>().signUp(
      _nameController.text.trim(),
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
                'Sign Up',
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
                hint: 'Full Name',
                controller: _nameController,
                textInputAction: TextInputAction.next,
                validator: AuthValidators.validateName,
              ),
              AuthTextField(
                hint: 'Email (@nltu.lviv.ua or @nltu.edu.ua)',
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
                validator: AuthValidators.validatePassword,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 6),
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
                    'Sign Up',
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
                'Or sign up with',
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
                    'Already have an account? ',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).pop();
                      showAuthModal(context, const SignInModal());
                    },
                    child: Text(
                      'Sign In!',
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
