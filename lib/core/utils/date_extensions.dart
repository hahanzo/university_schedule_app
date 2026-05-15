import 'package:flutter/material.dart';

extension DateTimeX on DateTime {
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

  String get weekdayNameUa {
    switch (weekday) {
      case 1:
        return 'Понеділок';
      case 2:
        return 'Вівторок';
      case 3:
        return 'Середа';
      case 4:
        return 'Четвер';
      case 5:
        return 'П\'ятниця';
      case 6:
        return 'Субота';
      case 7:
        return 'Неділя';
      default:
        return '';
    }
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
