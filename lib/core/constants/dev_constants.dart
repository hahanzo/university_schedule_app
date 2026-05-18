/// Development-only constants for Firebase Auth Emulator test accounts.
/// These values are only used when USE_FIREBASE_EMULATORS=true.
abstract final class DevConstants {
  static const testStudentEmail = 'test.student@nltu.lviv.ua';
  static const testTeacherEmail = 'test.teacher@nltu.edu.ua';
  static const testPassword = 'Test1234!';
  static const testStudentGroup = 'KN-11-1';
  static const testStudentName = 'Test Student';
  static const testTeacherName = 'Test Teacher';
}

/// Constants for avatar image picking constraints.
abstract final class AvatarConstants {
  static const maxDimension = 720.0;
  static const imageQuality = 85;
  static const avatarRadius = 48.0;
  static const avatarIconSize = 48.0;
}

/// Retry configuration for Firestore profile loading after registration.
abstract final class AuthConstants {
  static const profileLoadRetries = 3;
  static const profileLoadRetryDelay = Duration(milliseconds: 600);
}
