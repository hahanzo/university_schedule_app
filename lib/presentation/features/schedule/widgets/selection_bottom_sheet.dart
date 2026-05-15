import 'package:flutter/material.dart';
import 'package:university_schedule_app/l10n/app_localizations.dart';

class SelectionBottomSheet extends StatelessWidget {
  final String title;
  final List<String> items;
  final Function(String) onItemSelected;

  const SelectionBottomSheet({
    super.key,
    required this.title,
    required this.items,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: items.length,
              separatorBuilder: (context, index) => Divider(
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
                height: 1,
              ),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.clear,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      AppLocalizations.of(context)!.clearFilter,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      onItemSelected('RESET');
                      Navigator.pop(context);
                    },
                  );
                }

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    items[index],
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    onItemSelected(items[index]);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
