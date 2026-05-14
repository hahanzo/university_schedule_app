import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/schedule_repository.dart';
import 'schedule_state.dart';

class ScheduleCubit extends Cubit<ScheduleState> {
  final ScheduleRepository _repository;

  ScheduleCubit(this._repository) : super(const ScheduleState.initial());

  Future<void> loadSchedule(String groupId) async {
    emit(const ScheduleState.loading());
    try {
      final lessons = await _repository.getScheduleByGroup(groupId);
      lessons.sort((a, b) => a.lessonNumber.compareTo(b.lessonNumber));
      
      emit(ScheduleState.loaded(
        allLessons: lessons, 
        filteredLessons: lessons,
        selectedGroup: [groupId],
      ));
    } catch (e) {
      emit(ScheduleState.error(e.toString()));
    }
  }

  void searchLessons(String query) {
    state.maybeWhen(
      loaded: (allLessons, _, selectedGroup) { 
        if (query.isEmpty) {
          emit(ScheduleState.loaded(
            allLessons: allLessons, 
            filteredLessons: allLessons,
            selectedGroup: selectedGroup, 
          ));
          return;
        }

        final filtered = allLessons.where((lesson) {
          final searchTarget = "${lesson.subjectName} ${lesson.teacherName}".toLowerCase();
          return searchTarget.contains(query.toLowerCase());
        }).toList();

        emit(ScheduleState.loaded(
          allLessons: allLessons, 
          filteredLessons: filtered,
          selectedGroup: selectedGroup,
        ));
      },
      orElse: () {},
    );
  }

  void applyFilter({String? teacher, String? group, String? subject, String? time, int? dayOfWeek}) {
    state.maybeWhen(
      loaded: (allLessons, _, selectedGroup) {
        final filtered = allLessons.where((lesson) {
          bool matches = true;
          if (teacher != null) matches &= lesson.teacherName == teacher;
          if (group != null) matches &= lesson.groupId == group;
          if (subject != null) matches &= lesson.subjectName == subject;
          if (time != null) matches &= lesson.timeStart == time;
          if (dayOfWeek != null) matches &= lesson.dayOfWeek == dayOfWeek;
          return matches;
        }).toList();

        emit(ScheduleState.loaded(
          allLessons: allLessons, 
          filteredLessons: filtered, 
          selectedGroup: selectedGroup,
        ));
      },
      orElse: () {},
    );
  }
}