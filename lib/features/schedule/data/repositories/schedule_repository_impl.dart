import 'dart:convert';
import 'package:flutter/services.dart';
import '../../domain/entities/lesson_entity.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../datasources/schedule_local_datasource.dart';
import '../models/lesson_model.dart';

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

  List<LessonModel>? _cachedLessons;

  Future<List<LessonModel>> _getAllLessons() async {
    if (_cachedLessons != null) return _cachedLessons!;
    final String response = await rootBundle.loadString('assets/data/schedule.json');
    final List<dynamic> data = json.decode(response);
    _cachedLessons = data.map((json) => LessonModel.fromJson(json)).toList();
    return _cachedLessons!;
  }

  @override
  Future<List<String>> getSearchSuggestions(String query) async {
    if (query.length < 2) return [];
    
    final lessons = await _getAllLessons();
    final lowerQuery = query.toLowerCase();
    
    final Set<String> suggestions = {};

    for (var lesson in lessons) {
      if (lesson.teacher.toLowerCase().contains(lowerQuery)) {
        suggestions.add(lesson.teacher);
      }
      if (lesson.subject.toLowerCase().contains(lowerQuery)) {
        suggestions.add(lesson.subject);
      }
      if (lesson.groupId.toLowerCase().contains(lowerQuery)) {
        suggestions.add(lesson.groupId);
      }
    }

    return suggestions.take(5).toList();
  }

  @override
  Future<List<LessonModel>> searchLessons(String query) async {
    final lessons = await _getAllLessons();
    final lowerQuery = query.toLowerCase();

    return lessons.where((l) {
      return l.teacher.toLowerCase().contains(lowerQuery) ||
             l.subject.toLowerCase().contains(lowerQuery) ||
             l.groupId.toLowerCase().contains(lowerQuery);
    }).toList();
  }
}