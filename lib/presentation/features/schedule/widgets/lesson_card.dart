import 'package:flutter/material.dart';
import 'package:university_schedule_app/l10n/app_localizations.dart';

import '../../../../data/models/lesson_dto.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';

class LessonCard extends StatelessWidget {
  final LessonDto lesson;

  /// When [true], shows the group ID instead of the teacher name.
  /// Used by the teacher schedule screen where the teacher is already known.
  final bool showGroupInstead;

  const LessonCard({
    super.key,
    required this.lesson,
    this.showGroupInstead = false,
  });

  static const double _indicatorWidth =
      ScheduleUiConstants.lessonCardIndicatorWidth;
  static const double _contentPaddingH =
      ScheduleUiConstants.lessonCardContentPaddingH;
  static const double _contentPaddingV =
      ScheduleUiConstants.lessonCardContentPaddingV;

  String? _getTranslatedType(BuildContext context, String type) {
    final t = type.toLowerCase();
    if (t.contains('lecture')) return AppLocalizations.of(context)!.lecture;
    if (t.contains('lab')) return AppLocalizations.of(context)!.lab;
    if (t.contains('practice')) return AppLocalizations.of(context)!.practice;
    if (t.contains('unknown')) return null;
    return t;
  }

  @override
  Widget build(BuildContext context) {
    // Get colors and styles from the current theme
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Determine the accent line color based on lesson type
    final Color typeColor = _getIndicatorColor(context, lesson.type);
    final String? translatedType = _getTranslatedType(context, lesson.type);

    final bool hasTeacher =
        lesson.teacherName.isNotEmpty &&
        lesson.teacherName.toLowerCase() != 'null';
    final bool hasRoom =
        lesson.roomName.isNotEmpty && lesson.roomName.toLowerCase() != 'null';
    final bool hasGroup = lesson.groupId.isNotEmpty;

    // Teacher mode: show group; student mode: show teacher name.
    final bool showSecondaryRow = showGroupInstead
        ? hasGroup || hasRoom
        : hasTeacher || hasRoom;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ScheduleUiConstants.lessonCardHorizontalPadding,
        vertical: ScheduleUiConstants.lessonCardVerticalPadding,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Time Column left
          SizedBox(
            width: ScheduleUiConstants.lessonCardTimeColumnWidth,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  lesson.timeStart,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  lesson.timeEnd,
                  style: textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: ScheduleUiConstants.lessonCardTimeColumnGap),

          // Main Card Content
          Expanded(
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(
                  ScheduleUiConstants.lessonCardBorderRadius,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(width: _indicatorWidth, color: typeColor),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      _indicatorWidth + _contentPaddingH,
                      _contentPaddingV,
                      _contentPaddingH,
                      _contentPaddingV,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Lesson type (lecture, lab, etc.)
                        if (translatedType != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              translatedType,
                              style: textTheme.labelMedium?.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        // Subject name
                        Text(
                          lesson.subjectName,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        if (showSecondaryRow) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (showGroupInstead && hasGroup) ...[
                                const Icon(
                                  Icons.group_outlined,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    lesson.groupId,
                                    style: textTheme.bodySmall,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ] else if (!showGroupInstead && hasTeacher) ...[
                                const Icon(
                                  Icons.person_outline,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    lesson.teacherName,
                                    style: textTheme.bodySmall,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                              if (hasRoom) ...[
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  lesson.roomName,
                                  style: textTheme.bodySmall,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Logic for selecting line color from AppColors
  Color _getIndicatorColor(BuildContext context, String type) {
    final t = type.toLowerCase();
    if (t.contains('lab')) {
      return Theme.of(context).extension<LessonColors>()!.labColor!;
    }
    if (t.contains('lecture')) {
      return Theme.of(context).extension<LessonColors>()!.lectureColor!;
    }
    if (t.contains('practice')) {
      return Theme.of(context).extension<LessonColors>()!.practiceColor!;
    }
    return Colors.transparent;
  }
}
