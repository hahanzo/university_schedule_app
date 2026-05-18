// ignore_for_file: avoid_print

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

  // Збираємо унікальних викладачів для створення пошта/викладач мапінгу
  final Map<String, String> teachersMap = {};
  for (var item in scheduleData) {
    final String teacherName = item['teacher']?.toString() ?? '';
    final String teacherId = teacherName.toLowerCase()
        .replaceAll(' ', '_').replaceAll('.', '_');
    if (teacherName.isNotEmpty && teacherName != 'null') {
      teachersMap[teacherId] = teacherName;
    }
  }

  print('\n🚀 Uploading teacher email mappings...');
  for (var entry in teachersMap.entries) {
    final String teacherId = entry.key;
    final String name = entry.value;
    final String email = '$teacherId@nltu.edu.ua';

    final teacherData = {
      "fields": {
        "teacherId": {"stringValue": teacherId},
        "name": {"stringValue": name}
      }
    };

    final url = Uri.parse('$baseUrl/teachers/$email');
    final response = await http.patch(
      url,
      body: json.encode(teacherData),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      print('✅ Mapped: $email -> $teacherId ($name)');
    } else {
      print('❌ Error mapping $email: ${response.body}');
    }
  }

  // Збираємо унікальні групи
  final Set<String> groupsSet = {};
  for (var item in scheduleData) {
    if (item['groupId'] != null) {
      groupsSet.add(item['groupId'].toString());
    }
  }
  final List<String> groupsList = groupsSet.toList()..sort();
  final List<String> testGroups = groupsList.take(3).toList();

  // Додаємо тестові акаунти у спеціальну колекцію для емулятора
  print('\n🚀 Uploading dev test accounts...');
  
  final List<Map<String, dynamic>> studentAccounts = testGroups.asMap().entries.map((e) {
    return {
      "mapValue": {
        "fields": {
          "email": {"stringValue": "student${e.key + 1}@nltu.lviv.ua"},
          "name": {"stringValue": "Test Student ${e.key + 1}"},
          "groupId": {"stringValue": e.value},
          "role": {"stringValue": "student"}
        }
      }
    };
  }).toList();

  final List<Map<String, dynamic>> teacherAccounts = teachersMap.entries.take(3).toList().asMap().entries.map((e) {
    return {
      "mapValue": {
        "fields": {
          "email": {"stringValue": "teacher${e.key + 1}@nltu.edu.ua"},
          "name": {"stringValue": e.value.value},
          "teacherId": {"stringValue": e.value.key},
          "role": {"stringValue": "teacher"}
        }
      }
    };
  }).toList();

  final testAccountsData = {
    "fields": {
      "students": {"arrayValue": {"values": studentAccounts}},
      "teachers": {"arrayValue": {"values": teacherAccounts}}
    }
  };

  final testAccountsUrl = Uri.parse('$baseUrl/config/test_accounts');
  final testAccountsResponse = await http.patch(
    testAccountsUrl,
    body: json.encode(testAccountsData),
    headers: {'Content-Type': 'application/json'},
  );

  if (testAccountsResponse.statusCode == 200) {
    print('✅ Created dev test accounts in config/test_accounts');
  } else {
    print('❌ Error creating test accounts: ${testAccountsResponse.body}');
  }

  print('\n✨ Database updated!');
}