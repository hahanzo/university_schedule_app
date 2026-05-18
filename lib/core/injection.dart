import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';

import '../data/repositories/schedule_repository_impl.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/repositories/schedule_repository.dart';
import '../domain/repositories/auth_repository.dart';
import '../presentation/features/schedule/blocs/student_schedule_cubit.dart';
import '../presentation/features/schedule/blocs/teacher_schedule_cubit.dart';
import '../presentation/features/auth/blocs/auth_cubit.dart';
import '../presentation/features/settings/blocs/settings_cubit.dart';

final GetIt getIt = GetIt.instance;

Future<void> configureDependencies() async {
  final firestore = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;
  final storage = FirebaseStorage.instance;

  const bool useEmulators =
      bool.fromEnvironment('USE_FIREBASE_EMULATORS', defaultValue: true);
  const String emulatorHostEnv =
      String.fromEnvironment('FIREBASE_EMULATOR_HOST');
  const String firestoreHostEnv = String.fromEnvironment('FIRESTORE_IP');
  final String emulatorHost = emulatorHostEnv.isNotEmpty
      ? emulatorHostEnv
      : (firestoreHostEnv.isNotEmpty ? firestoreHostEnv : '10.0.2.2');

  if (useEmulators) {
    firestore.useFirestoreEmulator(emulatorHost, 8080);
    auth.useAuthEmulator(emulatorHost, 9099);
    storage.useStorageEmulator(emulatorHost, 9199);
  }

  firestore.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  getIt.registerSingleton<FirebaseFirestore>(firestore);
  getIt.registerSingleton<FirebaseAuth>(auth);
  getIt.registerSingleton<FirebaseStorage>(storage);

  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      getIt<FirebaseAuth>(),
      getIt<FirebaseFirestore>(),
      getIt<FirebaseStorage>(),
    ),
  );

  getIt.registerLazySingleton<ScheduleRepository>(
    () => ScheduleRepositoryImpl(getIt<FirebaseFirestore>()),
  );

  getIt.registerSingleton<StudentScheduleCubit>(
    StudentScheduleCubit(getIt<ScheduleRepository>()),
  );

  getIt.registerSingleton<TeacherScheduleCubit>(
    TeacherScheduleCubit(getIt<ScheduleRepository>()),
  );

  getIt.registerSingleton<AuthCubit>(
    AuthCubit(getIt<AuthRepository>()),
  );

  getIt.registerSingleton<SettingsCubit>(
    SettingsCubit(),
  );
}