import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/filter_keys.dart';
import '../../../../core/utils/date_extensions.dart';
import '../../../../domain/repositories/schedule_repository.dart';
import '../../../../data/models/lesson_dto.dart';
import '../utils/schedule_list_builder.dart';
import 'schedule_state.dart';

/// Cubit for the teacher schedule screen.
/// Works identically to [ScheduleCubit] but fetches by teacherId instead of groupId,
/// and uses [FilterKeys.group] instead of [FilterKeys.teacher] for filtering.
class TeacherScheduleCubit extends Cubit<ScheduleState> {
  final ScheduleRepository _repository;

  StreamSubscription<List<LessonDto>>? _watchSubscription;
  List<String> _watchedTeacherIds = [];

  static const _listEq = ListEquality<String>();

  TeacherScheduleCubit(this._repository) : super(const ScheduleState.initial());

  LoadedScheduleState? get _loaded => state.loadedOrNull;

  @override
  Future<void> close() {
    _watchSubscription?.cancel();
    return super.close();
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<void> loadTeacher(String teacherId) =>
      loadMultipleTeachers([teacherId]);

  /// Returns available teachers map (id → name) for UI pickers.
  Future<Map<String, String>> getAvailableTeachers() =>
      _repository.getAllAvailableTeachers();

  Future<void> loadMultipleTeachers(List<String> teacherIds) async {
    final currentDate = _loaded?.selectedDate ?? DateTime.now().closestWorkday;

    emit(const ScheduleState.loading());
    try {
      // availableGroups reused to hold available teacher ids; availableTeachers map held separately
      final teacherMap = await _repository.getAllAvailableTeachers();
      final lessons = await _fetchLessonsForTeachers(teacherIds);

      _emitLoadedState(
        allLessons: lessons,
        filteredLessons: lessons,
        selectedGroup: teacherIds,           // "selectedGroup" holds teacher IDs
        availableGroups: teacherMap.keys.toList(), // available teacher IDs
        activeFilters: {},
        selectedDate: currentDate,
      );

      _subscribeToUpdates(teacherIds);
    } catch (e) {
      emit(ScheduleState.error(e.toString()));
    }
  }

  Future<void> reloadFromCache() async {
    final s = _loaded;
    final teacherIds = s?.selectedGroup ?? [];
    final currentDate = s?.selectedDate ?? DateTime.now().closestWorkday;
    var availableTeacherIds = s?.availableGroups ?? [];
    final activeFilters = s?.activeFilters ?? {};

    if (teacherIds.isEmpty) return;

    try {
      final lessons = await _fetchLessonsFromCache(teacherIds);

      if (availableTeacherIds.isEmpty) {
        final map = await _repository.getAllAvailableTeachersFromCache();
        availableTeacherIds = map.keys.toList();
      }

      _emitLoadedState(
        allLessons: lessons,
        filteredLessons: lessons,
        selectedGroup: teacherIds,
        availableGroups: availableTeacherIds,
        activeFilters: activeFilters,
        selectedDate: currentDate,
      );
    } catch (e) {
      emit(ScheduleState.error(e.toString()));
    }
  }

  void changeDate(DateTime newDate) {
    final s = _loaded;
    if (s == null) return;
    _emitFromLoaded(s, selectedDate: newDate);
  }

  void searchLessons(String query) {
    final s = _loaded;
    if (s == null) return;

    if (query.isEmpty) {
      _emitFromLoaded(s, filteredLessons: s.allLessons);
      return;
    }

    final lowerQuery = query.toLowerCase();
    final filtered = s.allLessons.where((lesson) {
      return '${lesson.subjectName} ${lesson.groupId}'
          .toLowerCase()
          .contains(lowerQuery);
    }).toList();

    _emitFromLoaded(s, filteredLessons: filtered);
  }

  void applyFilter({String? group, String? subject, String? time}) {
    final s = _loaded;
    if (s == null) return;

    final updatedFilters = Map<String, String?>.from(s.activeFilters);
    if (group != null) updatedFilters[FilterKeys.group] = group;
    if (subject != null) updatedFilters[FilterKeys.subject] = subject;
    if (time != null) updatedFilters[FilterKeys.time] = time;

    final filtered = _applyFiltersToLessons(s.allLessons, updatedFilters);
    _emitFromLoaded(s, filteredLessons: filtered, activeFilters: updatedFilters);
  }

  void clearFilter(String filterKey) {
    final s = _loaded;
    if (s == null) return;

    final updatedFilters = Map<String, String?>.from(s.activeFilters)
      ..remove(filterKey);
    final filtered = _applyFiltersToLessons(s.allLessons, updatedFilters);
    _emitFromLoaded(s, filteredLessons: filtered, activeFilters: updatedFilters);
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  Future<List<LessonDto>> _fetchLessonsForTeachers(List<String> teacherIds) async {
    final results = await Future.wait(
      teacherIds.map((id) => _repository.getScheduleByTeacher(id)),
    );
    return results.expand((l) => l).toList()
      ..sort((a, b) => a.lessonNumber.compareTo(b.lessonNumber));
  }

  Future<List<LessonDto>> _fetchLessonsFromCache(List<String> teacherIds) async {
    final results = await Future.wait(
      teacherIds.map((id) => _repository.getScheduleByTeacherFromCache(id)),
    );
    return results.expand((l) => l).toList()
      ..sort((a, b) => a.lessonNumber.compareTo(b.lessonNumber));
  }

  void _subscribeToUpdates(List<String> teacherIds) {
    if (_watchSubscription != null &&
        _listEq.equals(
          [..._watchedTeacherIds]..sort(),
          [...teacherIds]..sort(),
        )) {
      return;
    }

    _watchSubscription?.cancel();
    _watchedTeacherIds = teacherIds;

    if (teacherIds.isEmpty) return;

    final stream = teacherIds.length == 1
        ? _repository.watchScheduleByTeacher(teacherIds.first)
        : _mergeTeacherStreams(teacherIds);

    _watchSubscription = stream.listen(
      (remoteData) {
        final s = _loaded;
        if (s == null) return;
        if (_lessonsAreDifferent(s.allLessons, remoteData)) {
          final filtered = _applyFiltersToLessons(remoteData, s.activeFilters);
          _emitFromLoaded(s, allLessons: remoteData, filteredLessons: filtered);
        }
      },
      onError: (_) {},
    );
  }

  Stream<List<LessonDto>> _mergeTeacherStreams(List<String> teacherIds) {
    final streams = teacherIds.map(_repository.watchScheduleByTeacher).toList();
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
      if (filters[FilterKeys.group] != null) {
        final allowedGroups = filters[FilterKeys.group]!.split(',');
        if (!allowedGroups.contains(lesson.groupId)) {
          return false;
        }
      }
      if (filters[FilterKeys.subject] != null &&
          lesson.subjectName != filters[FilterKeys.subject]) {
        return false;
      }
      if (filters[FilterKeys.time] != null &&
          lesson.timeStart != filters[FilterKeys.time]) {
        return false;
      }
      return true;
    }).toList();
  }

