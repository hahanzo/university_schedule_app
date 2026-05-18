import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';

class AuthModalDrafts {
  static String signInEmail = '';
  static String signInPassword = '';
  static String signUpName = '';
  static String signUpEmail = '';
  static String signUpPassword = '';
  static String resetEmail = '';
}

void showAuthModal(BuildContext context, Widget child) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => child,
  );
}

class AuthModalContainer extends StatelessWidget {
  final Widget child;

  const AuthModalContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AuthUiConstants.modalTopRadius),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(
            AuthUiConstants.modalHorizontalPadding,
            AuthUiConstants.modalTopPadding,
            AuthUiConstants.modalHorizontalPadding,
            AuthUiConstants.modalBottomPadding,
          ),
          child: child,
        ),
      ),
    );
  }
}

class AuthTextField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType? keyboard;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final void Function(String)? onChanged;
  final AutovalidateMode? autovalidateMode;

  const AuthTextField({
    super.key,
    required this.hint,
    required this.controller,
    this.obscure = false,
    this.keyboard,
    this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
    this.onChanged,
    this.autovalidateMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AuthUiConstants.fieldBottomMargin),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AuthUiConstants.fieldRadius),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboard,
        textInputAction: textInputAction,
        onFieldSubmitted: onFieldSubmitted,
        onChanged: onChanged,
        validator: validator,
        autovalidateMode:
            autovalidateMode ?? AutovalidateMode.onUserInteraction,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AuthUiConstants.horizontalTextPadding,
            vertical: AuthUiConstants.verticalTextPadding,
          ),
          border: InputBorder.none,
          errorStyle: TextStyle(
            color: Theme.of(context).colorScheme.error,
            fontSize: AuthUiConstants.formErrorFontSize,
          ),
        ),
        style: const TextStyle(fontSize: AuthUiConstants.fieldFontSize),
      ),
    );
  }
}

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;

  const GoogleSignInButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AuthUiConstants.buttonHeight,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppTheme.getAuthPrimaryColor(context)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AuthUiConstants.buttonRadius),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/images/material-icon-theme_google.svg',
              height: AuthUiConstants.googleIconSize,
              width: AuthUiConstants.googleIconSize,
            ),
            const SizedBox(width: AuthUiConstants.googleTextGap),
            Text(
              'Continue with Google',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
