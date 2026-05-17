import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/filter_keys.dart';
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
import '../widgets/group_selector.dart' show GroupSelector, groupPrefix;
import '../widgets/group_divider.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late ScheduleCubit _cubit;
  bool _isFilterVisible = false;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<ScheduleCubit>();
    _cubit.loadSchedule(AppConstants.defaultGroupId);
  }

  void _onDateChanged(DateTime newDate) {
    _cubit.changeDate(newDate.closestWorkday);
  }

  void _changeMonth(DateTime currentDate, int offset) {
    final targetWeekday = currentDate.weekday;
    final occurrence = ((currentDate.day - 1) ~/ 7) + 1;

    final targetMonthFirstDay = DateTime(
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
      // Automatically jump to Monday if a weekend is picked
      _cubit.changeDate(picked.closestWorkday);
    }
  }

  void _toggleFilters() {
    setState(() {
      _isFilterVisible = !_isFilterVisible;
    });
  }

  void _showGroupSelector() {
    // Read state once before opening — GroupSelector manages its own local state.
    final s = _cubit.state.loadedOrNull;
    if (s == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 16,
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          child: Container(
            color: Theme.of(context).colorScheme.surface,
            child: GroupSelector(
              selectedGroups: s.selectedGroup,
              availableGroups: s.availableGroups,
              onGroupsChanged: _cubit.loadMultipleGroups,
            ),
          ),
        ),
      ),
    );
  }

  void _openSelectionMenu(String filterKey) {
    final s = _cubit.state.loadedOrNull;
    if (s == null) return;

    final filterLabels = {
      FilterKeys.teacher: AppLocalizations.of(context)!.teacher,
      FilterKeys.time:    AppLocalizations.of(context)!.time,
      FilterKeys.subject: AppLocalizations.of(context)!.subject,
    };

    final options = switch (filterKey) {
      FilterKeys.teacher => s.allLessons.map((l) => l.teacherName).toSet().toList()..sort(),
      FilterKeys.subject => s.allLessons.map((l) => l.subjectName).toSet().toList()..sort(),
      FilterKeys.time    => s.allLessons.map((l) => l.timeStart).toSet().toList()..sort(),
      _ => <String>[],
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SelectionBottomSheet(
        title: filterLabels[filterKey] ?? filterKey,
        items: options,
        onItemSelected: (selected) {
          final value = selected == 'RESET' ? null : selected;
          if (filterKey == FilterKeys.teacher) _cubit.applyFilter(teacher: value);
          if (filterKey == FilterKeys.subject) _cubit.applyFilter(subject: value);
          if (filterKey == FilterKeys.time) _cubit.applyFilter(time: value);
        },
      ),
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
                onSearchChanged: _cubit.searchLessons,
                onFilterPressed: _toggleFilters,
              ),

              // Only rebuilds when selectedDate or isGlobalSearch changes
              _CalendarStripSection(
                cubit: _cubit,
                onDateChanged: _onDateChanged,
                onMonthTap: _showDatePicker,
                onChangeMonth: _changeMonth,
              ),

              // Filter bar — only rebuilds when groups or filters change
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _isFilterVisible
                    ? _FilterBarSection(
                        cubit: _cubit,
                        onShowGroupSelector: _showGroupSelector,
                        onOpenSelectionMenu: _openSelectionMenu,
                      )
                    : const SizedBox(width: double.infinity, height: 0),
              ),

              // Lesson list — only rebuilds when scheduleItems or date changes
              Expanded(
                child: _LessonListSection(
                  cubit: _cubit,
                  onDateChanged: _onDateChanged,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Calendar Strip Section ──────────────────────────────────────────────────

class _CalendarStripSection extends StatelessWidget {
  final ScheduleCubit cubit;
  final void Function(DateTime) onDateChanged;
  final Future<void> Function(DateTime) onMonthTap;
  final void Function(DateTime, int) onChangeMonth;

  const _CalendarStripSection({
    required this.cubit,
    required this.onDateChanged,
    required this.onMonthTap,
    required this.onChangeMonth,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScheduleCubit, ScheduleState>(
      bloc: cubit,
      // Only rebuild when selectedDate or isGlobalSearch changes
      buildWhen: (prev, curr) {
        final p = prev.loadedOrNull;
        final c = curr.loadedOrNull;
        if (p == null || c == null) return prev != curr;
        return p.selectedDate != c.selectedDate ||
            p.isGlobalSearch != c.isGlobalSearch;
      },
      builder: (context, state) {
        final s = state.loadedOrNull;
        if (s == null) return const SizedBox();

        return AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: s.isGlobalSearch
              ? const SizedBox(width: double.infinity, height: 0)
              : CalendarStrip(
                  selectedDate: s.selectedDate,
                  onDateSelected: onDateChanged,
                  onMonthTap: () => onMonthTap(s.selectedDate),
                  onPreviousMonth: () => onChangeMonth(s.selectedDate, -1),
                  onNextMonth: () => onChangeMonth(s.selectedDate, 1),
                  onTodayTap: () => onDateChanged(DateTime.now()),
                ),
        );
      },
    );
  }
}

// ─── Filter Bar Section ──────────────────────────────────────────────────────

class _FilterBarSection extends StatelessWidget {
  final ScheduleCubit cubit;
  final VoidCallback onShowGroupSelector;
  final void Function(String) onOpenSelectionMenu;

  const _FilterBarSection({
    required this.cubit,
    required this.onShowGroupSelector,
    required this.onOpenSelectionMenu,
  });

  /// Builds smart chips: shows a prefix chip (e.g. "КН") when all subgroups
  /// of that prefix are selected, otherwise shows individual group chips.
  List<Widget> _buildGroupChips(
    BuildContext context,
    List<String> selectedGroups,
    List<String> availableGroups,
  ) {
    final Map<String, List<String>> byPrefix = {};
    for (final g in availableGroups) {
      (byPrefix[groupPrefix(g)] ??= []).add(g);
    }

    final chips = <Widget>[];
    final handled = <String>{};

    for (final group in selectedGroups) {
      if (handled.contains(group)) continue;
      final prefix = groupPrefix(group);
      final allInCategory = byPrefix[prefix] ?? [group];
      final allSelected = allInCategory.every((g) => selectedGroups.contains(g));

      if (allSelected && allInCategory.length > 1) {
        chips.add(Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Chip(
            label: Text(prefix),
            onDeleted: () {
              final remaining = selectedGroups
                  .where((g) => groupPrefix(g) != prefix)
                  .toList();
              cubit.loadMultipleGroups(
                remaining.isNotEmpty ? remaining : [allInCategory.first],
              );
            },
            deleteIcon: const Icon(Icons.close, size: 16),
            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          ),
        ));
        handled.addAll(allInCategory);
      } else {
        chips.add(Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Chip(
            label: Text(group),
            onDeleted: selectedGroups.length > 1
                ? () => cubit.removeGroup(group)
                : null,
            deleteIcon: selectedGroups.length > 1
                ? const Icon(Icons.close, size: 16)
                : null,
            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          ),
        ));
        handled.add(group);
      }
    }
    return chips;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScheduleCubit, ScheduleState>(
      bloc: cubit,
      // Only rebuild when selected groups, available groups, or active filters change
      buildWhen: (prev, curr) {
        final p = prev.loadedOrNull;
        final c = curr.loadedOrNull;
        if (p == null || c == null) return prev != curr;
        return p.selectedGroup != c.selectedGroup ||
            p.availableGroups != c.availableGroups ||
            p.activeFilters != c.activeFilters;
      },
      builder: (context, state) {
        final s = state.loadedOrNull;
        if (s == null) return const SizedBox.shrink();

        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    if (s.selectedGroup.length == s.availableGroups.length &&
                        s.availableGroups.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Chip(
                          label: Text(AppLocalizations.of(context)!.allGroups),
                          onDeleted: () {
                            if (s.availableGroups.isNotEmpty) {
                              cubit.loadSchedule(s.availableGroups.first);
                            }
                          },
                          deleteIcon: const Icon(Icons.close, size: 16),
                          backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        ),
                      )
                    else
                      ..._buildGroupChips(context, s.selectedGroup, s.availableGroups),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: ActionChip(
                        avatar: Icon(Icons.add, size: 16, color: Theme.of(context).colorScheme.onSurface),
                        label: Text(AppLocalizations.of(context)!.add),
                        onPressed: onShowGroupSelector,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            FilterChipsBar(
              onChipTap: onOpenSelectionMenu,
              onClearFilter: cubit.clearFilter,
              activeFilters: s.activeFilters,
            ),
          ],
        );
      },
    );
  }
}