  bool _lessonsAreDifferent(List<LessonDto> a, List<LessonDto> b) {
    if (a.length != b.length) return true;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return true;
    }
    return false;
  }

  void _emitFromLoaded(
    LoadedScheduleState s, {
    List<LessonDto>? allLessons,
    List<LessonDto>? filteredLessons,
    List<String>? selectedGroup,
    List<String>? availableGroups,
    Map<String, String?>? activeFilters,
    DateTime? selectedDate,
  }) {
    _emitLoadedState(
      allLessons: allLessons ?? s.allLessons,
      filteredLessons: filteredLessons ?? s.filteredLessons,
      selectedGroup: selectedGroup ?? s.selectedGroup,
      availableGroups: availableGroups ?? s.availableGroups,
      activeFilters: activeFilters ?? s.activeFilters,
      selectedDate: selectedDate ?? s.selectedDate,
    );
  }

  void _emitLoadedState({
    required List<LessonDto> allLessons,
    required List<LessonDto> filteredLessons,
    required List<String> selectedGroup,
    required List<String> availableGroups,
    required Map<String, String?> activeFilters,
    required DateTime selectedDate,
  }) {
    final isGlobalSearch =
        filteredLessons.length != allLessons.length || activeFilters.isNotEmpty;

    final scheduleItems = ScheduleListBuilder.buildList(
      allLessons: allLessons,
      filteredLessons: filteredLessons,
      selectedGroup: selectedGroup,
      activeFilters: activeFilters,
      selectedDate: selectedDate,
      isTeacherMode: true,
    );

    emit(ScheduleState.loaded(
      allLessons: allLessons,
      filteredLessons: filteredLessons,
      selectedGroup: selectedGroup,
      availableGroups: availableGroups,
      activeFilters: activeFilters,
      selectedDate: selectedDate,
      isGlobalSearch: isGlobalSearch,
      scheduleItems: scheduleItems,
    ));
  }
}
