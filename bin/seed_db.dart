import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  final File file = File('assets/data/schedule.json');
  final String jsonString = await file.readAsString();
  final List<dynamic> scheduleData = json.decode(jsonString);

  const String projectId = 'uni-schedule-dev';
  const String url = 'http://localhost:8080/v1/projects/$projectId/databases/(default)/documents/schedule';

  print('🚀 Starting data seeding for ${scheduleData.length} items in Firestore...');

  for (var item in scheduleData) {
    final firestoreData = {
      "fields": {
        "groupId": {"stringValue": item["groupId"]},
        "dayOfWeek": {"integerValue": item["dayOfWeek"]},
        "weekType": {"stringValue": item["weekType"]},
        "lessonNumber": {"integerValue": item["lessonNumber"]},
        "timeStart": {"stringValue": item["timeStart"]},
        "timeEnd": {"stringValue": item["timeEnd"]},
        "subject": {"stringValue": item["subject"]},
        "type": {"stringValue": item["type"]},
        "teacher": {"stringValue": item["teacher"]},
        "room": {"stringValue": item["room"]},
      }
    };

    final response = await http.post(
      Uri.parse(url),
      body: json.encode(firestoreData),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      print('✅ Added: ${item["subject"]} for ${item["groupId"]}');
    } else {
      print('❌ Error: ${response.body}');
    }
  }

  print('✨ Data seeding completed!');
}