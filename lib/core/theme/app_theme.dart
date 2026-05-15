import 'package:flutter/material.dart';

@immutable
class LessonColors extends ThemeExtension<LessonColors> {
  final Color? labColor;
  final Color? lectureColor;
  final Color? practiceColor;

  const LessonColors({
    required this.labColor,
    required this.lectureColor,
    required this.practiceColor,
  });

  @override
  LessonColors copyWith({
    Color? labColor,
    Color? lectureColor,
    Color? practiceColor,
  }) {
    return LessonColors(
      labColor: labColor ?? this.labColor,
      lectureColor: lectureColor ?? this.lectureColor,
      practiceColor: practiceColor ?? this.practiceColor,
    );
  }

  @override
  LessonColors lerp(ThemeExtension<LessonColors>? other, double t) {
    if (other is! LessonColors) {
      return this;
    }
    return LessonColors(
      labColor: Color.lerp(labColor, other.labColor, t),
      lectureColor: Color.lerp(lectureColor, other.lectureColor, t),
      practiceColor: Color.lerp(practiceColor, other.practiceColor, t),
    );
  }
}

class AppTheme {
  // Light Theme Colors
  static const Color _lightPrimary = Color(0xFFB8E994);
  static const Color _lightBackground = Color(0xFFFFFFFF);
  static const Color _lightSurface = Color(0xFFECEFE6);
  static const Color _lightOnBackground = Color(0xFF1A1C18);
  static const Color _lightOnSurfaceVariant = Color(0xFF444746);

  // Dark Theme Colors
  static const Color _darkPrimary = Color(0xFF90C26D);
  static const Color _darkBackground = Color(0xFF121212);
  static const Color _darkSurface = Color(0xFF1E1E1E);
  static const Color _darkOnBackground = Color(0xFFE2E2E2);
  static const Color _darkOnSurfaceVariant = Color(0xFFB3B3B3);

  // Lesson Colors Light
  static const LessonColors _lightLessonColors = LessonColors(
    labColor: Color(0xFF708661),
    lectureColor: Color(0xFF8E7A93),
    practiceColor: Color(0xFFC5C78F),
  );

  // Lesson Colors Dark
  static const LessonColors _darkLessonColors = LessonColors(
    labColor: Color(0xFF4A5C40),
    lectureColor: Color(0xFF6A5770),
    practiceColor: Color(0xFF949666),
  );

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _lightPrimary,
        primary: _lightPrimary,
        onPrimary: _lightOnBackground,
        surface: _lightSurface,
        onSurfaceVariant: _lightOnSurfaceVariant,
        onSurface: _lightOnBackground,
      ),
      scaffoldBackgroundColor: _lightBackground,
      datePickerTheme: DatePickerThemeData(
        backgroundColor: _lightBackground,
        headerBackgroundColor: _lightPrimary,
        headerForegroundColor: _lightOnBackground,
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _lightPrimary;
          return null;
        }),
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _lightOnBackground;
          return null;
        }),
        cancelButtonStyle: TextButton.styleFrom(
          foregroundColor: _lightOnSurfaceVariant,
        ),
        confirmButtonStyle: TextButton.styleFrom(
          foregroundColor: _lightOnBackground,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      searchBarTheme: SearchBarThemeData(
        backgroundColor: WidgetStateProperty.all(_lightSurface),
        elevation: WidgetStateProperty.all(0),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
      ),
      cardTheme: const CardThemeData(
        color: _lightSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: _lightOnBackground,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: TextStyle(color: _lightOnSurfaceVariant),
      ),
      extensions: const <ThemeExtension<dynamic>>[_lightLessonColors],
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: _darkPrimary,
        primary: _darkPrimary,
        onPrimary: _darkBackground,
        surface: _darkSurface,
        onSurfaceVariant: _darkOnSurfaceVariant,
        onSurface: _darkOnBackground,
      ),
      scaffoldBackgroundColor: _darkBackground,
      datePickerTheme: DatePickerThemeData(
        backgroundColor: _darkSurface,
        headerBackgroundColor: _darkPrimary,
        headerForegroundColor: _darkBackground,
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _darkPrimary;
          return null;
        }),
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _darkBackground;
          return null;
        }),
        cancelButtonStyle: TextButton.styleFrom(
          foregroundColor: _darkOnSurfaceVariant,
        ),
        confirmButtonStyle: TextButton.styleFrom(
          foregroundColor: _darkPrimary,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      searchBarTheme: SearchBarThemeData(
        backgroundColor: WidgetStateProperty.all(_darkSurface),
        elevation: WidgetStateProperty.all(0),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
      ),
      cardTheme: const CardThemeData(
        color: _darkSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: _darkOnBackground,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: TextStyle(color: _darkOnSurfaceVariant),
      ),
      extensions: const <ThemeExtension<dynamic>>[_darkLessonColors],
    );
  }
}
