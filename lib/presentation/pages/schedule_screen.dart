import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/injection.dart';
import '../../data/models/lesson_dto.dart';
import '../bloc/schedule_cubit.dart';
import '../bloc/schedule_state.dart';
import '../widgets/lesson_card.dart';
import '../widgets/calendar_strip.dart';
import '../widgets/schedule_header.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/time_divider.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final _cubit = getIt<ScheduleCubit>();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _cubit.loadSchedule('КН-11-1');
  }

  void _onDateChanged(DateTime newDate) {
    setState(() {
      _selectedDate = newDate;
    });
  }

  // Logic to check if the lesson has already ended
  bool _isLessonPast(String timeEnd) {
    final now = DateTime.now(); // Apply debug offset for testing
    try {
      final parts = timeEnd.split(':');
      final endHour = int.parse(parts[0]);
      final endMinute = int.parse(parts[1]);

      final endDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        endHour,
        endMinute,
      );
      return now.isAfter(endDateTime);
    } catch (e) {
      return false;
    }
  }

  // Function to call the Material 3 Date Picker
  Future<void> _showDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      _onDateChanged(picked);
    }
  }

  // Logic for switching months
  void _changeMonth(int offset) {
    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month + offset,
        _selectedDate.day,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _cubit,
      child: PopScope(
        // Triggered when the user attempts to pop the page (Back button/gesture)
        onPopInvokedWithResult: (didPop, result) {
          if (FocusScope.of(context).hasFocus) {
            FocusScope.of(context).unfocus();
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                // Search and Filter Header
                ScheduleHeader(
                  onSearchChanged: (query) => _cubit.searchLessons(query),
                  onFilterPressed: () {
                    // Call BottomSheet with filters (implement in next step)
                  },
                ),

                // Calendar strip (Mon-Fri)
                CalendarStrip(
                  selectedDate: _selectedDate,
                  onDateSelected: _onDateChanged,
                  onMonthTap: _showDatePicker,
                  onPreviousMonth: () => _changeMonth(-1),
                  onNextMonth: () => _changeMonth(1),
                ),

                // Divider between calendar and lessons list (HINT: may be useful for better separation of UI sections)
                // const Divider(height: 1, color: Colors.black12),

                // List of lessons
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      setState(() {
                        _selectedDate = DateTime.now();
                      });

                      // Clear search via controller if needed
                      // (requires moving controller to screen level or using a key)

                      // Reload data from Bloc
                      await _cubit.loadSchedule('КН-11-1');
                    },
                    color: AppColors.primary,
                    child: BlocBuilder<ScheduleCubit, ScheduleState>(
                      builder: (context, state) {
                        return state.when(
                          initial: () =>
                              const Center(child: Text("Select a group")),
                          loading: () => const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                          error: (message) => Center(child: Text(message)),
                          loaded: (allLessons, filteredLessons) {
                            final bool isSearching =
                                filteredLessons.length != allLessons.length;

                            // Prepare the list of lessons to show
                            final List<LessonDto> displayList = isSearching
                                ? filteredLessons
                                : filteredLessons
                                      .where(
                                        (l) =>
                                            l.dayOfWeek ==
                                            _selectedDate.weekday,
                                      )
                                      .toList();

                            if (displayList.isEmpty) {
                              return const Center(
                                child: Text("Нічого не знайдено 🔍"),
                              );
                            }

                            // Logic for the "Completed" divider
                            // Only show divider if it's today and we are NOT searching
                            int dividerIndex = -1;
                            final bool isToday = DateUtils.isSameDay(
                              _selectedDate,
                              DateTime.now(),
                            );

                            if (isToday && !isSearching) {
                              // Find the first lesson that is NOT past yet
                              dividerIndex = displayList.indexWhere(
                                (l) => !_isLessonPast(l.timeEnd),
                              );

                              // If all lessons are past, put divider at the end
                              if (dividerIndex == -1 &&
                                  displayList.isNotEmpty) {
                                dividerIndex = displayList.length;
                              }
                            }

                            // Build the list with an optional extra item for the divider
                            return ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount:
                                  displayList.length +
                                  (dividerIndex != -1 ? 1 : 0),
                              itemBuilder: (context, index) {
                                // If this position is for the divider
                                if (dividerIndex != -1 &&
                                    index == dividerIndex) {
                                  return const TimeDivider();
                                }

                                // Calculate the correct lesson index (shift back if divider was already placed)
                                final int lessonIndex =
                                    (dividerIndex != -1 && index > dividerIndex)
                                    ? index - 1
                                    : index;

                                return LessonCard(
                                  lesson: displayList[lessonIndex],
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}