import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/auth_validators.dart';
import '../blocs/auth_cubit.dart';
import '../blocs/auth_state.dart';
import 'auth_modal_shared.dart';
import 'sign_in_modal.dart';

class ForgotPasswordModal extends StatefulWidget {
  const ForgotPasswordModal({super.key});

  @override
  State<ForgotPasswordModal> createState() => _ForgotPasswordModalState();
}

class _ForgotPasswordModalState extends State<ForgotPasswordModal> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _emailController.text = AuthModalDrafts.resetEmail;
  }

  @override
  void dispose() {
    AuthModalDrafts.resetEmail = _emailController.text;
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitError != null) {
      setState(() => _submitError = null);
    }
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final success = await context.read<AuthCubit>().resetPassword(
      _emailController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Instructions sent to email')),
      );
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        state.maybeWhen(
          error: (message) {
            if (!mounted) {
              return;
            }
            setState(() => _submitError = message);
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
                'Reset Password',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getAuthPrimaryColor(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your email to receive reset instructions',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              AuthTextField(
                hint: 'Email',
                controller: _emailController,
                keyboard: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                validator: (value) =>
                    AuthValidators.validateEmail(value, enforceDomain: true),
                onFieldSubmitted: (_) => _submit(),
                onChanged: (_) {
                  if (_submitError != null) {
                    setState(() => _submitError = null);
                  }
                },
              ),
              if (_submitError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _submitError!,
                    style: TextStyle(color: colorScheme.error, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 8),
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
                    'Send Instructions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.surface,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                  showAuthModal(context, const SignInModal());
                },
                child: Text(
                  'Back to Sign In',
                  style: TextStyle(
                    color: AppTheme.getAuthPrimaryColor(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
