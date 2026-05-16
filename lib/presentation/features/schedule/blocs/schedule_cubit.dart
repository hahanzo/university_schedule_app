import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/date_extensions.dart';
import '../../../../domain/repositories/schedule_repository.dart';
import '../../../../data/models/lesson_dto.dart';
import '../utils/schedule_list_builder.dart';
import 'schedule_state.dart';

class ScheduleCubit extends Cubit<ScheduleState> {
  final ScheduleRepository _repository;

  // Active stream subscriptions keyed by group id list hash
  StreamSubscription<List<LessonDto>>? _watchSubscription;
  List<String> _watchedGroupIds = [];

  ScheduleCubit(this._repository) : super(const ScheduleState.initial());

  @override
  Future<void> close() {
    _watchSubscription?.cancel();
    return super.close();
  }

  Future<void> loadSchedule(String groupId) async {
    await loadMultipleGroups([groupId]);
  }

  Future<void> loadMultipleGroups(List<String> groupIds) async {
    // Default to today but skip weekends; preserve date if already loaded
    DateTime currentDate = DateTime.now().closestWorkday;
    state.maybeWhen(
      loaded: (_, __, ___, ____, _____, date, ______, _______) =>
          currentDate = date,
      orElse: () {},
    );

    emit(const ScheduleState.loading());
    try {
      final availableGroups = await _repository.getAllAvailableGroups();
      final lessons = await _fetchLessonsForGroups(groupIds);

      _emitLoadedState(
        allLessons: lessons,
        filteredLessons: lessons,
        selectedGroup: groupIds,
        availableGroups: availableGroups,
        activeFilters: {},
        selectedDate: currentDate,
      );

      // Subscribe to real-time updates for auto-sync when remote data changes
      _subscribeToUpdates(groupIds, availableGroups, currentDate);
    } catch (e) {
      emit(ScheduleState.error(e.toString()));
    }
  }

  // Pull-to-refresh: reads from local cache, preserves current date and filters
  Future<void> reloadFromCache() async {
    final currentState = state;
    List<String> groupIds = ['КН-11-1'];
    DateTime currentDate = DateTime.now().closestWorkday;
    List<String> availableGroups = [];
    Map<String, String?> activeFilters = {};

    currentState.maybeWhen(
      loaded: (a, b, selectedGroup, avGroups, filters, date, c, d) {
        groupIds = selectedGroup;
        currentDate = date;
        availableGroups = avGroups;
        activeFilters = filters;
      },
      orElse: () {},
    );

    try {
      final lessons = await _fetchLessonsFromCache(groupIds);

      // If cache was empty (first launch), also refresh groups list
      if (availableGroups.isEmpty) {
        availableGroups = await _repository.getAllAvailableGroupsFromCache();
      }

      _emitLoadedState(
        allLessons: lessons,
        filteredLessons: lessons,
        selectedGroup: groupIds,
        availableGroups: availableGroups,
        activeFilters: activeFilters,
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
          loadMultipleGroups([...selectedGroup, groupId]);
        }
      },
      orElse: () {},
    );
  }

  void removeGroup(String groupId) {
    state.maybeWhen(
      loaded: (_, __, selectedGroup, ___, ____, _____, ______, _______) {
        if (selectedGroup.length > 1) {
          loadMultipleGroups(selectedGroup.where((g) => g != groupId).toList());
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
              final searchTarget = '${lesson.subjectName} ${lesson.teacherName}'
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

            final filtered = _applyFiltersToLessons(allLessons, updatedFilters);

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
            final updatedFilters = Map<String, String?>.from(activeFilters)
              ..remove(filterKey);
            final filtered = _applyFiltersToLessons(allLessons, updatedFilters);

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

  // --- Private helpers ---

  Future<List<LessonDto>> _fetchLessonsForGroups(List<String> groupIds) async {
    final results = await Future.wait(
      groupIds.map((id) => _repository.getScheduleByGroup(id)),
    );
    final lessons = results.expand((l) => l).toList()
      ..sort((a, b) => a.lessonNumber.compareTo(b.lessonNumber));
    return lessons;
  }

  Future<List<LessonDto>> _fetchLessonsFromCache(List<String> groupIds) async {
    final results = await Future.wait(
      groupIds.map((id) => _repository.getScheduleByGroupFromCache(id)),
    );
    final lessons = results.expand((l) => l).toList()
      ..sort((a, b) => a.lessonNumber.compareTo(b.lessonNumber));
    return lessons;
  }

  // Subscribes to Firestore real-time stream. When remote data changes,
  // updates the local state automatically without user interaction.
  void _subscribeToUpdates(
    List<String> groupIds,
    List<String> availableGroups,
    DateTime initialDate,
  ) {
    // Cancel previous subscription if groups changed
    if (_watchedGroupIds.join(',') == groupIds.join(',') &&
        _watchSubscription != null) {
      return;
    }

    _watchSubscription?.cancel();
    _watchedGroupIds = groupIds;

    // For simplicity, watch the first group; extend to merge streams for multi-group
    if (groupIds.isEmpty) return;

    final mergedStream = groupIds.length == 1
        ? _repository.watchScheduleByGroup(groupIds.first)
        : _mergeGroupStreams(groupIds);

    _watchSubscription = mergedStream.listen(
      (remoteData) {
        // Only update if the remote data differs from what we have locally
        state.maybeWhen(
          loaded:
              (
                currentLessons,
                _,
                selectedGroup,
                avGroups,
                activeFilters,
                selectedDate,
                __,
                ___,
              ) {
                if (_lessonsAreDifferent(currentLessons, remoteData)) {
                  final filtered = _applyFiltersToLessons(
                    remoteData,
                    activeFilters,
                  );
                  _emitLoadedState(
                    allLessons: remoteData,
                    filteredLessons: filtered,
                    selectedGroup: selectedGroup,
                    availableGroups: avGroups,
                    activeFilters: activeFilters,
                    selectedDate: selectedDate,
                  );
                }
              },
          orElse: () {},
        );
      },
      onError: (_) {
        // Stream errors are non-fatal; cached data remains visible
      },
    );
  }

  // Merges multiple group streams into a single combined list stream.
  Stream<List<LessonDto>> _mergeGroupStreams(List<String> groupIds) {
    final streams = groupIds.map(_repository.watchScheduleByGroup).toList();
    final latestSnapshots = List<List<LessonDto>>.filled(streams.length, []);
    final controller = StreamController<List<LessonDto>>();

    for (int i = 0; i < streams.length; i++) {
      final index = i;
      streams[i].listen((data) {
        latestSnapshots[index] = data;
        if (!controller.isClosed) {
          controller.add(latestSnapshots.expand((l) => l).toList());
        }
      });
    }

    return controller.stream;
  }

  List<LessonDto> _applyFiltersToLessons(
    List<LessonDto> lessons,
    Map<String, String?> filters,
  ) {
    return lessons.where((lesson) {
      if (filters['teacher'] != null &&
          lesson.teacherName != filters['teacher']) {
        return false;
      }
      if (filters['subject'] != null &&
          lesson.subjectName != filters['subject']) {
        return false;
      }
      if (filters['time'] != null && lesson.timeStart != filters['time']) {
        return false;
      }
      return true;
    }).toList();
  }

  // Simple check: compare counts and spot-check a few fields to detect changes.
  bool _lessonsAreDifferent(List<LessonDto> a, List<LessonDto> b) {
    if (a.length != b.length) return true;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return true;
    }
    return false;
  }

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