// ─── Lesson List Section ─────────────────────────────────────────────────────

class _LessonListSection extends StatelessWidget {
  final ScheduleCubit cubit;
  final void Function(DateTime) onDateChanged;

  const _LessonListSection({
    required this.cubit,
    required this.onDateChanged,
  });

  String _getLocalizedWeekday(BuildContext context, int weekday) {
    final l10n = AppLocalizations.of(context)!;
    return switch (weekday) {
      1 => l10n.monday,
      2 => l10n.tuesday,
      3 => l10n.wednesday,
      4 => l10n.thursday,
      5 => l10n.friday,
      6 => l10n.saturday,
      7 => l10n.sunday,
      _ => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScheduleCubit, ScheduleState>(
      bloc: cubit,
      // Only rebuild when scheduleItems or selectedDate changes
      buildWhen: (prev, curr) {
        final p = prev.loadedOrNull;
        final c = curr.loadedOrNull;
        if (p == null || c == null) return prev != curr;
        return p.scheduleItems != c.scheduleItems ||
            p.selectedDate != c.selectedDate;
      },
      builder: (context, state) {
        final s = state.loadedOrNull;

        final nonLoaded = state.maybeWhen(
          initial: () => Center(child: Text(AppLocalizations.of(context)!.loading)),
          loading: () => Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          error: (message) => Center(child: Text(message)),
          orElse: () => null,
        );
        if (nonLoaded != null) return nonLoaded;
        if (s == null) return const SizedBox();

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity == null) return;
            if (details.primaryVelocity! > 300) {
              onDateChanged(s.selectedDate.previousWorkday);
            } else if (details.primaryVelocity! < -300) {
              onDateChanged(s.selectedDate.nextWorkday);
            }
          },
          child: RefreshIndicator(
            onRefresh: cubit.reloadFromCache,
            color: Theme.of(context).colorScheme.primary,
            child: s.scheduleItems.isEmpty
                ? Center(child: Text(AppLocalizations.of(context)!.noResults))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: s.scheduleItems.length,
                    itemBuilder: (context, index) {
                      final item = s.scheduleItems[index];

                      if (item is DayHeaderItem) {
                        return Padding(
                          padding: const EdgeInsets.only(
                            top: 16, bottom: 8, left: 16, right: 16,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _getLocalizedWeekday(context, item.weekday),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
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
                        return GroupDivider(groupName: item.groupName);
                      }

                      if (item is TimeDividerItem) {
                        return const TimeDivider();
                      }

                      if (item is LessonItem) {
                        return LessonCard(lesson: item.lesson);
                      }

                      return const SizedBox();
                    },
                  ),
          ),
        );
      },
    );
  }
}
