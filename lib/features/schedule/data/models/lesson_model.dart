import '../../domain/entities/lesson_entity.dart';

class LessonModel extends LessonEntity {
  const LessonModel({
    required super.groupId,
    required super.dayOfWeek,
    required super.weekType,
    required super.lessonNumber,
    required super.timeStart,
    required super.timeEnd,
    required super.subject,
    required super.type,
    required super.teacher,
    required super.room,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    return LessonModel(
      groupId: json['groupId'] ?? '',
      dayOfWeek: json['dayOfWeek'] ?? 0,
      weekType: json['weekType'] ?? 'all',
      lessonNumber: json['lessonNumber'] ?? 0,
      timeStart: json['timeStart'] ?? '',
      timeEnd: json['timeEnd'] ?? '',
      subject: json['subject'] ?? '',
      type: json['type'] ?? 'unknown',
      teacher: json['teacher'] ?? '',
      room: json['room'] ?? '',
    );
  }
}