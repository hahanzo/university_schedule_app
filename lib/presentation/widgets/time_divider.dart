import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class TimeDivider extends StatelessWidget {
  const TimeDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            'Завершено',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.onSurfaceVariant.withOpacity(0.6),
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(width: 8),
          // Horizontal line
          Expanded(
            child: Container(
              height: 1,
              color: AppColors.onSurfaceVariant.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }
}