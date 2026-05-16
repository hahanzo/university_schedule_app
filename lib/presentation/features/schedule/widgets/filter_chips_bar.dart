import 'package:flutter/material.dart';
import 'package:university_schedule_app/l10n/app_localizations.dart';

class FilterChipsBar extends StatelessWidget {
  final Function(String filterKey) onChipTap;
  final Function(String filterKey) onClearFilter;
  final Map<String, String?> activeFilters;

  const FilterChipsBar({
    super.key,
    required this.onChipTap,
    required this.onClearFilter,
    this.activeFilters = const {},
  });

  @override
  Widget build(BuildContext context) {
    final filterCategories = [
      {'label': AppLocalizations.of(context)!.teacher, 'key': 'teacher'},
      {'label': AppLocalizations.of(context)!.time, 'key': 'time'},
      {'label': AppLocalizations.of(context)!.subject, 'key': 'subject'},
    ];

    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: filterCategories.map((filter) {
            final key = filter['key']!;
            final label = filter['label']!;
            final isActive =
                activeFilters.containsKey(key) && activeFilters[key] != null;
            final filterValue = activeFilters[key];

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ConstrainedBox(
                // Cap chip width so long subject/teacher names are truncated
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
                  selectedColor: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.2),
                  side: BorderSide(
                    color: isActive
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade300,
                    width: isActive ? 2 : 1,
                  ),
                  deleteIcon:
                      isActive ? const Icon(Icons.close, size: 16) : null,
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
