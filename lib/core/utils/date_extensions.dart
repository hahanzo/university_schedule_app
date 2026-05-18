import 'package:flutter/material.dart';

extension DateTimeX on DateTime {
  bool get isWeekend =>
      weekday == DateTime.saturday || weekday == DateTime.sunday;

  // Returns next Monday from any date (used to skip weekends)
  DateTime get nextMonday {
    final daysUntilMonday = DateTime.monday - weekday;
    return add(
      Duration(
        days: daysUntilMonday <= 0 ? daysUntilMonday + 7 : daysUntilMonday,
      ),
    );
  }

  // If this date is a weekend, returns next Monday; otherwise returns itself
  DateTime get closestWorkday => isWeekend ? nextMonday : this;

  DateTime get nextWorkday {
    DateTime next = add(const Duration(days: 1));
    while (next.weekday > 5) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }

  DateTime get previousWorkday {
    DateTime prev = subtract(const Duration(days: 1));
    while (prev.weekday > 5) {
      prev = prev.subtract(const Duration(days: 1));
    }
    return prev;
  }

  bool isSameDayAs(DateTime other) {
    return DateUtils.isSameDay(this, other);
  }

  /// Returns the ISO 8601 week number
  int get weekNumber {
    final date = DateTime.utc(year, month, day);
    final dayNum = date.weekday;
    final thursday = date.add(Duration(days: 4 - dayNum));
    final firstDayOfYear = DateTime.utc(thursday.year, 1, 1);
    final diff = thursday.difference(firstDayOfYear).inDays;
    return (diff / 7).floor() + 1;
  }

  bool get isNumeratorWeek => weekNumber % 2 != 0;
  bool get isDenominatorWeek => weekNumber % 2 == 0;
}
