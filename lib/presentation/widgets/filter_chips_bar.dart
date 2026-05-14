import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class FilterChipsBar extends StatelessWidget {
  final Function(String filterType) onChipTap;
  final Map<String, dynamic> activeFilters;

  const FilterChipsBar({
    super.key, 
    required this.onChipTap,
    this.activeFilters = const {},
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> filterCategories = [
      {'label': 'Викладач', 'icon': Icons.person_search_outlined, 'key': 'teacher'},
      {'label': 'Група', 'icon': Icons.group_outlined, 'key': 'group'},
      {'label': 'День', 'icon': Icons.calendar_today_outlined, 'key': 'dayOfWeek'},
      {'label': 'Година', 'icon': Icons.access_time, 'key': 'time'},
      {'label': 'Предмет', 'icon': Icons.book_outlined, 'key': 'subject'},
    ];

    return SizedBox(
      height: 56,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: filterCategories.length,
        itemBuilder: (context, index) {
          final filter = filterCategories[index];
          final isActive = activeFilters.containsKey(filter['key']);
          
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ActionChip(
              avatar: Icon(
                filter['icon'], 
                size: 16, 
                color: isActive ? AppColors.primary : AppColors.onSurfaceVariant
              ),
              label: Text(
                filter['label'],
                style: TextStyle(
                  color: isActive ? AppColors.primary : AppColors.onSurfaceVariant,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              backgroundColor: isActive 
                  ? AppColors.primary.withOpacity(0.1) 
                  : AppColors.surface.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isActive ? AppColors.primary : Colors.transparent,
                ),
              ),
              onPressed: () => onChipTap(filter['label']),
            ),
          );
        },
      ),
    );
  }
}