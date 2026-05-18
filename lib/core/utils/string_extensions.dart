import 'package:flutter/foundation.dart';

extension StringExtension on String {
  /// Capitalizes only the first letter of the string.
  String toCapitalized() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  /// Rewrites localhost to 10.0.2.2 on Android emulator/devices
  /// in a completely web-safe manner without importing dart:io.
  String resolveEmulatorUrl() {
    if (isEmpty) return this;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return replaceAll('localhost', '10.0.2.2');
    }
    return this;
  }
}
