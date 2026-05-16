import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'l10n/app_localizations.dart';
import 'presentation/features/schedule/pages/schedule_screen.dart';
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

  // Set transparent status bar and navigation bar for a more immersive experience
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
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
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('uk'),
      home: const ScheduleScreen(),
    );
  }
}
