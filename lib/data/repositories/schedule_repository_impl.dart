import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/repositories/schedule_repository.dart';
import '../models/lesson_dto.dart';

class ScheduleRepositoryImpl implements ScheduleRepository {
  final FirebaseFirestore _firestore;

  ScheduleRepositoryImpl(this._firestore);

  Query<Map<String, dynamic>> _groupQuery(String groupId) =>
      _firestore.collection('schedule').where('groupId', isEqualTo: groupId);

  Query<Map<String, dynamic>> _teacherQuery(String teacherId) =>
      _firestore.collection('schedule').where('teacherId', isEqualTo: teacherId);

  List<LessonDto> _mapDocs(QuerySnapshot<Map<String, dynamic>> snapshot) =>
      snapshot.docs.map((doc) => LessonDto.fromJson(doc.data())).toList();

  // ── Group methods ──────────────────────────────────────────────────────────

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

  // ── Teacher methods ────────────────────────────────────────────────────────

  @override
  Future<List<LessonDto>> getScheduleByTeacher(String teacherId) async {
    try {
      final snapshot = await _teacherQuery(teacherId).get();
      return _mapDocs(snapshot);
    } catch (e) {
      throw Exception('Error loading teacher schedule: $e');
    }
  }

  @override
  Future<List<LessonDto>> getScheduleByTeacherFromCache(String teacherId) async {
    try {
      final snapshot = await _teacherQuery(teacherId).get(
        const GetOptions(source: Source.cache),
      );
      return _mapDocs(snapshot);
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') {
        return getScheduleByTeacher(teacherId);
      }
      throw Exception('Error loading teacher schedule from cache: $e');
    }
  }

  @override
  Stream<List<LessonDto>> watchScheduleByTeacher(String teacherId) {
    return _teacherQuery(teacherId)
        .snapshots()
        .map((snapshot) => _mapDocs(snapshot));
  }

  /// Returns a map of teacherId → teacherName from all schedule documents.
  @override
  Future<Map<String, String>> getAllAvailableTeachers() async {
    try {
      final snapshot = await _firestore.collection('schedule').get();
      final map = <String, String>{};
      for (final doc in snapshot.docs) {
        final id = doc['teacherId'] as String? ?? '';
        final name = doc['teacherName'] as String? ?? '';
        if (id.isNotEmpty && name.isNotEmpty) map[id] = name;
      }
      return Map.fromEntries(
        map.entries.toList()..sort((a, b) => a.value.compareTo(b.value)),
      );
    } catch (e) {
      throw Exception('Error loading available teachers: $e');
    }
  }

  @override
  Future<Map<String, String>> getAllAvailableTeachersFromCache() async {
    try {
      final snapshot = await _firestore
          .collection('schedule')
          .get(const GetOptions(source: Source.cache));
      final map = <String, String>{};
      for (final doc in snapshot.docs) {
        final id = doc['teacherId'] as String? ?? '';
        final name = doc['teacherName'] as String? ?? '';
        if (id.isNotEmpty && name.isNotEmpty) map[id] = name;
      }
      return Map.fromEntries(
        map.entries.toList()..sort((a, b) => a.value.compareTo(b.value)),
      );
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') {
        return getAllAvailableTeachers();
      }
      throw Exception('Error loading teachers from cache: $e');
    }
  }

  @override
  Future<List<String>> getGroupsForTeacher(String teacherId) async {
    if (teacherId.trim().isEmpty) {
      return [];
    }
    try {
      final snapshot = await _teacherQuery(teacherId).get();
      final groups = snapshot.docs
          .map((doc) => doc['groupId'] as String)
          .toSet()
          .toList();
      groups.sort();
      return groups;
    } catch (e) {
      throw Exception('Error loading teacher groups: $e');
    }
  }
}
