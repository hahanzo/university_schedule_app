import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../data/models/lesson_dto.dart';
import '../models/schedule_list_item.dart';

part 'schedule_state.freezed.dart';

@freezed
class ScheduleState with _$ScheduleState {
  const factory ScheduleState.initial() = _Initial;
  const factory ScheduleState.loading() = _Loading;
  const factory ScheduleState.loaded({
    required List<LessonDto> allLessons,
    required List<LessonDto> filteredLessons,
    required List<String> selectedGroup,
    required List<String> availableGroups,
    required Map<String, String?> activeFilters,
    required DateTime selectedDate,
    required bool isGlobalSearch,
    required List<ScheduleListItem> scheduleItems,
  }) = _Loaded;
  const factory ScheduleState.error(String message) = _Error;
}

/// Public alias for the loaded state so other files can reference it without
/// depending on the Freezed-generated private [_Loaded] class.
typedef LoadedScheduleState = _Loaded;

extension ScheduleStateX on ScheduleState {
  /// Returns the [LoadedScheduleState] when in loaded state, or `null` otherwise.
  LoadedScheduleState? get loadedOrNull => mapOrNull(loaded: (s) => s);
}
