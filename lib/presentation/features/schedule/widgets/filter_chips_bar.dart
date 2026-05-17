import 'package:flutter/material.dart';
import 'package:university_schedule_app/core/constants/filter_keys.dart';
import 'package:university_schedule_app/l10n/app_localizations.dart';

class FilterChipsBar extends StatelessWidget {
  final Function(String filterKey) onChipTap;
  final Function(String filterKey) onClearFilter;
  final Map<String, String?> activeFilters;

  /// Optional custom set of filter keys to display.
  /// Defaults to [teacher, time, subject] when null (student schedule).
  final List<String>? filterKeys;

  const FilterChipsBar({
    super.key,
    required this.onChipTap,
    required this.onClearFilter,
    this.activeFilters = const {},
    this.filterKeys,
  });

  String _labelFor(BuildContext context, String key) {
    final l = AppLocalizations.of(context)!;
    return switch (key) {
      FilterKeys.teacher => l.teacher,
      FilterKeys.subject => l.subject,
      FilterKeys.time    => l.time,
      FilterKeys.group   => l.group,
      _ => key,
    };
  }

  @override
  Widget build(BuildContext context) {
    final keys = filterKeys ??
        [FilterKeys.teacher, FilterKeys.time, FilterKeys.subject];

    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: keys.map((key) {
            final label = _labelFor(context, key);
            final isActive =
                activeFilters.containsKey(key) && activeFilters[key] != null;
            final filterValue = activeFilters[key];

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ConstrainedBox(
                // Cap chip width so long names are truncated
                constraints: const BoxConstraints(maxWidth: 200),
                child: FilterChip(
                  key: ValueKey(key),
                  label: Text(
                    isActive ? '$label: $filterValue' : label,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  selected: isActive,
                  onSelected: (_) => onChipTap(key),
                  backgroundColor: Colors.transparent,
                  selectedColor:
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  side: BorderSide(
                    color: isActive
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade300,
                    width: isActive ? 2 : 1,
                  ),
                  deleteIcon: isActive ? const Icon(Icons.close, size: 16) : null,
                  onDeleted: isActive ? () => onClearFilter(key) : null,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
