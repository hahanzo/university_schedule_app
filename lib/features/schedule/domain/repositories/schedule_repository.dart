import '../entities/lesson_entity.dart';

abstract class ScheduleRepository {
  Future<List<LessonEntity>> getScheduleForGroup(String groupId);
}