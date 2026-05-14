import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/utils/string_extensions.dart';
import '../../core/theme/app_colors.dart';

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

  @override
  void initState() {
    super.initState();
    // Use a large initial page to allow "infinite" scrolling in both directions
    _pageController = PageController(initialPage: 500);
  }

  // Calculate workdays (Mon-Fri) for a specific week offset
  List<DateTime> _getWeekDays(int weekOffset) {
    DateTime now = widget.selectedDate;
    DateTime monday = now.subtract(Duration(days: now.weekday - 1));
    monday = monday.add(Duration(days: weekOffset * 7));

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
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                    child: Text(
                      DateFormat('MMMM', 'uk').format(widget.selectedDate).toCapitalized(),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: AppColors.onBackground,
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
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(32),
            border: isToday && !isSelected 
                ? Border.all(color: AppColors.primary, width: 1) 
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                DateFormat('E', 'uk_UA').format(date).toCapitalized(),
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
                  color: isSelected ? Colors.black : AppColors.onBackground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}