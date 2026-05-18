import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/filter_keys.dart';
import '../../../../core/utils/date_extensions.dart';
import '../../../../domain/repositories/schedule_repository.dart';
import '../../../../data/models/lesson_dto.dart';
import '../utils/schedule_list_builder.dart';
import 'schedule_state.dart';

class StudentScheduleCubit extends Cubit<ScheduleState> {
  final ScheduleRepository _repository;

  StreamSubscription<List<LessonDto>>? _watchSubscription;
  StreamController<List<LessonDto>>? _mergeController;
  List<List<StreamSubscription<List<LessonDto>>>> _mergeSubscriptions = [];
  List<String> _watchedGroupIds = [];

  static const _groupListEq = ListEquality<String>();

  StudentScheduleCubit(this._repository) : super(const ScheduleState.initial());

  // Shortcut to the current loaded state; null when not in loaded state.
  LoadedScheduleState? get _loaded => state.loadedOrNull;

  @override
  Future<void> close() {
    _watchSubscription?.cancel();
    _closeMergeController();
    return super.close();
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<void> loadSchedule(String groupId) =>
      loadMultipleGroups([groupId]);

  Future<void> loadMultipleGroups(List<String> groupIds) async {
    // Preserve current date when switching groups; fall back to today (workday).
    final currentDate = _loaded?.selectedDate ?? DateTime.now().closestWorkday;

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

      // Subscribe to real-time Firestore updates for automatic sync.
      _subscribeToUpdates(groupIds);
    } catch (e) {
      emit(ScheduleState.error(e.toString()));
    }
  }

  /// Pull-to-refresh: reads from local cache, preserves all current state.
  Future<void> reloadFromCache() async {
    final s = _loaded;
    final groupIds = s?.selectedGroup ?? [AppConstants.defaultGroupId];
    final currentDate = s?.selectedDate ?? DateTime.now().closestWorkday;
    var availableGroups = s?.availableGroups ?? [];
    final activeFilters = s?.activeFilters ?? {};

    try {
      final lessons = await _fetchLessonsFromCache(groupIds);

      // On first launch the cache may be empty — fetch group list from cache.
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
    final s = _loaded;
    if (s == null) return;
    _emitFromLoaded(s, selectedDate: newDate);
  }

  void addGroup(String groupId) {
    final s = _loaded;
    if (s == null || s.selectedGroup.contains(groupId)) return;
    loadMultipleGroups([...s.selectedGroup, groupId]);
  }

  void removeGroup(String groupId) {
    final s = _loaded;
    if (s == null || s.selectedGroup.length <= 1) return;
    loadMultipleGroups(s.selectedGroup.where((g) => g != groupId).toList());
  }

  void searchLessons(String query) {
    final s = _loaded;
    if (s == null) return;

    if (query.isEmpty) {
      _emitFromLoaded(s, filteredLessons: s.allLessons);
      return;
    }

    // Compute lowercase query once — not inside the loop.
    final lowerQuery = query.toLowerCase();
    final filtered = s.allLessons.where((lesson) {
      return '${lesson.subjectName} ${lesson.teacherName}'
          .toLowerCase()
          .contains(lowerQuery);
    }).toList();

    _emitFromLoaded(s, filteredLessons: filtered);
  }

  void applyFilter({String? teacher, String? subject, String? time}) {
    final s = _loaded;
    if (s == null) return;

    final updatedFilters = Map<String, String?>.from(s.activeFilters);
    if (teacher != null) updatedFilters[FilterKeys.teacher] = teacher;
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

  Future<List<LessonDto>> _fetchLessonsForGroups(List<String> groupIds) async {
    final results = await Future.wait(
      groupIds.map((id) => _repository.getScheduleByGroup(id)),
    );
    return results.expand((l) => l).toList()
      ..sort((a, b) => a.lessonNumber.compareTo(b.lessonNumber));
  }

  Future<List<LessonDto>> _fetchLessonsFromCache(List<String> groupIds) async {
    final results = await Future.wait(
      groupIds.map((id) => _repository.getScheduleByGroupFromCache(id)),
    );
    return results.expand((l) => l).toList()
      ..sort((a, b) => a.lessonNumber.compareTo(b.lessonNumber));
  }

  // Subscribes to Firestore real-time stream; auto-updates UI on remote changes.
  void _subscribeToUpdates(List<String> groupIds) {
    // Skip re-subscription when already watching exactly the same groups.
    if (_watchSubscription != null &&
        _groupListEq.equals(
          [..._watchedGroupIds]..sort(),
          [...groupIds]..sort(),
        )) {
      return;
    }

    _watchSubscription?.cancel();
    _closeMergeController();
    _watchedGroupIds = groupIds;

    if (groupIds.isEmpty) return;

    final stream = groupIds.length == 1
        ? _repository.watchScheduleByGroup(groupIds.first)
        : _mergeGroupStreams(groupIds);

    _watchSubscription = stream.listen(
      (remoteData) {
        final s = _loaded;
        if (s == null) return;
        if (_lessonsAreDifferent(s.allLessons, remoteData)) {
          final filtered = _applyFiltersToLessons(remoteData, s.activeFilters);
          _emitFromLoaded(s, allLessons: remoteData, filteredLessons: filtered);
        }
      },
      onError: (_) {
        // Stream errors are non-fatal; cached data remains visible.
      },
    );
  }

  // Merges multiple group streams into one combined list stream.
  // All inner subscriptions and the controller are tracked for proper cleanup.
  Stream<List<LessonDto>> _mergeGroupStreams(List<String> groupIds) {
    _closeMergeController();

    final streams = groupIds.map(_repository.watchScheduleByGroup).toList();
    final latestSnapshots = List<List<LessonDto>>.filled(streams.length, []);
    final controller = StreamController<List<LessonDto>>();
    final innerSubs = <StreamSubscription<List<LessonDto>>>[];

    for (int i = 0; i < streams.length; i++) {
      final index = i;
      innerSubs.add(streams[i].listen((data) {
        latestSnapshots[index] = data;
        if (!controller.isClosed) {
          controller.add(latestSnapshots.expand((l) => l).toList());
        }
      }));
    }

    _mergeController = controller;
    _mergeSubscriptions = [innerSubs];
    return controller.stream;
  }

  void _closeMergeController() {
    for (final sub in _mergeSubscriptions.expand((s) => s)) {
      sub.cancel();
    }
    _mergeSubscriptions = [];
    _mergeController?.close();
    _mergeController = null;
  }

  List<LessonDto> _applyFiltersToLessons(
    List<LessonDto> lessons,
    Map<String, String?> filters,
  ) {
    return lessons.where((lesson) {
      if (filters[FilterKeys.teacher] != null &&
          lesson.teacherName != filters[FilterKeys.teacher]) {
        return false;
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

  /// Emits a new loaded state from an existing one, overriding only specified fields.
  /// Automatically rebuilds [scheduleItems] and [isGlobalSearch].
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
