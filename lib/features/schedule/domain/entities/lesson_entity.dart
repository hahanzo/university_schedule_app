import 'package:equatable/equatable.dart';

class LessonEntity extends Equatable {
  final String groupId;
  final int dayOfWeek; // 1 - Mon, 7 - Sun
  final String weekType; // 'numerator', 'denominator', 'all'
  final int lessonNumber;
  final String timeStart;
  final String timeEnd;
  final String subject;
  final String type; // 'lecture', 'lab', 'practice'
  final String teacher;
  final String room;

  const LessonEntity({
    required this.groupId,
    required this.dayOfWeek,
    required this.weekType,
    required this.lessonNumber,
    required this.timeStart,
    required this.timeEnd,
    required this.subject,
    required this.type,
    required this.teacher,
    required this.room,
  });

  @override
  List<Object?> get props => [groupId, dayOfWeek, lessonNumber, subject, type];
}