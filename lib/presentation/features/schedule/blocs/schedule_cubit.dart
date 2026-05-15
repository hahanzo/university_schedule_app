import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/repositories/schedule_repository.dart';
import '../../../../data/models/lesson_dto.dart';
import '../utils/schedule_list_builder.dart';
import 'schedule_state.dart';

class ScheduleCubit extends Cubit<ScheduleState> {
  final ScheduleRepository _repository;

  ScheduleCubit(this._repository) : super(const ScheduleState.initial());

  Future<void> loadSchedule(String groupId) async {
    await loadMultipleGroups([groupId]);
  }

  Future<void> loadMultipleGroups(List<String> groupIds) async {
    // Preserve existing date if reloading
    DateTime currentDate = DateTime.now();
    state.maybeWhen(
      loaded: (_, __, ___, ____, _____, date, ______, _______) =>
          currentDate = date,
      orElse: () {},
    );

    emit(const ScheduleState.loading());
    try {
      final availableGroups = await _repository.getAllAvailableGroups();

      final List<LessonDto> allLessonsData = [];
      for (final groupId in groupIds) {
        final lessons = await _repository.getScheduleByGroup(groupId);
        allLessonsData.addAll(lessons);
      }

      allLessonsData.sort((a, b) => a.lessonNumber.compareTo(b.lessonNumber));

      _emitLoadedState(
        allLessons: allLessonsData,
        filteredLessons: allLessonsData,
        selectedGroup: groupIds,
        availableGroups: availableGroups,
        activeFilters: {},
        selectedDate: currentDate,
      );
    } catch (e) {
      emit(ScheduleState.error(e.toString()));
    }
  }

  void changeDate(DateTime newDate) {
    state.maybeWhen(
      loaded:
          (
            all,
            filtered,
            selectedGroup,
            availableGroups,
            activeFilters,
            _,
            isGlobal,
            items,
          ) {
            _emitLoadedState(
              allLessons: all,
              filteredLessons: filtered,
              selectedGroup: selectedGroup,
              availableGroups: availableGroups,
              activeFilters: activeFilters,
              selectedDate: newDate,
            );
          },
      orElse: () {},
    );
  }

  void addGroup(String groupId) {
    state.maybeWhen(
      loaded: (_, __, selectedGroup, ___, ____, _____, ______, _______) {
        if (!selectedGroup.contains(groupId)) {
          final updatedGroups = [...selectedGroup, groupId];
          loadMultipleGroups(updatedGroups);
        }
      },
      orElse: () {},
    );
  }

  void removeGroup(String groupId) {
    state.maybeWhen(
      loaded: (_, __, selectedGroup, ___, ____, _____, ______, _______) {
        if (selectedGroup.length > 1) {
          final updatedGroups = selectedGroup
              .where((g) => g != groupId)
              .toList();
          loadMultipleGroups(updatedGroups);
        }
      },
      orElse: () {},
    );
  }

  void searchLessons(String query) {
    state.maybeWhen(
      loaded:
          (
            allLessons,
            _,
            selectedGroup,
            availableGroups,
            activeFilters,
            selectedDate,
            __,
            ___,
          ) {
            if (query.isEmpty) {
              _emitLoadedState(
                allLessons: allLessons,
                filteredLessons: allLessons,
                selectedGroup: selectedGroup,
                availableGroups: availableGroups,
                activeFilters: activeFilters,
                selectedDate: selectedDate,
              );
              return;
            }

            final filtered = allLessons.where((lesson) {
              final searchTarget = "${lesson.subjectName} ${lesson.teacherName}"
                  .toLowerCase();
              return searchTarget.contains(query.toLowerCase());
            }).toList();

            _emitLoadedState(
              allLessons: allLessons,
              filteredLessons: filtered,
              selectedGroup: selectedGroup,
              availableGroups: availableGroups,
              activeFilters: activeFilters,
              selectedDate: selectedDate,
            );
          },
      orElse: () {},
    );
  }

  void applyFilter({String? teacher, String? subject, String? time}) {
    state.maybeWhen(
      loaded:
          (
            allLessons,
            _,
            selectedGroup,
            availableGroups,
            activeFilters,
            selectedDate,
            __,
            ___,
          ) {
            final updatedFilters = Map<String, String?>.from(activeFilters);

            if (teacher != null) updatedFilters['teacher'] = teacher;
            if (subject != null) updatedFilters['subject'] = subject;
            if (time != null) updatedFilters['time'] = time;

            final filtered = allLessons.where((lesson) {
              bool matches = true;
              if (updatedFilters['teacher'] != null) {
                matches &= lesson.teacherName == updatedFilters['teacher'];
              }
              if (updatedFilters['subject'] != null) {
                matches &= lesson.subjectName == updatedFilters['subject'];
              }
              if (updatedFilters['time'] != null) {
                matches &= lesson.timeStart == updatedFilters['time'];
              }
              return matches;
            }).toList();

            _emitLoadedState(
              allLessons: allLessons,
              filteredLessons: filtered,
              selectedGroup: selectedGroup,
              availableGroups: availableGroups,
              activeFilters: updatedFilters,
              selectedDate: selectedDate,
            );
          },
      orElse: () {},
    );
  }

  void clearFilter(String filterKey) {
    state.maybeWhen(
      loaded:
          (
            allLessons,
            _,
            selectedGroup,
            availableGroups,
            activeFilters,
            selectedDate,
            __,
            ___,
          ) {
            final updatedFilters = Map<String, String?>.from(activeFilters);
            updatedFilters.remove(filterKey);

            final filtered = allLessons.where((lesson) {
              bool matches = true;
              if (updatedFilters['teacher'] != null) {
                matches &= lesson.teacherName == updatedFilters['teacher'];
              }
              if (updatedFilters['subject'] != null) {
                matches &= lesson.subjectName == updatedFilters['subject'];
              }
              if (updatedFilters['time'] != null) {
                matches &= lesson.timeStart == updatedFilters['time'];
              }
              return matches;
            }).toList();

            _emitLoadedState(
              allLessons: allLessons,
              filteredLessons: filtered,
              selectedGroup: selectedGroup,
              availableGroups: availableGroups,
              activeFilters: updatedFilters,
              selectedDate: selectedDate,
            );
          },
      orElse: () {},
    );
  }

  // --- Helper to build schedule items and emit state ---
  void _emitLoadedState({
    required List<LessonDto> allLessons,
    required List<LessonDto> filteredLessons,
    required List<String> selectedGroup,
    required List<String> availableGroups,
    required Map<String, String?> activeFilters,
    required DateTime selectedDate,
  }) {
    final bool isSearching = filteredLessons.length != allLessons.length;
    final bool isGlobalSearch = isSearching || activeFilters.isNotEmpty;

    final scheduleItems = ScheduleListBuilder.buildList(
      allLessons: allLessons,
      filteredLessons: filteredLessons,
      selectedGroup: selectedGroup,
      activeFilters: activeFilters,
      selectedDate: selectedDate,
    );

    emit(
      ScheduleState.loaded(
        allLessons: allLessons,
        filteredLessons: filteredLessons,
        selectedGroup: selectedGroup,
        availableGroups: availableGroups,
        activeFilters: activeFilters,
        selectedDate: selectedDate,
        isGlobalSearch: isGlobalSearch,
        scheduleItems: scheduleItems,
      ),
    );
  }
}
