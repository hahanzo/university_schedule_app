import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/schedule/presentation/bloc/schedule_bloc.dart';
import 'features/schedule/data/datasources/schedule_local_datasource.dart';
import 'features/schedule/data/repositories/schedule_repository_impl.dart';
import 'features/schedule/presentation/page/home_page.dart';

void main() {
  final dataSource = ScheduleLocalDataSourceImpl();
  
  final repository = ScheduleRepositoryImpl(localDataSource: dataSource);

  runApp(
    MaterialApp(
      home: BlocProvider(
        create: (context) => ScheduleBloc(repository: repository),
        child: const HomePage(),
      ),
    ),
  );
}
