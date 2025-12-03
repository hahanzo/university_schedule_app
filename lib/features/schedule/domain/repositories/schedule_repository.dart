import '../entities/lesson_entity.dart';

abstract class ScheduleRepository {
  Future<List<LessonEntity>> getScheduleForGroup(String groupId);
  Future<List<String>> getSearchSuggestions(String query);
  Future<List<LessonEntity>> searchLessons(String query);
}