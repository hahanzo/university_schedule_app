import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class ScheduleHeader extends StatelessWidget {
  final VoidCallback onFilterPressed;
  final ValueChanged<String> onSearchChanged;

  const ScheduleHeader({
    super.key,
    required this.onFilterPressed,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          // Menu Button (Burger Icon)
          IconButton(
            icon: const Icon(Icons.menu, color: AppColors.onBackground),
            onPressed: () {
              // Here will be the Drawer opening
            },
          ),
          const SizedBox(width: 8),
          // Search Field
          Expanded(
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(28),
              ),
              child: TextField(
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search schedule',
                  hintStyle: TextStyle(color: AppColors.onSurfaceVariant.withOpacity(0.7)),
                  prefixIcon: const Icon(Icons.search, color: AppColors.onSurfaceVariant),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Filter Button
          IconButton(
            icon: const Icon(Icons.tune, color: AppColors.onBackground),
            onPressed: onFilterPressed,
          ),
        ],
      ),
    );
  }
}