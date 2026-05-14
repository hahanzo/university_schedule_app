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
import '../widgets/group_selector.dart';
import '../widgets/group_divider.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late ScheduleCubit _cubit;
  DateTime _selectedDate = DateTime.now();
  bool _isFilterVisible = false;
  ScheduleState? _lastLoadedState;

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

  DateTime _getNextWorkday(DateTime date) {
    DateTime next = date.add(const Duration(days: 1));
    while (next.weekday > 5) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }

  DateTime _getPreviousWorkday(DateTime date) {
    DateTime prev = date.subtract(const Duration(days: 1));
    while (prev.weekday > 5) {
      prev = prev.subtract(const Duration(days: 1));
    }
    return prev;
  }

  String _getDayName(int weekday) {
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

  void _toggleFilters() {
    setState(() {
      _isFilterVisible = !_isFilterVisible;
    });
  }

  void _showGroupSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 0,
          right: 0,
          top: 16,
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          child: Container(
            color: AppColors.surface,
            child: BlocBuilder<ScheduleCubit, ScheduleState>(
              bloc: _cubit,
              builder: (context, state) {
                // Store last loaded state to show previous data while loading
                state.maybeWhen(
                  loaded: (_, __, ___, ____, _____) {
                    _lastLoadedState = state;
                    return null;
                  },
                  orElse: () => null,
                );

                final displayState = _lastLoadedState ?? state;

                return displayState.maybeWhen(
                  loaded:
                      (
                        _,
                        __,
                        selectedGroupsUpdated,
                        availableGroupsUpdated,
                        ______,
                      ) {
                        return GroupSelector(
                          selectedGroups: selectedGroupsUpdated,
                          availableGroups: availableGroupsUpdated,
                          onGroupToggle: (group) {
                            if (selectedGroupsUpdated.contains(group)) {
                              _cubit.removeGroup(group);
                            } else {
                              _cubit.addGroup(group);
                            }
                          },
                        );
                      },
                  orElse: () => const SizedBox(),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // Logic to check if the lesson has already ended
  bool _isLessonPast(String timeEnd) {
    final now = DateTime.now();
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
      int targetWeekday = _selectedDate.weekday;

      // Find which occurrence of this weekday it is in the current month
      int occurrence = ((_selectedDate.day - 1) ~/ 7) + 1;

      DateTime targetMonthFirstDay = DateTime(
        _selectedDate.year,
        _selectedDate.month + offset,
        1,
      );

      int daysToAdd = (targetWeekday - targetMonthFirstDay.weekday) % 7;
      if (daysToAdd < 0) daysToAdd += 7;

      DateTime targetDate = targetMonthFirstDay.add(
        Duration(days: daysToAdd + (occurrence - 1) * 7),
      );

      // If the target occurrence pushes into the NEXT month (e.g. 5th occurrence doesn't exist),
      // fallback to the last occurrence of that month.
      if (targetDate.month != targetMonthFirstDay.month) {
        targetDate = targetDate.subtract(const Duration(days: 7));
      }

      _selectedDate = targetDate;
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

  // Open selection menu for a specific filter (by filter key)
  // Filter options are limited to lessons on the selected date
  void _openSelectionMenu(String filterKey) {
    final state = _cubit.state;

    // Map filter keys to display labels
    const filterLabels = {
      'teacher': 'Викладач',
      'time': 'Година',
      'subject': 'Предмет',
    };

    state.maybeWhen(
      loaded: (allLessons, _, __, ___, ____) {
        List<String> options = [];

        // Get options only for lessons on the selected date
        final lessonsForDate = allLessons
            .where((l) => l.dayOfWeek == _selectedDate.weekday)
            .toList();

        switch (filterKey) {
          case 'teacher':
            options = lessonsForDate.map((l) => l.teacherName).toSet().toList();
            break;
          case 'subject':
            options = lessonsForDate.map((l) => l.subjectName).toSet().toList();
            break;
          case 'time':
            options = lessonsForDate.map((l) => l.timeStart).toSet().toList();
            break;
        }

        options.sort();

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (sheetContext) => SelectionBottomSheet(
            title: filterLabels[filterKey] ?? filterKey,
            items: options,
            onItemSelected: (selected) {
              final value = selected == 'RESET' ? null : selected;

              // Apply filter based on filter key
              if (filterKey == 'teacher') {
                _cubit.applyFilter(teacher: value);
              } else if (filterKey == 'subject') {
                _cubit.applyFilter(subject: value);
              } else if (filterKey == 'time') {
                _cubit.applyFilter(time: value);
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
              BlocBuilder<ScheduleCubit, ScheduleState>(
                bloc: _cubit,
                builder: (context, state) {
                  bool isGlobalSearch = false;
                  state.maybeWhen(
                    loaded: (all, filtered, _, __, filters) {
                      isGlobalSearch =
                          (filtered.length != all.length) || filters.isNotEmpty;
                    },
                    orElse: () {},
                  );

                  return AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: isGlobalSearch
                        ? const SizedBox(width: double.infinity, height: 0)
                        : CalendarStrip(
                            selectedDate: _selectedDate,
                            onDateSelected: _onDateChanged,
                            onMonthTap: _showDatePicker,
                            onPreviousMonth: () => _changeMonth(-1),
                            onNextMonth: () => _changeMonth(1),
                          ),
                  );
                },
              ),

              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _isFilterVisible
                    ? BlocBuilder<ScheduleCubit, ScheduleState>(
                        bloc: _cubit,
                        builder: (context, state) {
                          return state.maybeWhen(
                            loaded:
                                (
                                  allLessons,
                                  _,
                                  selectedGroups,
                                  availableGroups,
                                  activeFilters,
                                ) {
                                  return Column(
                                    children: [
                                      // Selected Groups Display
                                      SizedBox(
                                        width: double.infinity,
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          child: Row(
                                            children: [
                                              ...selectedGroups.map((group) {
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        right: 8,
                                                      ),
                                                  child: Chip(
                                                    label: Text(group),
                                                    onDeleted:
                                                        selectedGroups.length >
                                                            1
                                                        ? () => _cubit
                                                              .removeGroup(
                                                                group,
                                                              )
                                                        : null,
                                                    deleteIcon:
                                                        selectedGroups.length >
                                                            1
                                                        ? const Icon(
                                                            Icons.close,
                                                            size: 16,
                                                          )
                                                        : null,
                                                    backgroundColor: AppColors
                                                        .primary
                                                        .withOpacity(0.1),
                                                  ),
                                                );
                                              }),
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  left: 4,
                                                ),
                                                child: ActionChip(
                                                  avatar: const Icon(
                                                    Icons.add,
                                                    size: 16,
                                                  ),
                                                  label: const Text('Додати'),
                                                  onPressed: () =>
                                                      _showGroupSelector(),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // Filters
                                      FilterChipsBar(
                                        onChipTap: (filterKey) =>
                                            _openSelectionMenu(filterKey),
                                        onClearFilter: (filterKey) =>
                                            _cubit.clearFilter(filterKey),
                                        activeFilters: activeFilters,
                                      ),
                                    ],
                                  );
                                },
                            orElse: () => const SizedBox.shrink(),
                          );
                        },
                      )
                    : const SizedBox(width: double.infinity, height: 0),
              ),

              // List of lessons
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragEnd: (details) {
                    if (details.primaryVelocity == null) return;
                    // Swipe right -> previous workday
                    if (details.primaryVelocity! > 300) {
                      _onDateChanged(_getPreviousWorkday(_selectedDate));
                    }
                    // Swipe left -> next workday
                    else if (details.primaryVelocity! < -300) {
                      _onDateChanged(_getNextWorkday(_selectedDate));
                    }
                  },
                  child: RefreshIndicator(
                    onRefresh: () async {
                      setState(() {
                        _selectedDate = DateTime.now();
                      });
                      // Reload with default group
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
                          loaded:
                              (
                                allLessons,
                                filteredLessons,
                                selectedGroup,
                                availableGroups,
                                activeFilters,
                              ) {
                                final bool isSearching =
                                    filteredLessons.length != allLessons.length;
                                final bool isGlobalSearch =
                                    isSearching || activeFilters.isNotEmpty;

                                // Filter by selected date from calendar
                                List<LessonDto> displayList = isGlobalSearch
                                    ? filteredLessons.toList()
                                    : filteredLessons
                                          .where(
                                            (l) =>
                                                l.dayOfWeek ==
                                                _selectedDate.weekday,
                                          )
                                          .toList();

                                // Apply active filters (AND logic - all filters must match)
                                if (activeFilters.isNotEmpty) {
                                  displayList = displayList.where((lesson) {
                                    bool matches = true;

                                    if (activeFilters['teacher'] != null) {
                                      matches &=
                                          lesson.teacherName ==
                                          activeFilters['teacher'];
                                    }
                                    if (activeFilters['subject'] != null) {
                                      matches &=
                                          lesson.subjectName ==
                                          activeFilters['subject'];
                                    }
                                    if (activeFilters['time'] != null) {
                                      matches &=
                                          lesson.timeStart ==
                                          activeFilters['time'];
                                    }

                                    return matches;
                                  }).toList();
                                }

                                if (displayList.isEmpty) {
                                  return const Center(
                                    child: Text("Нічого не знайдено 🔍"),
                                  );
                                }

                                // Logic for grouping and dividers
                                List<Widget> listItems = [];

                                // Sort the list
                                displayList.sort((a, b) {
                                  if (isGlobalSearch) {
                                    int dayCompare = a.dayOfWeek.compareTo(
                                      b.dayOfWeek,
                                    );
                                    if (dayCompare != 0) return dayCompare;
                                  }

                                  if (selectedGroup.length > 1) {
                                    int indexA = selectedGroup.indexOf(
                                      a.groupId,
                                    );
                                    int indexB = selectedGroup.indexOf(
                                      b.groupId,
                                    );
                                    int groupCompare = indexA.compareTo(indexB);
                                    if (groupCompare != 0) return groupCompare;
                                  }

                                  return a.lessonNumber.compareTo(
                                    b.lessonNumber,
                                  );
                                });

                                if (isGlobalSearch) {
                                  int? currentDay;
                                  String? currentGroup;

                                  for (var lesson in displayList) {
                                    if (currentDay != lesson.dayOfWeek) {
                                      currentDay = lesson.dayOfWeek;
                                      currentGroup =
                                          null; // reset group when day changes

                                      // Add Day Divider
                                      listItems.add(
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 16,
                                            bottom: 8,
                                            left: 16,
                                            right: 16,
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.calendar_today,
                                                size: 16,
                                                color: AppColors.primary,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                _getDayName(lesson.dayOfWeek),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: AppColors.primary,
                                                    ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Container(
                                                  height: 1,
                                                  color: AppColors.primary
                                                      .withOpacity(0.2),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }

                                    if (selectedGroup.length > 1 &&
                                        currentGroup != lesson.groupId) {
                                      currentGroup = lesson.groupId;
                                      listItems.add(
                                        GroupDivider(groupName: currentGroup),
                                      );
                                    }

                                    listItems.add(LessonCard(lesson: lesson));
                                  }
                                } else {
                                  // Original logic for single day
                                  final bool isToday = DateUtils.isSameDay(
                                    _selectedDate,
                                    DateTime.now(),
                                  );

                                  if (selectedGroup.length <= 1) {
                                    // Single group logic with TimeDivider
                                    int dividerIndex = -1;
                                    if (isToday && !isSearching) {
                                      dividerIndex = displayList.indexWhere(
                                        (l) => !_isLessonPast(l.timeEnd),
                                      );
                                      if (dividerIndex == -1 &&
                                          displayList.isNotEmpty)
                                        dividerIndex = displayList.length;
                                    }

                                    for (
                                      int i = 0;
                                      i < displayList.length;
                                      i++
                                    ) {
                                      if (i == dividerIndex)
                                        listItems.add(const TimeDivider());
                                      listItems.add(
                                        LessonCard(lesson: displayList[i]),
                                      );
                                    }
                                    if (dividerIndex == displayList.length &&
                                        displayList.isNotEmpty) {
                                      listItems.add(const TimeDivider());
                                    }
                                  } else {
                                    // Multiple groups logic
                                    String? currentGroup;
                                    List<LessonDto> currentGroupLessons = [];

                                    void flushGroup() {
                                      if (currentGroupLessons.isEmpty) return;
                                      listItems.add(
                                        GroupDivider(groupName: currentGroup!),
                                      );

                                      int dividerIndex = -1;
                                      if (isToday && !isSearching) {
                                        dividerIndex = currentGroupLessons
                                            .indexWhere(
                                              (l) => !_isLessonPast(l.timeEnd),
                                            );
                                        if (dividerIndex == -1)
                                          dividerIndex =
                                              currentGroupLessons.length;
                                      }

                                      for (
                                        int i = 0;
                                        i < currentGroupLessons.length;
                                        i++
                                      ) {
                                        if (i == dividerIndex)
                                          listItems.add(const TimeDivider());
                                        listItems.add(
                                          LessonCard(
                                            lesson: currentGroupLessons[i],
                                          ),
                                        );
                                      }
                                      if (dividerIndex ==
                                          currentGroupLessons.length)
                                        listItems.add(const TimeDivider());

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

                                return ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  itemCount: listItems.length,
                                  itemBuilder: (context, index) =>
                                      listItems[index],
                                );
                              },
                        );
                      },
                    ),
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
