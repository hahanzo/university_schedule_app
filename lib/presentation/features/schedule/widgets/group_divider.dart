import 'package:flutter/material.dart';

class GroupDivider extends StatelessWidget {
  final String groupName;

  const GroupDivider({super.key, required this.groupName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            groupName,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
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
