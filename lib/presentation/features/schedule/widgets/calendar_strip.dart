import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/string_extensions.dart';

class CalendarStrip extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  // Callback for month label tap
  final VoidCallback onMonthTap;
  // Callbacks for arrow buttons
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  const CalendarStrip({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.onMonthTap,
    required this.onPreviousMonth,
    required this.onNextMonth,
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
    // Calculate Monday of the week containing the initial selectedDate
    _anchorMonday = _getMonday(widget.selectedDate);
    _pageController = PageController(initialPage: 500);
  }

  DateTime _getMonday(DateTime date) {
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: date.weekday - 1));
  }

  @override
  void didUpdateWidget(CalendarStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the date was changed from outside (e.g. month picker or next/prev month buttons)
    // we need to check if we should jump to that week if it's not the one we are currently showing.
    // However, to avoid jumping during manual scroll, we only sync if the week is different
    // and it wasn't a simple day selection.
    if (!DateUtils.isSameDay(oldWidget.selectedDate, widget.selectedDate)) {
      final currentMonday = _anchorMonday.add(
        Duration(days: (_pageController.page?.round() ?? 500 - 500) * 7),
      );
      final newMonday = _getMonday(widget.selectedDate);

      if (!DateUtils.isSameDay(currentMonday, newMonday)) {
        // Recalculate anchor to the new date to keep the view centered/synced
        setState(() {
          _anchorMonday = newMonday;
          _pageController.jumpToPage(500);
        });
      }
    }
  }

  // Calculate workdays (Mon-Fri) for a specific week offset
  List<DateTime> _getWeekDays(int weekOffset) {
    DateTime monday = _anchorMonday.add(Duration(days: weekOffset * 7));
    return List.generate(5, (index) => monday.add(Duration(days: index)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Month Selector Header with arrows
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: widget.onPreviousMonth,
              ),

              // Updated Month Title with click feedback
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onMonthTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 4.0,
                    ),
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

              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: widget.onNextMonth,
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
    bool isToday = DateUtils.isSameDay(date, DateTime.now());

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
