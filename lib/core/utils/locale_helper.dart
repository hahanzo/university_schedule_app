import 'package:flutter/material.dart';

/// Helper for detecting and managing application locale.
abstract final class LocaleHelper {
  /// Supported locales
  static const List<String> supportedLanguageCodes = ['en', 'uk'];

  /// Get system locale if supported, otherwise default to Ukrainian.
  static Locale detectSystemLocale() {
    final systemLocale = WidgetsBinding.instance.window.locale;
    final languageCode = systemLocale.languageCode.toLowerCase();

    if (supportedLanguageCodes.contains(languageCode)) {
      return Locale(languageCode);
    }

    // Default to Ukrainian if system locale is not supported
    return const Locale('uk');
  }

  /// Convert Locale to language code string for storage.
  static String localeToString(Locale locale) {
    return locale.languageCode;
  }

  /// Convert language code string back to Locale.
  static Locale stringToLocale(String languageCode) {
    if (supportedLanguageCodes.contains(languageCode)) {
      return Locale(languageCode);
    }
    return const Locale('uk');
  }

  /// Get locale display name for UI.
  static String getLocaleDisplayName(Locale locale) {
    switch (locale.languageCode) {
      case 'uk':
        return 'Українська';
      case 'en':
        return 'English';
      default:
        return locale.languageCode;
    }
  }
}
