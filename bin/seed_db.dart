import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  final File file = File('assets/data/schedule.json');
  if (!await file.exists()) {
    print('❌ File assets/data/schedule.json not found!');
    return;
  }

  final String jsonString = await file.readAsString();
  final List<dynamic> scheduleData = json.decode(jsonString);

  const String projectId = 'uni-schedule-dev';
  const String baseUrl = 'http://localhost:8080/v1/projects/$projectId/databases/(default)/documents';

  print('🚀 Uploading clean database for Flutter...');

  for (var item in scheduleData) {
    // Form document ID: group_day_lesson_week
    String gId = item['groupId'].toString().toLowerCase().replaceAll('-', '');
    String week = item['weekType'].toString().substring(0, 3); 
    String docId = "${gId}_${item['dayOfWeek']}_${item['lessonNumber']}_$week";

    // Identifiers for transfer logic (plain text)
    String teacherId = item['teacher'].toString().toLowerCase()
        .replaceAll(' ', '_').replaceAll('.', '_');
    String roomId = "aud_${item['room'].toString().replaceAll('а.', '').trim()}";

    final firestoreData = {
      "fields": {
        "groupId": {"stringValue": item["groupId"]},
        "subjectName": {"stringValue": item["subject"]},
        "teacherName": {"stringValue": item["teacher"]},
        "teacherId": {"stringValue": teacherId}, 
        "roomName": {"stringValue": item["room"]},
        "roomId": {"stringValue": roomId},       
        "dayOfWeek": {"integerValue": item["dayOfWeek"]},
        "lessonNumber": {"integerValue": item["lessonNumber"]},
        "timeStart": {"stringValue": item["timeStart"]},
        "timeEnd": {"stringValue": item["timeEnd"]},
        "weekType": {"stringValue": item["weekType"]},
        "type": {"stringValue": item["type"]},
        "isModification": {"booleanValue": false} 
      }
    };

    final url = Uri.parse('$baseUrl/schedule/$docId');
    final response = await http.patch(
      url,
      body: json.encode(firestoreData),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      print('✅ Created: $docId');
    } else {
      print('❌ Error $docId: ${response.body}');
    }
  }
  print('\n✨ Database updated!');
}