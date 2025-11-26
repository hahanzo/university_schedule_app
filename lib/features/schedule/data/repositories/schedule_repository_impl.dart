import '../../domain/entities/lesson_entity.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../datasources/schedule_local_datasource.dart';

class ScheduleRepositoryImpl implements ScheduleRepository {
  final ScheduleLocalDataSource localDataSource;

  ScheduleRepositoryImpl({required this.localDataSource});

  @override
  Future<List<LessonEntity>> getScheduleForGroup(String groupId) async {
    try {
      final lessons = await localDataSource.getLessonsFromJson(groupId);
      return lessons;
    } catch (e) {
      throw Exception('Failed to load schedule: $e');
    }
  }
}