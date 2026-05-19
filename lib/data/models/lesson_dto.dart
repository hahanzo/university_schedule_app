import 'package:freezed_annotation/freezed_annotation.dart';

part 'lesson_dto.freezed.dart';
part 'lesson_dto.g.dart';

@Freezed(fromJson: true)
abstract class LessonDto with _$LessonDto {
  const factory LessonDto({
    required String groupId,
    required String subjectName,
    required String teacherName,
    required String teacherId,
    required String roomName,
    required String roomId,
    required int dayOfWeek,
    required int lessonNumber,
    required String timeStart,
    required String timeEnd,
    required String type,
    required String weekType,
    @Default(false) bool isModification,
    @Default('') String id,
  }) = _LessonDto;

  factory LessonDto.fromJson(Map<String, dynamic> json) => _$LessonDtoFromJson(json);
}