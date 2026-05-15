import 'package:flutter/material.dart';
import 'package:university_schedule_app/l10n/app_localizations.dart';

class FilterChipsBar extends StatelessWidget {
  // Callback when filter chip is tapped (to open selection menu)
  final Function(String filterKey) onChipTap;
  // Callback when filter X button is pressed (to clear filter)
  final Function(String filterKey) onClearFilter;
  // Map of active filters: key -> value (e.g., 'teacher' -> 'John Smith')
  final Map<String, String?> activeFilters;

  const FilterChipsBar({
    super.key,
    required this.onChipTap,
    required this.onClearFilter,
    this.activeFilters = const {},
  });

  @override
  Widget build(BuildContext context) {
    // Define available filter types
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
            // Check if this filter is currently active
            final isActive =
                activeFilters.containsKey(key) && activeFilters[key] != null;
            final filterValue = activeFilters[key];

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                key: ValueKey(key),
                // Display label + value if filter is active
                label: Text(
                  isActive ? '$label: $filterValue' : label,
                  overflow: TextOverflow.ellipsis,
                ),
                selected: isActive,
                // Green theme - same color scheme as group selector
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
                // Show X delete button only if filter is active
                deleteIcon: isActive ? const Icon(Icons.close, size: 16) : null,
                onDeleted: isActive ? () => onClearFilter(key) : null,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
