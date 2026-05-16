import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../models/lesson_dto.dart';

class ScheduleRepositoryImpl implements ScheduleRepository {
  final FirebaseFirestore _firestore;

  ScheduleRepositoryImpl(this._firestore);

  Query<Map<String, dynamic>> _groupQuery(String groupId) =>
      _firestore.collection('schedule').where('groupId', isEqualTo: groupId);

  List<LessonDto> _mapDocs(QuerySnapshot<Map<String, dynamic>> snapshot) =>
      snapshot.docs.map((doc) => LessonDto.fromJson(doc.data())).toList();

  @override
  Future<List<LessonDto>> getScheduleByGroup(String groupId) async {
    try {
      final snapshot = await _groupQuery(groupId).get();
      return _mapDocs(snapshot);
    } catch (e) {
      throw Exception('Error loading schedule: $e');
    }
  }

  // Reads only from the local Firestore cache — no network request.
  @override
  Future<List<LessonDto>> getScheduleByGroupFromCache(String groupId) async {
    try {
      final snapshot = await _groupQuery(groupId).get(
        const GetOptions(source: Source.cache),
      );
      return _mapDocs(snapshot);
    } on FirebaseException catch (e) {
      // Cache may be empty on first launch — fall back to network
      if (e.code == 'unavailable') {
        return getScheduleByGroup(groupId);
      }
      throw Exception('Error loading schedule from cache: $e');
    }
  }

  @override
  Stream<List<LessonDto>> watchScheduleByGroup(String groupId) {
    return _groupQuery(groupId)
        .snapshots()
        .map((snapshot) => _mapDocs(snapshot));
  }

  @override
  Future<List<String>> getAllAvailableGroups() async {
    try {
      final snapshot = await _firestore.collection('schedule').get();
      final groups =
          snapshot.docs.map((doc) => doc['groupId'] as String).toSet().toList();
      groups.sort();
      return groups;
    } catch (e) {
      throw Exception('Error loading available groups: $e');
    }
  }

  // Reads the group list from local cache.
  @override
  Future<List<String>> getAllAvailableGroupsFromCache() async {
    try {
      final snapshot = await _firestore
          .collection('schedule')
          .get(const GetOptions(source: Source.cache));
      final groups =
          snapshot.docs.map((doc) => doc['groupId'] as String).toSet().toList();
      groups.sort();
      return groups;
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') {
        return getAllAvailableGroups();
      }
      throw Exception('Error loading groups from cache: $e');
    }
  }
}