import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:university_schedule_app/core/utils/date_extensions.dart';
import 'package:university_schedule_app/l10n/app_localizations.dart';
import '../../../../core/utils/string_extensions.dart';

class CalendarStrip extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final VoidCallback onMonthTap;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  // Callback to jump back to today's date
  final VoidCallback? onTodayTap;

  const CalendarStrip({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.onMonthTap,
    required this.onPreviousMonth,
    required this.onNextMonth,
    this.onTodayTap,
  });

  @override
  State<CalendarStrip> createState() => _CalendarStripState();
}

class _CalendarStripState extends State<CalendarStrip> {
  late PageController _pageController;
  late DateTime _anchorMonday;

  @override
  void initState() {
    super.initState();
    _anchorMonday = _getMonday(widget.selectedDate);
    _pageController = PageController(initialPage: 500);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _getMonday(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: date.weekday - 1));
  }

  @override
  void didUpdateWidget(CalendarStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync calendar view when date changes from outside (e.g. month picker)
    if (!DateUtils.isSameDay(oldWidget.selectedDate, widget.selectedDate)) {
      final currentMonday = _anchorMonday.add(
        Duration(days: (_pageController.page?.round() ?? 500 - 500) * 7),
      );
      final newMonday = _getMonday(widget.selectedDate);

      if (!DateUtils.isSameDay(currentMonday, newMonday)) {
        setState(() {
          _anchorMonday = newMonday;
          _pageController.jumpToPage(500);
        });
      }
    }
  }

  List<DateTime> _getWeekDays(int weekOffset) {
    DateTime monday = _anchorMonday.add(Duration(days: weekOffset * 7));
    return List.generate(5, (index) => monday.add(Duration(days: index)));
  }

  /// Returns -1 if selected week is in the past, 1 if in the future, 0 if current.
  /// Uses closestWorkday so weekends don't break the comparison.
  int _weekDirection() {
    final todayMonday = _getMonday(DateTime.now().closestWorkday);
    final selectedMonday = _getMonday(widget.selectedDate);
    final diff = selectedMonday.difference(todayMonday).inDays;
    if (diff < 0) return -1;
    if (diff > 0) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final direction = _weekDirection();
    final isOffCurrentWeek = direction != 0 && widget.onTodayTap != null;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Row(
            children: [
              // Left side: chevron + optional Today chip (when in future week)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: widget.onPreviousMonth,
                  ),
                  if (isOffCurrentWeek && direction > 0)
                    _TodayChip(onTap: widget.onTodayTap!),
                ],
              ),

              // Centered month title
              Expanded(
                child: GestureDetector(
                  onTap: widget.onMonthTap,
                  child: Center(
                    child: Text(
                      DateFormat(
                        'MMMM',
                        Localizations.localeOf(context).toString(),
                      ).format(widget.selectedDate).toCapitalized(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),

              // Right side: optional Today chip (when in past week) + chevron
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isOffCurrentWeek && direction < 0)
                    _TodayChip(onTap: widget.onTodayTap!),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: widget.onNextMonth,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Horizontal Day Strip
        SizedBox(
          height: 90,
          child: PageView.builder(
            controller: _pageController,
            itemBuilder: (context, index) {
              final weekDays = _getWeekDays(index - 500);
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: weekDays.map((date) => _buildDayItem(date)).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDayItem(DateTime date) {
    bool isSelected = DateUtils.isSameDay(date, widget.selectedDate);
    // When today is a weekend, show the ring on the closest workday instead
    bool isToday = DateUtils.isSameDay(date, DateTime.now().closestWorkday);

    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onDateSelected(date),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(32),
            border: isToday && !isSelected
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1,
                  )
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                DateFormat(
                  'E',
                  Localizations.localeOf(context).toString(),
                ).format(date).toCapitalized(),
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.grey,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                date.day.toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Colors.black
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small rounded "Today" button that appears next to the month title.
class _TodayChip extends StatelessWidget {
  final VoidCallback onTap;

  const _TodayChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
          ),
        ),
        child: Text(
          l10n.today,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ),
    );
  }
}
