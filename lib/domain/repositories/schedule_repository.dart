import '../../data/models/lesson_dto.dart';

abstract class ScheduleRepository {
  Future<List<LessonDto>> getScheduleByGroup(String groupId);
  
  Stream<List<LessonDto>> watchScheduleByGroup(String groupId);
}