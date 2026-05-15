import 'package:flutter/material.dart';
import 'package:university_schedule_app/l10n/app_localizations.dart';
import '../../../../data/models/lesson_dto.dart';
import '../../../../core/theme/app_theme.dart';

class LessonCard extends StatelessWidget {
  final LessonDto lesson;

  const LessonCard({super.key, required this.lesson});

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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Time Column left
          SizedBox(
            width: 50,
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
          const SizedBox(width: 12),

          // Main Card Content
          Expanded(
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
              ),
              // IntrinsicHeight adjusts the line height to the content height
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    // Color Indicator left
                    Container(
                      width: 10,
                      decoration: BoxDecoration(
                        color: typeColor,
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(18),
                        ),
                      ),
                    ),

                    // Card content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
                            if (hasTeacher || hasRoom) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  if (hasTeacher) ...[
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
                    ),
                  ],
                ),
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
