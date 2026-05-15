import '../../../../data/models/lesson_dto.dart';
import '../models/schedule_list_item.dart';
import '../../../../core/utils/date_extensions.dart';

class ScheduleListBuilder {
  static List<ScheduleListItem> buildList({
    required List<LessonDto> allLessons,
    required List<LessonDto> filteredLessons,
    required List<String> selectedGroup,
    required Map<String, String?> activeFilters,
    required DateTime selectedDate,
  }) {
    final bool isSearching = filteredLessons.length != allLessons.length;
    final bool isGlobalSearch = isSearching || activeFilters.isNotEmpty;

    // Filter by selected date from calendar and week parity
    List<LessonDto> displayList = filteredLessons.where((l) {
      // 1. If not global search, check day of week
      if (!isGlobalSearch && l.dayOfWeek != selectedDate.weekday) {
        return false;
      }

      // 2. Check week parity
      final wt = l.weekType.toLowerCase();
      
      // If weekType is empty or explicitly says it's for all weeks, show it
      if (wt.isEmpty || wt == 'all' || wt == 'both' || wt == 'always') {
        return true;
      }

      if (selectedDate.isNumeratorWeek) {
        return wt == 'numerator';
      } else {
        return wt == 'denominator';
      }
    }).toList();

    if (displayList.isEmpty) {
      return []; // Return empty list to signify no items found
    }

    List<ScheduleListItem> listItems = [];

    // Sort the list
    displayList.sort((a, b) {
      if (isGlobalSearch) {
        int dayCompare = a.dayOfWeek.compareTo(b.dayOfWeek);
        if (dayCompare != 0) return dayCompare;
      }

      if (selectedGroup.length > 1) {
        int indexA = selectedGroup.indexOf(a.groupId);
        int indexB = selectedGroup.indexOf(b.groupId);
        int groupCompare = indexA.compareTo(indexB);
        if (groupCompare != 0) return groupCompare;
      }

      return a.lessonNumber.compareTo(b.lessonNumber);
    });

    if (isGlobalSearch) {
      int? currentDay;
      String? currentGroup;

      for (var lesson in displayList) {
        if (currentDay != lesson.dayOfWeek) {
          currentDay = lesson.dayOfWeek;
          currentGroup = null; // reset group when day changes

          listItems.add(DayHeaderItem(lesson.dayOfWeek));
        }

        if (selectedGroup.length > 1 && currentGroup != lesson.groupId) {
          currentGroup = lesson.groupId;
          listItems.add(GroupHeaderItem(currentGroup));
        }

        listItems.add(LessonItem(lesson));
      }
    } else {
      // Original logic for single day
      final bool isToday = selectedDate.isSameDayAs(DateTime.now());

      if (selectedGroup.length <= 1) {
        // Single group logic with TimeDivider
        int dividerIndex = -1;
        if (isToday && !isSearching) {
          dividerIndex = displayList.indexWhere(
            (l) => !_isLessonPast(l.timeEnd),
          );
          if (dividerIndex == -1 && displayList.isNotEmpty)
            dividerIndex = displayList.length;
        }

        for (int i = 0; i < displayList.length; i++) {
          if (i == dividerIndex) listItems.add(TimeDividerItem());
          listItems.add(LessonItem(displayList[i]));
        }
        if (dividerIndex == displayList.length && displayList.isNotEmpty) {
          listItems.add(TimeDividerItem());
        }
      } else {
        // Multiple groups logic
        String? currentGroup;
        List<LessonDto> currentGroupLessons = [];

        void flushGroup() {
          if (currentGroupLessons.isEmpty) return;
          listItems.add(GroupHeaderItem(currentGroup!));

          int dividerIndex = -1;
          if (isToday && !isSearching) {
            dividerIndex = currentGroupLessons.indexWhere(
              (l) => !_isLessonPast(l.timeEnd),
            );
            if (dividerIndex == -1) dividerIndex = currentGroupLessons.length;
          }

          for (int i = 0; i < currentGroupLessons.length; i++) {
            if (i == dividerIndex) listItems.add(TimeDividerItem());
            listItems.add(LessonItem(currentGroupLessons[i]));
          }
          if (dividerIndex == currentGroupLessons.length)
            listItems.add(TimeDividerItem());

          currentGroupLessons.clear();
        }

        for (var lesson in displayList) {
          if (currentGroup != lesson.groupId) {
            flushGroup();
            currentGroup = lesson.groupId;
          }
          currentGroupLessons.add(lesson);
        }
        flushGroup(); // flush last group
      }
    }
    return listItems;
  }

  static bool _isLessonPast(String timeEnd) {
    if (timeEnd.isEmpty) return false;
    final parts = timeEnd.split(':');
    if (parts.length != 2) return false;

    final now = DateTime.now();
    final endTime = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );

    return now.isAfter(endTime);
  }
}
