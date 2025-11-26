import 'package:flutter/material.dart';
import '../../domain/entities/lesson_entity.dart';

class LessonCard extends StatelessWidget {
  final LessonEntity lesson;

  const LessonCard({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Determine the color of the strip depending on the type of pair
    final typeColor = _getTypeColor(lesson.type, colorScheme);

    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Lesson details
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // Time
                  SizedBox(
                    width: 50,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          lesson.timeStart,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          lesson.timeEnd,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Color line indicator
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: typeColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Lesson information
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        //Type ('lecture', 'lab', 'practice')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: typeColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _formatType(lesson.type),
                            style: textTheme.labelSmall?.copyWith(
                              color: typeColor,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        
                        //Subject
                        Text(
                          lesson.subject,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Teacher and room (Row with icons)
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, 
                              size: 14, color: colorScheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              lesson.room,
                              style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.person_outline, 
                              size: 14, color: colorScheme.primary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                lesson.teacher,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(String type, ColorScheme scheme) {
    switch (type) {
      case 'lecture': return Colors.orange.shade700; 
      case 'lab': return scheme.primary;
      case 'practice': return Colors.green.shade600;
      default: return scheme.outline;
    }
  }

  String _formatType(String type) {
    switch (type) {
      case 'lecture': return 'ЛЕКЦІЯ';
      case 'lab': return 'ЛАБОРАТОРНА';
      case 'practice': return 'ПРАКТИЧНА';
      default: return type.toUpperCase();
    }
  }
}