/// App-wide constants that do not belong to a specific feature.
abstract final class AppConstants {
  /// Role identifiers stored in Firestore.
  static const teacherRole = 'teacher';
  static const studentRole = 'student';
}

/// Reusable layout values for auth UI.
abstract final class AuthUiConstants {
  static const modalTopRadius = 20.0;
  static const fieldRadius = 4.0;
  static const buttonRadius = 12.0;
  static const buttonHeight = 50.0;
  static const modalHorizontalPadding = 24.0;
  static const modalTopPadding = 24.0;
  static const modalBottomPadding = 32.0;
  static const fieldBottomMargin = 14.0;
  static const fieldFontSize = 15.0;
  static const titleFontSize = 30.0;
  static const subtitleFontSize = 13.0;
  static const actionFontSize = 16.0;
  static const googleIconSize = 22.0;
  static const googleTextGap = 10.0;
  static const horizontalTextPadding = 16.0;
  static const verticalTextPadding = 14.0;
  static const cardVerticalGap = 6.0;
  static const sectionGap = 20.0;
  static const smallGap = 8.0;
  static const mediumGap = 14.0;
  static const largeGap = 20.0;
  static const formErrorFontSize = 12.0;
}

/// Reusable layout values for schedule UI.
abstract final class ScheduleUiConstants {
  // Lesson card
  static const lessonCardIndicatorWidth = 10.0;
  static const lessonCardContentPaddingH = 16.0;
  static const lessonCardContentPaddingV = 12.0;
  static const lessonCardBorderRadius = 18.0;
  static const lessonCardTimeColumnWidth = 50.0;
  static const lessonCardTimeColumnGap = 12.0;
  static const lessonCardHorizontalPadding = 16.0;
  static const lessonCardVerticalPadding = 6.0;

  // Schedule header
  static const scheduleHeaderHeight = 56.0;
  static const scheduleHeaderBorderRadius = 28.0;
  static const scheduleHeaderPaddingTop = 8.0;
  static const scheduleHeaderPaddingBottom = 8.0;
  static const scheduleHeaderPaddingHorizontal = 16.0;
  static const scheduleHeaderGap = 8.0;

  // Selection bottom sheet
  static const selectionSheetBorderRadius = 24.0;
  static const selectionSheetPaddingHorizontal = 16.0;
  static const selectionSheetPaddingVertical = 20.0;
  static const selectionSheetItemPadding = 8.0;
  static const selectionSheetItemBorderRadius = 8.0;
  static const selectionSheetDividerHeight = 1.0;
  static const selectionSheetGap = 16.0;

  // Time divider
  static const timeDividerPaddingHorizontal = 16.0;
  static const timeDividerPaddingVertical = 8.0;
  static const timeDividerLineGap = 8.0;
  static const timeDividerLineHeight = 1.0;
}

/// Reusable layout values for settings UI.
abstract final class SettingsUiConstants {
  static const horizontalPadding = 16.0;
  static const verticalPaddingSmall = 8.0;
  static const dividerHeight = 32.0;
  static const userCardMarginBottom = 8.0;
  static const sectionHeaderVerticalPadding = 8.0;
}
