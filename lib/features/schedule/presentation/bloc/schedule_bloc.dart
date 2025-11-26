import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/lesson_entity.dart';
import '../../domain/repositories/schedule_repository.dart';

// --- EVENTS ---
abstract class ScheduleEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class LoadSchedule extends ScheduleEvent {
  final String groupId;
  final int dayOfWeek;      
  final String currentWeek;

  LoadSchedule({
    required this.groupId,
    required this.dayOfWeek,
    required this.currentWeek,
  });
}

// --- STATES ---
abstract class ScheduleState extends Equatable {
  @override
  List<Object> get props => [];
}

class ScheduleInitial extends ScheduleState {}
class ScheduleLoading extends ScheduleState {}
class ScheduleError extends ScheduleState {
  final String message;
  ScheduleError(this.message);
}
class ScheduleLoaded extends ScheduleState {
  final List<LessonEntity> lessons;
  ScheduleLoaded(this.lessons);
}

// --- BLOC ---
class ScheduleBloc extends Bloc<ScheduleEvent, ScheduleState> {
  final ScheduleRepository repository;

  ScheduleBloc({required this.repository}) : super(ScheduleInitial()) {
    on<LoadSchedule>(_onLoadSchedule);
  }

  Future<void> _onLoadSchedule(
    LoadSchedule event, 
    Emitter<ScheduleState> emit
  ) async {
    emit(ScheduleLoading());
    try {
      final allLessons = await repository.getScheduleForGroup(event.groupId);

      final filteredLessons = allLessons.where((l) {
        final isDayMatch = l.dayOfWeek == event.dayOfWeek;
        final isWeekMatch = l.weekType == 'all' || l.weekType == event.currentWeek;
        return isDayMatch && isWeekMatch;
      }).toList();

      filteredLessons.sort((a, b) => a.lessonNumber.compareTo(b.lessonNumber));

      emit(ScheduleLoaded(filteredLessons));
    } catch (e) {
      debugPrint("Error to doing schedule loading: $e");
      emit(ScheduleError("Не вдалося завантажити розклад"));
    }
  }
}