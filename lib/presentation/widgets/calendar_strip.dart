import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';

class CalendarStrip extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;

  const CalendarStrip({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  State<CalendarStrip> createState() => _CalendarStripState();
}

class _CalendarStripState extends State<CalendarStrip> {
  late PageController _pageController;
  int _currentWeekIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 500);
  }

  // Get the list of dates for the week based on the current week index
  List<DateTime> _getWeekDays(int weekOffset) {
    DateTime now = DateTime.now();
    DateTime monday = now.subtract(Duration(days: now.weekday - 1));
    monday = monday.add(Duration(days: weekOffset * 7));

    return List.generate(5, (index) => monday.add(Duration(days: index)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Title with month and year
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            DateFormat('MMMM yyyy').format(widget.selectedDate),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        
        // PageView for week navigation
        SizedBox(
          height: 90,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (page) {
              setState(() {
                _currentWeekIndex = page - 500;
              });
            },
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
    
    // Use Expanded to ensure equal spacing and proper alignment
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
                DateFormat('E').format(date), // Пн, Вт...
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