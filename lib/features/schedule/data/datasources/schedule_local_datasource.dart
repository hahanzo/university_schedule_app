import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/lesson_model.dart';

abstract class ScheduleLocalDataSource {
  Future<List<LessonModel>> getLessonsFromJson(String groupId);
}

class ScheduleLocalDataSourceImpl implements ScheduleLocalDataSource {
  @override
  Future<List<LessonModel>> getLessonsFromJson(String groupId) async {
    final String response = await rootBundle.loadString('assets/data/schedule.json');
    
    final List<dynamic> data = json.decode(response);
    
    return data
        .map((json) => LessonModel.fromJson(json))
        .where((lesson) => lesson.groupId == groupId)
        .toList();
  }
}