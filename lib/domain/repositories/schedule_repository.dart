import '../../data/models/lesson_dto.dart';

abstract class ScheduleRepository {
  Future<List<LessonDto>> getScheduleByGroup(String groupId);
  Future<List<LessonDto>> getScheduleByGroupFromCache(String groupId);
  Stream<List<LessonDto>> watchScheduleByGroup(String groupId);
  Future<List<String>> getAllAvailableGroups();
  Future<List<String>> getAllAvailableGroupsFromCache();

  Future<List<LessonDto>> getScheduleByTeacher(String teacherId);
  Future<List<LessonDto>> getScheduleByTeacherFromCache(String teacherId);
  Stream<List<LessonDto>> watchScheduleByTeacher(String teacherId);
  Future<Map<String, String>> getAllAvailableTeachers(); // id → name
  Future<Map<String, String>> getAllAvailableTeachersFromCache();
  Future<List<String>> getGroupsForTeacher(String teacherId);
}