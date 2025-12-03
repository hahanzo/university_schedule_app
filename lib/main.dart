import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/app_theme.dart';
import 'features/schedule/data/datasources/schedule_local_datasource.dart';
import 'features/schedule/data/repositories/schedule_repository_impl.dart';
import 'features/schedule/domain/repositories/schedule_repository.dart';
import 'features/schedule/presentation/bloc/schedule_bloc.dart';
import 'features/schedule/presentation/page/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dataSource = ScheduleLocalDataSourceImpl();
  final repository = ScheduleRepositoryImpl(localDataSource: dataSource);

  runApp(
    RepositoryProvider<ScheduleRepository>(
      create: (context) => repository,
      child: const UniversityApp(),
    ),
  );
}

class UniversityApp extends StatelessWidget {
  const UniversityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Розклад Університету',
      theme: AppTheme.lightTheme,
      home: BlocProvider(
        create: (context) {
          try {
            final repo = context.read<ScheduleRepository>();
            return ScheduleBloc(repository: repo);
          } catch (e) {
            print("Error: $e");
            rethrow;
          }
        },
        child: const HomePage(),
      ),
    );
  }
}