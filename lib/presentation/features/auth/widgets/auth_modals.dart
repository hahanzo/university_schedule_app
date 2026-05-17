import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/utils/auth_validators.dart';
import '../blocs/auth_cubit.dart';
import '../blocs/auth_state.dart';

// --- Shared Widgets ---
class CustomTextField extends StatelessWidget {
  final String hintText;
  final bool obscureText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;

  const CustomTextField({
    super.key,
    required this.hintText,
    this.obscureText = false,
    this.controller,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E7DE),
        borderRadius: BorderRadius.circular(4),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: InputBorder.none,
        ),
        // Show hintText as a label above field when focused
        // We use it as hint for simplicity
        style: const TextStyle(fontSize: 15),
      ),
    );
  }

  Widget withHint(String hint) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E7DE),
        borderRadius: BorderRadius.circular(4),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: InputBorder.none,
        ),
        style: const TextStyle(fontSize: 15),
      ),
    );
  }
}

// Simpler version that just wraps with hint
Widget _textField({
  required String hint,
  required TextEditingController controller,
  bool obscure = false,
  TextInputType? keyboard,
  String? Function(String?)? validator,
  TextInputAction? textInputAction,
  void Function(String)? onFieldSubmitted,
  void Function(String)? onChanged,
  AutovalidateMode? autovalidateMode,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 14),
    decoration: BoxDecoration(
      color: const Color(0xFFE2E7DE),
      borderRadius: BorderRadius.circular(4),
    ),
    child: TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      onChanged: onChanged,
      validator: validator,
      autovalidateMode: autovalidateMode ?? AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF777777)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: InputBorder.none,
        errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
      ),
      style: const TextStyle(fontSize: 15),
    ),
  );
}

// --- Modal wrapper helper ---
void _openModal(BuildContext context, Widget child) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => child,
  );
}

class _AuthModalDrafts {
  static String signInEmail = '';
  static String signInPassword = '';
  static String signUpName = '';
  static String signUpEmail = '';
  static String signUpPassword = '';
  static String resetEmail = '';
}

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;
  const GoogleSignInButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF3C6E47)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/images/material-icon-theme_google.svg',
              height: 22,
              width: 22,
            ),
            const SizedBox(width: 10),
            const Text(
              'Continue with Google',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Sign In Modal ---
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
    _emailController.text = _AuthModalDrafts.signInEmail;
    _passwordController.text = _AuthModalDrafts.signInPassword;
  }

  @override
  void dispose() {
    _AuthModalDrafts.signInEmail = _emailController.text;
    _AuthModalDrafts.signInPassword = _passwordController.text;
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
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Sign In',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C5E3B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Enter your details below',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  _textField(
                    hint: 'Email',
                    controller: _emailController,
                    keyboard: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (value) => AuthValidators.validateEmail(
                      value,
                      enforceDomain: true,
                    ),
                  ),
                  _textField(
                    hint: 'Password',
                    controller: _passwordController,
                    obscure: true,
                    textInputAction: TextInputAction.done,
                    validator: AuthValidators.validateSignInPassword,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  // Forgot password — centered
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _openModal(context, const ForgotPasswordModal());
                      },
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(color: Colors.grey),
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
                        backgroundColor: const Color(0xFF3C6E47),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Or sign in with',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  GoogleSignInButton(
                    onPressed: () =>
                        context.read<AuthCubit>().signInWithGoogle(),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _openModal(context, const SignUpModal());
                        },
                        child: const Text(
                          'Create one!',
                          style: TextStyle(
                            color: Color(0xFF3C6E47),
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
        ),
      ),
    );
  }
}

// --- Sign Up Modal ---
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
    _nameController.text = _AuthModalDrafts.signUpName;
    _emailController.text = _AuthModalDrafts.signUpEmail;
    _passwordController.text = _AuthModalDrafts.signUpPassword;
  }

  @override
  void dispose() {
    _AuthModalDrafts.signUpName = _nameController.text;
    _AuthModalDrafts.signUpEmail = _emailController.text;
    _AuthModalDrafts.signUpPassword = _passwordController.text;
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
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Sign Up',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C5E3B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Enter your details below',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  _textField(
                    hint: 'Full Name',
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    validator: AuthValidators.validateName,
                  ),
                  _textField(
                    hint: 'Email (@nltu.lviv.ua or @nltu.edu.ua)',
                    controller: _emailController,
                    keyboard: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (value) => AuthValidators.validateEmail(
                      value,
                      enforceDomain: true,
                    ),
                  ),
                  _textField(
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
                        backgroundColor: const Color(0xFF3C6E47),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Or sign up with',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  GoogleSignInButton(
                    onPressed: () =>
                        context.read<AuthCubit>().signInWithGoogle(),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Already have an account? ",
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _openModal(context, const SignInModal());
                        },
                        child: const Text(
                          'Sign In!',
                          style: TextStyle(
                            color: Color(0xFF3C6E47),
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
        ),
      ),
    );
  }
}

// --- Forgot Password Modal ---
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
    _emailController.text = _AuthModalDrafts.resetEmail;
  }

  @override
  void dispose() {
    _AuthModalDrafts.resetEmail = _emailController.text;
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
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Reset Password',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C5E3B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter your email to receive reset instructions',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  _textField(
                    hint: 'Email',
                    controller: _emailController,
                    keyboard: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    validator: (value) => AuthValidators.validateEmail(
                      value,
                      enforceDomain: true,
                    ),
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
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF3C6E47),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Send Instructions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _openModal(context, const SignInModal());
                    },
                    child: const Text(
                      'Back to Sign In',
                      style: TextStyle(color: Color(0xFF3C6E47)),
                    ),
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
