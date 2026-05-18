import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/filter_keys.dart';
import '../../../../core/injection.dart';
import '../../../../core/utils/date_extensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../blocs/teacher_schedule_cubit.dart';
import '../blocs/schedule_state.dart';
import '../models/schedule_list_item.dart';
import '../widgets/filter_chips_bar.dart';
import '../widgets/selection_bottom_sheet.dart';
import '../widgets/time_divider.dart';
import '../widgets/lesson_card.dart';
import '../widgets/calendar_strip.dart';
import '../widgets/schedule_header.dart';
import '../widgets/group_divider.dart';
import '../widgets/group_selector.dart' show GroupSelector;

class TeacherScheduleScreen extends StatefulWidget {
  const TeacherScheduleScreen({super.key});

  @override
  State<TeacherScheduleScreen> createState() => _TeacherScheduleScreenState();
}

class _TeacherScheduleScreenState extends State<TeacherScheduleScreen> {
  late TeacherScheduleCubit _cubit;
  bool _isFilterVisible = false;

  /// id → name cache populated after first load
  Map<String, String> _teacherNames = {};

  @override
  void initState() {
    super.initState();
    _cubit = getIt<TeacherScheduleCubit>();
    _initTeachers();
  }

  Future<void> _initTeachers() async {
    try {
      _teacherNames = await _cubit.getAvailableTeachers();
    } catch (_) {}

    if (_teacherNames.isEmpty) {
      _cubit.loadTeacher(AppConstants.defaultTeacherId);
      return;
    }

    final initialId = _teacherNames.containsKey(AppConstants.defaultTeacherId)
        ? AppConstants.defaultTeacherId
        : _teacherNames.keys.first;

    _cubit.loadTeacher(initialId);
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
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != currentDate) {
      _cubit.changeDate(picked.closestWorkday);
    }
  }

  void _toggleFilters() {
    setState(() => _isFilterVisible = !_isFilterVisible);
  }

  /// Shows a searchable bottom sheet to pick multiple teachers.
  void _showTeacherSelector() {
    final s = _cubit.state.loadedOrNull;
    if (s == null || _teacherNames.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: _TeacherPickerSheet(
            teacherNames: _teacherNames,
            selectedIds: s.selectedGroup,
            scrollController: scrollController,
            onSelected: (ids) {
              Navigator.pop(ctx);
              _cubit.loadMultipleTeachers(ids);
            },
          ),
        ),
      ),
    );
  }

  void _openSelectionMenu(String filterKey) {
    final s = _cubit.state.loadedOrNull;
    if (s == null) return;

    final filterLabels = {
      FilterKeys.group:   AppLocalizations.of(context)!.group,
      FilterKeys.subject: AppLocalizations.of(context)!.subject,
      FilterKeys.time:    AppLocalizations.of(context)!.time,
    };

    final isNumerator = s.selectedDate.isNumeratorWeek;
    final weekLessons = s.allLessons.where((l) {
      final wt = l.weekType.toLowerCase();
      if (wt.isEmpty || wt == 'all' || wt == 'both' || wt == 'always') return true;
      return isNumerator ? wt == 'numerator' : wt == 'denominator';
    }).toList();

    if (filterKey == FilterKeys.group) {
      final activeGroupStr = s.activeFilters[FilterKeys.group];
      final selectedGroups = activeGroupStr?.split(',') ?? [];
      final availableGroupsInSchedule = weekLessons.map((l) => l.groupId).toSet().toList()..sort();

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return Padding(
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
                  selectedGroups: selectedGroups,
                  availableGroups: availableGroupsInSchedule,
                  onGroupsChanged: (newGroups) {
                    if (newGroups.isEmpty) {
                      _cubit.clearFilter(FilterKeys.group);
                    } else {
                      _cubit.applyFilter(group: newGroups.join(','));
                    }
                  },
                ),
              ),
            ),
          );
        },
      );
      return;
    }

    final options = switch (filterKey) {
      FilterKeys.subject => weekLessons.map((l) => l.subjectName).toSet().toList()..sort(),
      FilterKeys.time    => weekLessons.map((l) => l.timeStart).toSet().toList()..sort((a, b) {
          int parseTime(String t) {
            final parts = t.split(':');
            if (parts.length != 2) return 0;
            return int.parse(parts[0]) * 60 + int.parse(parts[1]);
          }
          return parseTime(a).compareTo(parseTime(b));
        }),
      _ => <String>[],
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SelectionBottomSheet(
        title: filterLabels[filterKey] ?? filterKey,
        items: options,
        onItemSelected: (selected) {
          final value = selected == 'RESET' ? null : selected;
          if (filterKey == FilterKeys.group) _cubit.applyFilter(group: value);
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
        if (FocusScope.of(context).hasFocus) FocusScope.of(context).unfocus();
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

              // Calendar strip
              _TeacherCalendarSection(
                cubit: _cubit,
                onDateChanged: _onDateChanged,
                onMonthTap: _showDatePicker,
                onChangeMonth: _changeMonth,
              ),

              // Filter bar
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _isFilterVisible
                    ? _TeacherFilterBarSection(
                        cubit: _cubit,
                        teacherNames: _teacherNames,
                        onShowTeacherSelector: _showTeacherSelector,
                        onOpenSelectionMenu: _openSelectionMenu,
                      )
                    : const SizedBox(width: double.infinity, height: 0),
              ),

              // Lesson list
              Expanded(
                child: _TeacherLessonListSection(
                  cubit: _cubit,
                  teacherNames: _teacherNames,
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

// ─── Calendar strip ───────────────────────────────────────────────────────────

class _TeacherCalendarSection extends StatelessWidget {
  final TeacherScheduleCubit cubit;
  final void Function(DateTime) onDateChanged;
  final Future<void> Function(DateTime) onMonthTap;
  final void Function(DateTime, int) onChangeMonth;

  const _TeacherCalendarSection({
    required this.cubit,
    required this.onDateChanged,
    required this.onMonthTap,
    required this.onChangeMonth,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TeacherScheduleCubit, ScheduleState>(
      bloc: cubit,
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

// ─── Filter bar ───────────────────────────────────────────────────────────────

class _TeacherFilterBarSection extends StatelessWidget {
  final TeacherScheduleCubit cubit;
  final Map<String, String> teacherNames;
  final VoidCallback onShowTeacherSelector;
  final void Function(String) onOpenSelectionMenu;

  const _TeacherFilterBarSection({
    required this.cubit,
    required this.teacherNames,
    required this.onShowTeacherSelector,
    required this.onOpenSelectionMenu,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TeacherScheduleCubit, ScheduleState>(
      bloc: cubit,
      buildWhen: (prev, curr) {
        final p = prev.loadedOrNull;
        final c = curr.loadedOrNull;
        if (p == null || c == null) return prev != curr;
        return p.selectedGroup != c.selectedGroup ||
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
                    ...s.selectedGroup.map((id) {
                      final teacherName = teacherNames[id] ?? id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InputChip(
                          avatar: const Icon(Icons.person, size: 16),
                          label: Text(
                            teacherName,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onDeleted: s.selectedGroup.length > 1
                              ? () {
                                  final newSelected = List<String>.from(s.selectedGroup)..remove(id);
                                  cubit.loadMultipleTeachers(newSelected);
                                }
                              : null,
                          deleteIcon: s.selectedGroup.length > 1
                              ? const Icon(Icons.close, size: 16)
                              : null,
                          onPressed: onShowTeacherSelector,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.1),
                        ),
                      );
                    }),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: ActionChip(
                        avatar: Icon(Icons.add, size: 16, color: Theme.of(context).colorScheme.onSurface),
                        label: Text(AppLocalizations.of(context)!.add),
                        onPressed: onShowTeacherSelector,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Group / Subject / Time filter chips
            FilterChipsBar(
              filterKeys: const [
                FilterKeys.group,
                FilterKeys.subject,
                FilterKeys.time,
              ],
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

// ─── Lesson list ─────────────────────────────────────────────────────────────

class _TeacherLessonListSection extends StatelessWidget {
  final TeacherScheduleCubit cubit;
  final Map<String, String> teacherNames;
  final void Function(DateTime) onDateChanged;

  const _TeacherLessonListSection({
    required this.cubit,
    required this.teacherNames,
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
    return BlocBuilder<TeacherScheduleCubit, ScheduleState>(
      bloc: cubit,
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
          initial: () =>
              Center(child: Text(AppLocalizations.of(context)!.loading)),
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
                ? Center(
                    child: Text(AppLocalizations.of(context)!.noResults),
                  )
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
                                      color:
                                          Theme.of(context).colorScheme.primary,
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
                        return GroupDivider(groupName: teacherNames[item.groupName] ?? item.groupName);
                      }
                      if (item is TimeDividerItem) return const TimeDivider();
                      if (item is LessonItem) {
                        return LessonCard(
                          lesson: item.lesson,
                          showGroupInstead: true, // show group, not teacher
                        );
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

// ─── Teacher picker sheet ────────────────────────────────────────────────────

class _TeacherPickerSheet extends StatefulWidget {
  final Map<String, String> teacherNames; // id → name
  final List<String> selectedIds;
  final ScrollController scrollController;
  final void Function(List<String> ids) onSelected;

  const _TeacherPickerSheet({
    required this.teacherNames,
    required this.selectedIds,
    required this.scrollController,
    required this.onSelected,
  });

  @override
  State<_TeacherPickerSheet> createState() => _TeacherPickerSheetState();
}

class _TeacherPickerSheetState extends State<_TeacherPickerSheet> {
  String _query = '';
  late Set<String> _localSelected;

  @override
  void initState() {
    super.initState();
    _localSelected = Set.from(widget.selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.teacherNames.entries
        .where((e) => e.value.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade400,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            // Removed autofocus: true
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.search,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: widget.scrollController,
            itemCount: filtered.length,
            itemBuilder: (ctx, i) {
              final entry = filtered[i];
              final isSelected = _localSelected.contains(entry.key);
              return CheckboxListTile(
                title: Text(entry.value),
                value: isSelected,
                activeColor: Theme.of(context).colorScheme.primary,
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _localSelected.add(entry.key);
                    } else if (_localSelected.length > 1) {
                      _localSelected.remove(entry.key);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context)!.minOneGroup))
                      );
                    }
                  });
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                if (_localSelected.isNotEmpty) {
                  widget.onSelected(_localSelected.toList());
                }
              },
              child: Text(AppLocalizations.of(context)!.done),
            ),
          ),
        ),
      ],
    );
  }
}
