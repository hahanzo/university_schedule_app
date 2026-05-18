import 'package:flutter/material.dart';
import '../../../../core/utils/locale_helper.dart';

class SettingsState {
  final ThemeMode themeMode;
  final Locale locale;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.locale = const Locale('uk'),
  });

  /// Factory constructor that initializes with system locale on first launch.
  factory SettingsState.withSystemLocale() {
    return SettingsState(
      themeMode: ThemeMode.system,
      locale: LocaleHelper.detectSystemLocale(),
    );
  }

  SettingsState copyWith({ThemeMode? themeMode, Locale? locale}) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
    );
  }
}
