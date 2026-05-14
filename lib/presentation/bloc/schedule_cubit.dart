import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../../data/models/lesson_dto.dart';
import 'schedule_state.dart';

class ScheduleCubit extends Cubit<ScheduleState> {
  final ScheduleRepository _repository;

  ScheduleCubit(this._repository) : super(const ScheduleState.initial());

  Future<void> loadSchedule(String groupId) async {
    await loadMultipleGroups([groupId]);
  }

  Future<void> loadMultipleGroups(List<String> groupIds) async {
    emit(const ScheduleState.loading());
    try {
      // Get available groups
      final availableGroups = await _repository.getAllAvailableGroups();
      
      final List<LessonDto> allLessonsData = [];

      for (final groupId in groupIds) {
        final lessons = await _repository.getScheduleByGroup(groupId);
        allLessonsData.addAll(lessons);
      }

      // Sort by lesson number
      allLessonsData.sort((a, b) => a.lessonNumber.compareTo(b.lessonNumber));

      emit(ScheduleState.loaded(
        allLessons: allLessonsData,
        filteredLessons: allLessonsData,
        selectedGroup: groupIds,
        availableGroups: availableGroups,
        activeFilters: {}, // Initialize empty filters
      ));
    } catch (e) {
      emit(ScheduleState.error(e.toString()));
    }
  }

  void addGroup(String groupId) {
    state.maybeWhen(
      // When adding a group, preserve current active filters
      loaded: (allLessons, filteredLessons, selectedGroup, availableGroups, activeFilters) {
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
      // When removing a group, preserve current active filters
      loaded: (allLessons, filteredLessons, selectedGroup, availableGroups, activeFilters) {
        // Ensure at least one group is selected
        if (selectedGroup.length > 1) {
          final updatedGroups = selectedGroup.where((g) => g != groupId).toList();
          loadMultipleGroups(updatedGroups);
        }
      },
      orElse: () {},
    );
  }

  void searchLessons(String query) {
    state.maybeWhen(
      loaded: (allLessons, _, selectedGroup, availableGroups, activeFilters) {
        if (query.isEmpty) {
          emit(ScheduleState.loaded(
            allLessons: allLessons,
            filteredLessons: allLessons,
            selectedGroup: selectedGroup,
            availableGroups: availableGroups,
            activeFilters: activeFilters,
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
          availableGroups: availableGroups,
          activeFilters: activeFilters,
        ));
      },
      orElse: () {},
    );
  }

  // Apply a filter: teacher, subject, or time
  // Uses AND logic: all active filters must match a lesson
  void applyFilter({String? teacher, String? subject, String? time}) {
    state.maybeWhen(
      loaded: (allLessons, _, selectedGroup, availableGroups, activeFilters) {
        // Update the active filters map
        final updatedFilters = Map<String, String?>.from(activeFilters);
        
        if (teacher != null) updatedFilters['teacher'] = teacher;
        if (subject != null) updatedFilters['subject'] = subject;
        if (time != null) updatedFilters['time'] = time;

        // Apply all active filters to allLessons (AND logic)
        final filtered = allLessons.where((lesson) {
          bool matches = true;
          
          // All active filters must match
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

        emit(ScheduleState.loaded(
          allLessons: allLessons,
          filteredLessons: filtered,
          selectedGroup: selectedGroup,
          availableGroups: availableGroups,
          activeFilters: updatedFilters,
        ));
      },
      orElse: () {},
    );
  }

  // Clear a specific filter by key (teacher, subject, or time)
  void clearFilter(String filterKey) {
    state.maybeWhen(
      loaded: (allLessons, _, selectedGroup, availableGroups, activeFilters) {
        // Remove the filter from active filters
        final updatedFilters = Map<String, String?>.from(activeFilters);
        updatedFilters.remove(filterKey);

        // Reapply all remaining active filters (AND logic)
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

        emit(ScheduleState.loaded(
          allLessons: allLessons,
          filteredLessons: filtered,
          selectedGroup: selectedGroup,
          availableGroups: availableGroups,
          activeFilters: updatedFilters,
        ));
      },
      orElse: () {},
    );
  }
}