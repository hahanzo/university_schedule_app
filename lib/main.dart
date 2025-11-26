import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/schedule/presentation/bloc/schedule_bloc.dart';
import 'features/schedule/data/datasources/schedule_local_datasource.dart';
import 'features/schedule/data/repositories/schedule_repository_impl.dart';
import 'features/schedule/presentation/page/home_page.dart';

void main() {
  // 1. Створюємо DataSource
  final dataSource = ScheduleLocalDataSourceImpl();
  
  // 2. Створюємо Repository
  final repository = ScheduleRepositoryImpl(localDataSource: dataSource);

  runApp(
    MaterialApp(
      home: BlocProvider(
        // 3. Створюємо BLoC і даємо йому репозиторій
        create: (context) => ScheduleBloc(repository: repository),
        child: const HomePage(),
      ),
    ),
  );
}
