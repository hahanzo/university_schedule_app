// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LessonDto _$LessonDtoFromJson(Map<String, dynamic> json) => _LessonDto(
  groupId: json['groupId'] as String,
  subjectName: json['subjectName'] as String,
  teacherName: json['teacherName'] as String,
  teacherId: json['teacherId'] as String,
  roomName: json['roomName'] as String,
  roomId: json['roomId'] as String,
  dayOfWeek: (json['dayOfWeek'] as num).toInt(),
  lessonNumber: (json['lessonNumber'] as num).toInt(),
  timeStart: json['timeStart'] as String,
  timeEnd: json['timeEnd'] as String,
  type: json['type'] as String,
  weekType: json['weekType'] as String,
  isModification: json['isModification'] as bool? ?? false,
);

Map<String, dynamic> _$LessonDtoToJson(_LessonDto instance) =>
    <String, dynamic>{
      'groupId': instance.groupId,
      'subjectName': instance.subjectName,
      'teacherName': instance.teacherName,
      'teacherId': instance.teacherId,
      'roomName': instance.roomName,
      'roomId': instance.roomId,
      'dayOfWeek': instance.dayOfWeek,
      'lessonNumber': instance.lessonNumber,
      'timeStart': instance.timeStart,
      'timeEnd': instance.timeEnd,
      'type': instance.type,
      'weekType': instance.weekType,
      'isModification': instance.isModification,
    };
