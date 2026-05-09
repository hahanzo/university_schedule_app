import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';

final GetIt getIt = GetIt.instance;

Future<void> configureDependencies() async {
  final firestore = FirebaseFirestore.instance;

  const String host = "10.0.2.2"; 
  
  firestore.useFirestoreEmulator(host, 8080);
  
  firestore.settings = const Settings(
    persistenceEnabled: false,
  );

  getIt.registerSingleton<FirebaseFirestore>(firestore);

  // getIt.registerLazySingleton<ScheduleRepository>(() => ScheduleRepositoryImpl(getIt()));
}