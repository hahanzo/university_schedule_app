import 'package:flutter/material.dart';
import 'package:university_schedule_app/l10n/app_localizations.dart';

class TimeDivider extends StatelessWidget {
  const TimeDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            AppLocalizations.of(context)!.completed,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          // Horizontal line
          Expanded(
            child: Container(
              height: 1,
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}
