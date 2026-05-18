import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/filter_keys.dart';
import '../../../../core/injection.dart';
import '../../../../core/utils/date_extensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../blocs/student_schedule_cubit.dart';
import '../blocs/schedule_state.dart';
import '../widgets/calendar_strip.dart';
import '../widgets/group_selector.dart' show GroupSelector;
import '../widgets/schedule_header.dart';
import '../widgets/selection_bottom_sheet.dart';
import '../widgets/student_schedule_sections.dart';

class StudentScheduleScreen extends StatefulWidget {
  final String? initialGroupId;

  const StudentScheduleScreen({super.key, this.initialGroupId});

  @override
  State<StudentScheduleScreen> createState() => _StudentScheduleScreenState();
}

class _StudentScheduleScreenState extends State<StudentScheduleScreen> {
  late StudentScheduleCubit _cubit;
  bool _isFilterVisible = false;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<StudentScheduleCubit>();
    final groupId = (widget.initialGroupId ?? '').trim();
    if (groupId.isNotEmpty) _cubit.loadSchedule(groupId);
  }

  @override
  void didUpdateWidget(covariant StudentScheduleScreen old) {
    super.didUpdateWidget(old);
    final newGroup = (widget.initialGroupId ?? '').trim();
    final oldGroup = (old.initialGroupId ?? '').trim();
    if (newGroup.isNotEmpty && newGroup != oldGroup) {
      _cubit.loadSchedule(newGroup);
    }
  }

  void _onDateChanged(DateTime date) =>
      _cubit.changeDate(date.closestWorkday);

  void _changeMonth(DateTime current, int offset) {
    final targetWeekday = current.weekday;
    final occurrence = ((current.day - 1) ~/ 7) + 1;
    final firstDay = DateTime(current.year, current.month + offset, 1);
    int daysToAdd = (targetWeekday - firstDay.weekday) % 7;
    if (daysToAdd < 0) daysToAdd += 7;
    var target = firstDay.add(Duration(days: daysToAdd + (occurrence - 1) * 7));
    if (target.month != firstDay.month) target = target.subtract(const Duration(days: 7));
    _cubit.changeDate(target);
  }

  Future<void> _showDatePicker(DateTime current) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != current) {
      _cubit.changeDate(picked.closestWorkday);
    }
  }

  void _showGroupSelector() {
    final s = _cubit.state.loadedOrNull;
    if (s == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          top: 16,
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: Container(
            color: Theme.of(ctx).colorScheme.surface,
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
    final l10n = AppLocalizations.of(context)!;

    final isNumerator = s.selectedDate.isNumeratorWeek;
    final weekLessons = s.allLessons.where((l) {
      final wt = l.weekType.toLowerCase();
      if (wt.isEmpty || wt == 'all' || wt == 'both' || wt == 'always') {
        return true;
      }
      return isNumerator ? wt == 'numerator' : wt == 'denominator';
    }).toList();

    final options = switch (filterKey) {
      FilterKeys.teacher =>
        weekLessons.map((l) => l.teacherName).toSet().toList()..sort(),
      FilterKeys.subject =>
        weekLessons.map((l) => l.subjectName).toSet().toList()..sort(),
      FilterKeys.time => weekLessons.map((l) => l.timeStart).toSet().toList()
        ..sort((a, b) {
          int t(String s) {
            final p = s.split(':');
            return p.length == 2
                ? int.parse(p[0]) * 60 + int.parse(p[1])
                : 0;
          }

          return t(a).compareTo(t(b));
        }),
      _ => <String>[],
    };

    final labels = {
      FilterKeys.teacher: l10n.teacher,
      FilterKeys.time: l10n.time,
      FilterKeys.subject: l10n.subject,
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SelectionBottomSheet(
        title: labels[filterKey] ?? filterKey,
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
      onPopInvokedWithResult: (didPop, _) {
        if (FocusScope.of(context).hasFocus) FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              ScheduleHeader(
                onSearchChanged: _cubit.searchLessons,
                onFilterPressed: () =>
                    setState(() => _isFilterVisible = !_isFilterVisible),
              ),
              _CalendarSection(
                cubit: _cubit,
                onDateChanged: _onDateChanged,
                onMonthTap: _showDatePicker,
                onChangeMonth: _changeMonth,
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _isFilterVisible
                    ? StudentFilterBar(
                        cubit: _cubit,
                        onShowGroupSelector: _showGroupSelector,
                        onOpenSelectionMenu: _openSelectionMenu,
                      )
                    : const SizedBox(width: double.infinity, height: 0),
              ),
              Expanded(
                child: StudentLessonList(
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

class _CalendarSection extends StatelessWidget {
  final StudentScheduleCubit cubit;
  final void Function(DateTime) onDateChanged;
  final Future<void> Function(DateTime) onMonthTap;
  final void Function(DateTime, int) onChangeMonth;

  const _CalendarSection({
    required this.cubit,
    required this.onDateChanged,
    required this.onMonthTap,
    required this.onChangeMonth,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StudentScheduleCubit, ScheduleState>(
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
        if (s == null) return const SizedBox.shrink();
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
