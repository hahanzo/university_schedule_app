import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import '../data/repositories/schedule_repository_impl.dart';
import '../domain/repositories/schedule_repository.dart';
import '../presentation/features/schedule/blocs/schedule_cubit.dart';

final GetIt getIt = GetIt.instance;

Future<void> configureDependencies() async {
  final firestore = FirebaseFirestore.instance;

  //flutter run --dart-define=FIRESTORE_IP=<IP_ADDRESS>
  const String host = String.fromEnvironment(
    'FIRESTORE_IP', 
    defaultValue: 'localhost',
  );
  
  firestore.useFirestoreEmulator(host, 8080);

  // Enable local disk cache — all Firestore reads are persisted offline
  firestore.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  getIt.registerSingleton<FirebaseFirestore>(firestore);

  getIt.registerLazySingleton<ScheduleRepository>(
    () => ScheduleRepositoryImpl(getIt<FirebaseFirestore>()),
  );

  getIt.registerSingleton<ScheduleCubit>(
    ScheduleCubit(getIt<ScheduleRepository>()),
  );
}