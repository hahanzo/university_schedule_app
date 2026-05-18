import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  /// Initialize with system locale detected on first launch.
  SettingsCubit() : super(SettingsState.withSystemLocale());

  void changeTheme(ThemeMode mode) {
    emit(state.copyWith(themeMode: mode));
  }

  void changeLocale(Locale locale) {
    emit(state.copyWith(locale: locale));
  }
}
