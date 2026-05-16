import '../../data/models/lesson_dto.dart';

abstract class ScheduleRepository {
  Future<List<LessonDto>> getScheduleByGroup(String groupId);

  Future<List<LessonDto>> getScheduleByGroupFromCache(String groupId);

  Stream<List<LessonDto>> watchScheduleByGroup(String groupId);

  Future<List<String>> getAllAvailableGroups();

  Future<List<String>> getAllAvailableGroupsFromCache();
}