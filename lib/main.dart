import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'l10n/app_localizations.dart';
import 'presentation/features/schedule/pages/student_schedule_screen.dart';
import 'presentation/features/schedule/pages/teacher_schedule_screen.dart';
import 'presentation/features/auth/blocs/auth_cubit.dart';
import 'presentation/features/auth/blocs/auth_state.dart';
import 'presentation/features/auth/pages/startup_screen.dart';
import 'presentation/features/settings/blocs/settings_cubit.dart';
import 'presentation/features/settings/blocs/settings_state.dart';
import 'presentation/features/settings/pages/settings_screen.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('uk_UA', null);

  const bool useEmulators = bool.fromEnvironment(
    'USE_FIREBASE_EMULATORS',
    defaultValue: true,
  );
  const String apiKeyEnv = String.fromEnvironment('FIREBASE_API_KEY');
  const String appIdEnv = String.fromEnvironment('FIREBASE_APP_ID');
  const String messagingSenderIdEnv = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  const String projectIdEnv = String.fromEnvironment('FIREBASE_PROJECT_ID');
  const String storageBucketEnv = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
  );
  const String authDomainEnv = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  const String databaseUrlEnv = String.fromEnvironment('FIREBASE_DATABASE_URL');

  final bool hasFirebaseOptions =
      apiKeyEnv.isNotEmpty &&
      appIdEnv.isNotEmpty &&
      messagingSenderIdEnv.isNotEmpty &&
      projectIdEnv.isNotEmpty;

  final FirebaseOptions firebaseOptions = FirebaseOptions(
    apiKey: hasFirebaseOptions ? apiKeyEnv : "any-key",
    appId: hasFirebaseOptions ? appIdEnv : "uni-schedule-app",
    messagingSenderId: hasFirebaseOptions ? messagingSenderIdEnv : "any-id",
    projectId: hasFirebaseOptions ? projectIdEnv : "uni-schedule-dev",
    storageBucket: storageBucketEnv.isNotEmpty
        ? storageBucketEnv
        : "uni-schedule-dev.appspot.com",
    authDomain: authDomainEnv.isNotEmpty ? authDomainEnv : null,
    databaseURL: databaseUrlEnv.isNotEmpty ? databaseUrlEnv : null,
  );

  if (useEmulators || hasFirebaseOptions) {
    await Firebase.initializeApp(options: firebaseOptions);
  } else {
    await Firebase.initializeApp();
  }

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
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<AuthCubit>()),
        BlocProvider(create: (_) => getIt<SettingsCubit>()),
      ],
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settingsState) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Uni Schedule',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: settingsState.themeMode,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: settingsState.locale,
            home: BlocBuilder<AuthCubit, AuthState>(
              builder: (context, authState) {
                return authState.maybeWhen(
                  authenticated: (user) => _RootScaffold(userRole: user.role),
                  orElse: () => const StartupScreen(),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _RootScaffold extends StatefulWidget {
  final String userRole;
  const _RootScaffold({required this.userRole});

  @override
  State<_RootScaffold> createState() => _RootScaffoldState();
}

class _RootScaffoldState extends State<_RootScaffold> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.userRole == AppConstants.teacherRole ? 1 : 0;
  }

  static const _pages = [
    StudentScheduleScreen(),
    TeacherScheduleScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.school_outlined),
            selectedIcon: const Icon(Icons.school),
            label: l10n.students,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: l10n.teachers,
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: l10n.settings,
          ),
        ],
      ),
    );
  }
}
