class AuthValidators {
  static const String studentDomain = 'nltu.lviv.ua';
  static const String teacherDomain = 'nltu.edu.ua';

  static bool isAllowedDomain(String email) {
    final lowerEmail = email.toLowerCase();
    return lowerEmail.endsWith(studentDomain) ||
        lowerEmail.endsWith(teacherDomain);
  }

  static String? validateName(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Full name is required.';
    }
    if (trimmed.length < 2) {
      return 'Full name must be at least 2 characters.';
    }
    if (trimmed.length > 50) {
      return 'Full name must be at most 50 characters.';
    }
    return null;
  }

  static String? validateEmail(String? value, {bool enforceDomain = false}) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Email is required.';
    }
    if (!_emailRegex.hasMatch(trimmed)) {
      return 'Enter a valid email address.';
    }
    if (enforceDomain && !isAllowedDomain(trimmed)) {
      return 'Use @nltu.lviv.ua or @nltu.edu.ua email.';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return 'Password is required.';
    }
    if (password.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    if (!_upperRegex.hasMatch(password)) {
      return 'Password must include an uppercase letter.';
    }
    if (!_lowerRegex.hasMatch(password)) {
      return 'Password must include a lowercase letter.';
    }
    if (!_digitRegex.hasMatch(password)) {
      return 'Password must include a digit.';
    }
    if (!_specialRegex.hasMatch(password)) {
      return 'Password must include a special character.';
    }
    return null;
  }

  static String? validateSignInPassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return 'Password is required.';
    }
    return null;
  }

  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final RegExp _upperRegex = RegExp(r'[A-Z]');
  static final RegExp _lowerRegex = RegExp(r'[a-z]');
  static final RegExp _digitRegex = RegExp(r'\d');
  static final RegExp _specialRegex = RegExp(r'[^A-Za-z0-9\s]');
}
