import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/material.dart';
import 'presentation/pages/schedule_screen.dart';
import 'core/theme/app_theme.dart';
import 'core/injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('uk_UA', null);

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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Uni Schedule',
      theme: AppTheme.light,
      localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('uk', 'UA'),
      ],
      locale: const Locale('uk', 'UA'), 
      home: const ScheduleScreen(),
    );
  }
}