import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/date_extensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../blocs/student_schedule_cubit.dart';
import '../blocs/schedule_state.dart';
import '../models/schedule_list_item.dart';
import 'filter_chips_bar.dart';
import 'group_divider.dart';
import 'group_selector.dart' show groupPrefix;
import 'lesson_card.dart';
import 'time_divider.dart';

// ─── Filter bar ───────────────────────────────────────────────────────────────

class StudentFilterBar extends StatelessWidget {
  final StudentScheduleCubit cubit;
  final VoidCallback onShowGroupSelector;
  final void Function(String) onOpenSelectionMenu;

  const StudentFilterBar({
    super.key,
    required this.cubit,
    required this.onShowGroupSelector,
    required this.onOpenSelectionMenu,
  });

  List<Widget> _buildGroupChips(
    BuildContext context,
    List<String> selected,
    List<String> available,
  ) {
    final byPrefix = <String, List<String>>{};
    for (final g in available) {
      (byPrefix[groupPrefix(g)] ??= []).add(g);
    }

    final chips = <Widget>[];
    final handled = <String>{};
    final primaryAlpha = Theme.of(
      context,
    ).colorScheme.primary.withValues(alpha: 0.1);

    for (final group in selected) {
      if (handled.contains(group)) continue;
      final prefix = groupPrefix(group);
      final allInCategory = byPrefix[prefix] ?? [group];
      final allSelected = allInCategory.every(selected.contains);

      if (allSelected && allInCategory.length > 1) {
        chips.add(
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Chip(
              label: Text(prefix),
              backgroundColor: primaryAlpha,
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () {
                final remaining = selected
                    .where((g) => groupPrefix(g) != prefix)
                    .toList();
                cubit.loadMultipleGroups(
                  remaining.isNotEmpty ? remaining : [allInCategory.first],
                );
              },
            ),
          ),
        );
        handled.addAll(allInCategory);
      } else {
        chips.add(
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Chip(
              label: Text(group),
              backgroundColor: primaryAlpha,
              deleteIcon: selected.length > 1
                  ? const Icon(Icons.close, size: 16)
                  : null,
              onDeleted: selected.length > 1
                  ? () => cubit.removeGroup(group)
                  : null,
            ),
          ),
        );
        handled.add(group);
      }
    }
    return chips;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StudentScheduleCubit, ScheduleState>(
      bloc: cubit,
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
        final l10n = AppLocalizations.of(context)!;
        final primaryAlpha = Theme.of(
          context,
        ).colorScheme.primary.withValues(alpha: 0.1);

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
                    if (s.selectedGroup.length == s.availableGroups.length &&
                        s.availableGroups.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Chip(
                          label: Text(l10n.allGroups),
                          backgroundColor: primaryAlpha,
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () {
                            if (s.availableGroups.isNotEmpty) {
                              cubit.loadSchedule(s.availableGroups.first);
                            }
                          },
                        ),
                      )
                    else
                      ..._buildGroupChips(
                        context,
                        s.selectedGroup,
                        s.availableGroups,
                      ),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: ActionChip(
                        avatar: Icon(
                          Icons.add,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        label: Text(l10n.add),
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

// ─── Lesson list ──────────────────────────────────────────────────────────────

class StudentLessonList extends StatelessWidget {
  final StudentScheduleCubit cubit;
  final void Function(DateTime) onDateChanged;

  const StudentLessonList({
    super.key,
    required this.cubit,
    required this.onDateChanged,
  });

  static String _weekdayLabel(BuildContext context, int weekday) {
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
    return BlocBuilder<StudentScheduleCubit, ScheduleState>(
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
        final l10n = AppLocalizations.of(context)!;

        final placeholder = state.maybeWhen(
          initial: () => Center(child: Text(l10n.loading)),
          loading: () => Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          error: (msg) => Center(child: Text(msg)),
          orElse: () => null,
        );
        if (placeholder != null) return placeholder;
        if (s == null) return const SizedBox.shrink();

        return RepaintBoundary(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragEnd: (d) {
              final v = d.primaryVelocity;
              if (v == null) return;
              if (v > 300) onDateChanged(s.selectedDate.previousWorkday);
              if (v < -300) onDateChanged(s.selectedDate.nextWorkday);
            },
            child: RefreshIndicator(
              onRefresh: cubit.reloadFromCache,
              color: Theme.of(context).colorScheme.primary,
              child: s.scheduleItems.isEmpty
                  ? Center(child: Text(l10n.noResults))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: s.scheduleItems.length,
                      itemBuilder: (ctx, i) =>
                          _buildItem(ctx, s.scheduleItems[i]),
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildItem(BuildContext context, ScheduleListItem item) {
    if (item is DayHeaderItem) {
      return _DayHeader(
        weekday: item.weekday,
        label: _weekdayLabel(context, item.weekday),
      );
    }
    if (item is GroupHeaderItem) return GroupDivider(groupName: item.groupName);
    if (item is TimeDividerItem) return const TimeDivider();
    if (item is LessonItem) return LessonCard(lesson: item.lesson);
    return const SizedBox.shrink();
  }
}

class _DayHeader extends StatelessWidget {
  final int weekday;
  final String label;

  const _DayHeader({required this.weekday, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8, left: 16, right: 16),
      child: Row(
        children: [
          Icon(Icons.calendar_today, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }
}
