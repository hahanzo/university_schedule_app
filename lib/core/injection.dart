import 'package:university_schedule_app/data/repositories/schedule_repository_impl.dart';
import 'package:university_schedule_app/domain/repositories/schedule_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';

final GetIt getIt = GetIt.instance;

Future<void> configureDependencies() async {
  final firestore = FirebaseFirestore.instance;

  //flutter run --dart-define=FIRESTORE_IP=<IP_ADDRESS>
  const String host = String.fromEnvironment(
    'FIRESTORE_IP', 
    defaultValue: 'localhost',
  );
  
  firestore.useFirestoreEmulator(host, 8080);
  
  firestore.settings = const Settings(
    persistenceEnabled: false,
  );

  getIt.registerSingleton<FirebaseFirestore>(firestore);

  getIt.registerLazySingleton<ScheduleRepository>(
    () => ScheduleRepositoryImpl(getIt<FirebaseFirestore>()),
  );
}