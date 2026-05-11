import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../models/lesson_dto.dart';

class ScheduleRepositoryImpl implements ScheduleRepository {
  final FirebaseFirestore _firestore;

  ScheduleRepositoryImpl(this._firestore);

  @override
  Future<List<LessonDto>> getScheduleByGroup(String groupId) async {
    try {
      final snapshot = await _firestore
          .collection('schedule')
          .where('groupId', isEqualTo: groupId)
          .get();

      return snapshot.docs
          .map((doc) => LessonDto.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception("Error of loading schedule: $e");
    }
  }

  @override
  Stream<List<LessonDto>> watchScheduleByGroup(String groupId) {
    return _firestore
        .collection('schedule')
        .where('groupId', isEqualTo: groupId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LessonDto.fromJson(doc.data()))
            .toList());
  }
}