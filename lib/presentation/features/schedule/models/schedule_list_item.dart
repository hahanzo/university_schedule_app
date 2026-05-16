import '../../../../data/models/lesson_dto.dart';

/// Base class for all items in the schedule list
abstract class ScheduleListItem {}

/// Represents a day header in the list (e.g., "Monday")
class DayHeaderItem extends ScheduleListItem {
  final int weekday;

  DayHeaderItem(this.weekday);
}

/// Represents a group header when multiple groups are selected
class GroupHeaderItem extends ScheduleListItem {
  final String groupName;

  GroupHeaderItem(this.groupName);
}

/// Represents the divider line separating past and future lessons
class TimeDividerItem extends ScheduleListItem {}

/// Represents an actual lesson card
class LessonItem extends ScheduleListItem {
  final LessonDto lesson;

  LessonItem(this.lesson);
}
