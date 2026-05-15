import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/injection.dart';
import '../../../../core/utils/date_extensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../blocs/schedule_cubit.dart';
import '../blocs/schedule_state.dart';
import '../models/schedule_list_item.dart';
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
  bool _isFilterVisible = false;
  ScheduleState? _lastLoadedState;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<ScheduleCubit>();
    _cubit.loadSchedule(
      'КН-11-1',
    ); // TODO: Extract magic string to user preferences later
  }

  void _onDateChanged(DateTime newDate) {
    _cubit.changeDate(newDate);
  }

  String _getLocalizedWeekday(BuildContext context, int weekday) {
    final l10n = AppLocalizations.of(context)!;
    switch (weekday) {
      case 1:
        return l10n.monday;
      case 2:
        return l10n.tuesday;
      case 3:
        return l10n.wednesday;
      case 4:
        return l10n.thursday;
      case 5:
        return l10n.friday;
      case 6:
        return l10n.saturday;
      case 7:
        return l10n.sunday;
      default:
        return '';
    }
  }

  void _changeMonth(DateTime currentDate, int offset) {
    int targetWeekday = currentDate.weekday;
    int occurrence = ((currentDate.day - 1) ~/ 7) + 1;

    DateTime targetMonthFirstDay = DateTime(
      currentDate.year,
      currentDate.month + offset,
      1,
    );

    int daysToAdd = (targetWeekday - targetMonthFirstDay.weekday) % 7;
    if (daysToAdd < 0) daysToAdd += 7;

    DateTime targetDate = targetMonthFirstDay.add(
      Duration(days: daysToAdd + (occurrence - 1) * 7),
    );

    if (targetDate.month != targetMonthFirstDay.month) {
      targetDate = targetDate.subtract(const Duration(days: 7));
    }

    _cubit.changeDate(targetDate);
  }

  Future<void> _showDatePicker(DateTime currentDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != currentDate) {
      _cubit.changeDate(picked);
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
            color: Theme.of(context).colorScheme.surface,
            child: BlocBuilder<ScheduleCubit, ScheduleState>(
              bloc: _cubit,
              builder: (context, state) {
                state.maybeWhen(
                  loaded: (_, __, ___, ____, _____, ______, _______, ________) {
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
                        _____,
                        ______,
                        _______,
                        ________,
                      ) {
                        return GroupSelector(
                          selectedGroups: selectedGroupsUpdated,
                          availableGroups: availableGroupsUpdated,
                          onGroupsChanged: (groups) => _cubit.loadMultipleGroups(groups),
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

  void _openSelectionMenu(String filterKey) {
    final state = _cubit.state;

    final filterLabels = {
      'teacher': AppLocalizations.of(context)!.teacher,
      'time': AppLocalizations.of(context)!.time,
      'subject': AppLocalizations.of(context)!.subject,
    };

    state.maybeWhen(
      loaded: (allLessons, _, __, ___, ____, selectedDate, _____, ______) {
        List<String> options = [];

        switch (filterKey) {
          case 'teacher':
            options = allLessons.map((l) => l.teacherName).toSet().toList();
            break;
          case 'subject':
            options = allLessons.map((l) => l.subjectName).toSet().toList();
            break;
          case 'time':
            options = allLessons.map((l) => l.timeStart).toSet().toList();
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
              if (filterKey == 'teacher') _cubit.applyFilter(teacher: value);
              if (filterKey == 'subject') _cubit.applyFilter(subject: value);
              if (filterKey == 'time') _cubit.applyFilter(time: value);
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
      onPopInvokedWithResult: (didPop, result) {
        if (FocusScope.of(context).hasFocus) {
          FocusScope.of(context).unfocus();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              ScheduleHeader(
                onSearchChanged: (query) => _cubit.searchLessons(query),
                onFilterPressed: _toggleFilters,
              ),

              // Calendar strip
              BlocBuilder<ScheduleCubit, ScheduleState>(
                bloc: _cubit,
                builder: (context, state) {
                  return state.maybeWhen(
                    loaded:
                        (
                          _,
                          __,
                          ___,
                          ____,
                          _____,
                          selectedDate,
                          isGlobalSearch,
                          ______,
                        ) {
                          return AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: isGlobalSearch
                                ? const SizedBox(
                                    width: double.infinity,
                                    height: 0,
                                  )
                                : CalendarStrip(
                                    selectedDate: selectedDate,
                                    onDateSelected: _onDateChanged,
                                    onMonthTap: () =>
                                        _showDatePicker(selectedDate),
                                    onPreviousMonth: () =>
                                        _changeMonth(selectedDate, -1),
                                    onNextMonth: () =>
                                        _changeMonth(selectedDate, 1),
                                  ),
                          );
                        },
                    orElse: () => const SizedBox(),
                  );
                },
              ),

              // Filter Bar
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
                                  _,
                                  __,
                                  selectedGroups,
                                  availableGroups,
                                  activeFilters,
                                  ____,
                                  _____,
                                  ______,
                                ) {
                                  return Column(
                                    children: [
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
                                               if (selectedGroups.length == availableGroups.length && availableGroups.isNotEmpty)
                                                 Padding(
                                                   padding: const EdgeInsets.only(right: 8),
                                                   child: Chip(
                                                     label: Text(AppLocalizations.of(context)!.allGroups),
                                                     onDeleted: () {
                                                       if (selectedGroups.isNotEmpty) {
                                                         _cubit.loadSchedule(selectedGroups.first);
                                                       }
                                                     },
                                                     deleteIcon: const Icon(Icons.close, size: 16),
                                                     backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                                   ),
                                                 )
                                               else
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
                                                    backgroundColor:
                                                        Theme.of(context)
                                                            .colorScheme
                                                            .primary
                                                            .withValues(alpha: 0.1),
                                                  ),
                                                );
                                              }),
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  left: 4,
                                                ),
                                                child: ActionChip(
                                                  avatar: Icon(
                                                    Icons.add,
                                                    size: 16,
                                                    color: Theme.of(context).colorScheme.onSurface,
                                                  ),
                                                  label: Text(
                                                    AppLocalizations.of(
                                                      context,
                                                    )!.add,
                                                  ),
                                                  onPressed: _showGroupSelector,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
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

              // Schedule List
              Expanded(
                child: BlocBuilder<ScheduleCubit, ScheduleState>(
                  bloc: _cubit,
                  builder: (context, state) {
                    return state.when(
                      initial: () => Center(
                        child: Text(AppLocalizations.of(context)!.loading),
                      ),
                      loading: () => Center(
                        child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      error: (message) => Center(child: Text(message)),
                      loaded:
                          (
                            _,
                            __,
                            ___,
                            ____,
                            _____,
                            selectedDate,
                            ______,
                            scheduleItems,
                          ) {
                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onHorizontalDragEnd: (details) {
                                if (details.primaryVelocity == null) return;
                                if (details.primaryVelocity! > 300) {
                                  _onDateChanged(selectedDate.previousWorkday);
                                } else if (details.primaryVelocity! < -300) {
                                  _onDateChanged(selectedDate.nextWorkday);
                                }
                              },
                              child: RefreshIndicator(
                                onRefresh: () async {
                                  _cubit.changeDate(DateTime.now());
                                  await _cubit.loadSchedule('КН-11-1');
                                },
                                color: Theme.of(context).colorScheme.primary,
                                child: scheduleItems.isEmpty
                                    ? Center(
                                        child: Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.noResults,
                                        ),
                                      )
                                    : ListView.builder(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        itemCount: scheduleItems.length,
                                        itemBuilder: (context, index) {
                                          final item = scheduleItems[index];

                                          if (item is DayHeaderItem) {
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                top: 16,
                                                bottom: 8,
                                                left: 16,
                                                right: 16,
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.calendar_today,
                                                    size: 16,
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    _getLocalizedWeekday(
                                                      context,
                                                      item.weekday,
                                                    ),
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleMedium
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Theme.of(
                                                            context,
                                                          ).colorScheme.primary,
                                                        ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Container(
                                                      height: 1,
                                                      color: Theme.of(context)
                                                         .colorScheme
                                                         .onSurface
                                                         .withValues(alpha: 0.15),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }

                                          if (item is GroupHeaderItem) {
                                            return GroupDivider(
                                              groupName: item.groupName,
                                            );
                                          }

                                          if (item is TimeDividerItem) {
                                            return const TimeDivider();
                                          }

                                          if (item is LessonItem) {
                                            return LessonCard(
                                              lesson: item.lesson,
                                            );
                                          }

                                          return const SizedBox();
                                        },
                                      ),
                              ),
                            );
                          },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
