import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'core/injection.dart';
import 'domain/repositories/schedule_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize with fake data for emulator usage
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "any-key", 
      appId: "uni-schedule-app",
      messagingSenderId: "any-id",
      projectId: "uni-schedule-dev",
      storageBucket: "uni-schedule-dev.appspot.com",
    ),
  );
  
  await configureDependencies();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    testSchedule();
    return MaterialApp(
      title: 'Uni Schedule',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(child: Text('Database connected to Docker!')),
      ),
    );
  }
}

void testSchedule() async {
  final repo = getIt<ScheduleRepository>();
  final lessons = await repo.getScheduleByGroup('КН-11-1');
  
  for (var lesson in lessons) {
    print('📖 Lesson: ${lesson.subjectName} о ${lesson.timeStart}');
  }
}