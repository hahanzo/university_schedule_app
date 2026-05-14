import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/injection.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/lesson_dto.dart';
import '../bloc/schedule_cubit.dart';
import '../bloc/schedule_state.dart';
import '../widgets/filter_chips_bar.dart';
import '../widgets/selection_bottom_sheet.dart';
import '../widgets/time_divider.dart';
import '../widgets/lesson_card.dart';
import '../widgets/calendar_strip.dart';
import '../widgets/schedule_header.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late ScheduleCubit _cubit;
  DateTime _selectedDate = DateTime.now();
  bool _isFilterVisible = false;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<ScheduleCubit>();
    _cubit.loadSchedule('КН-11-1');
  }

  void _onDateChanged(DateTime newDate) {
    setState(() {
      _selectedDate = newDate;
    });
  }

  void _toggleFilters() {
    setState(() {
      _isFilterVisible = !_isFilterVisible;
    });
  }

  String _getDayName(int day) {
    switch (day) {
      case 1: return 'Понеділок';
      case 2: return 'Вівторок';
      case 3: return 'Середа';
      case 4: return 'Четвер';
      case 5: return 'П\'ятниця';
      case 6: return 'Субота';
      case 7: return 'Неділя';
      default: return 'Невідомо';
    }
  }

  int? _getDayNumber(String? dayName) {
    switch (dayName) {
      case 'Понеділок': return 1;
      case 'Вівторок': return 2;
      case 'Середа': return 3;
      case 'Четвер': return 4;
      case 'П\'ятниця': return 5;
      case 'Субота': return 6;
      case 'Неділя': return 7;
      default: return null;
    }
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

  // Function to open the bottom sheet with filter options based on the selected filter type
  void _openSelectionMenu(String filterType) {
    final state = _cubit.state;
    
    state.maybeWhen(
      loaded: (allLessons, _, __) {
        List<String> options = [];

        switch (filterType) {
          case 'Викладач':
            options = allLessons.map((l) => l.teacherName).toSet().toList();
            break;
          case 'Група':
            options = allLessons.map((l) => l.groupId).toSet().toList();
            break;
          case 'Предмет':
            options = allLessons.map((l) => l.subjectName).toSet().toList();
            break;
          case 'Година':
            options = allLessons.map((l) => l.timeStart).toSet().toList();
            break;
          case 'День':
            options = allLessons.map((l) => _getDayName(l.dayOfWeek)).toSet().toList();
            break;
        }
        
        if (filterType == 'День') {
          options.sort((a, b) => (_getDayNumber(a) ?? 0).compareTo(_getDayNumber(b) ?? 0));
        } else {
          options.sort(); 
        }

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (sheetContext) => SelectionBottomSheet(
            title: '$filterType',
            items: options,
            onItemSelected: (selected) {
              final value = selected == 'RESET' ? null : selected;
              
              if (filterType == 'Викладач') {
                _cubit.applyFilter(teacher: value);
              } else if (filterType == 'Група') {
                _cubit.applyFilter(group: value);
              } else if (filterType == 'Предмет') {
                _cubit.applyFilter(subject: value);
              } else if (filterType == 'Година') {
                _cubit.applyFilter(time: value);
              } else if (filterType == 'День') {
                _cubit.applyFilter(dayOfWeek: _getDayNumber(value));
              }
            },
          ),
        );
      },
      orElse: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
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
                  _toggleFilters();
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

              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _isFilterVisible
                    ? FilterChipsBar(
                        onChipTap: (type) => _openSelectionMenu(type),
                      )
                    : const SizedBox(width: double.infinity, height: 0),
              ),
              
              // Divider between calendar and lessons list
              // const Divider(height: 1, color: Colors.black12),

              // List of lessons
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      _selectedDate = DateTime.now();
                    });

                    // Reload data from Bloc
                    await _cubit.loadSchedule('КН-11-1');
                  },
                  color: AppColors.primary,
                  child: BlocBuilder<ScheduleCubit, ScheduleState>(
                    bloc: _cubit, // Explicitly pass the bloc instance
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
                          loaded: (allLessons, filteredLessons, selectedGroup) {
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
      );
  }
}