import 'package:flutter/material.dart';
import 'package:university_schedule_app/l10n/app_localizations.dart';
import '../../../../core/constants/app_constants.dart';

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
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ScheduleUiConstants.selectionSheetPaddingHorizontal,
          vertical: ScheduleUiConstants.selectionSheetPaddingVertical,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(
              ScheduleUiConstants.selectionSheetBorderRadius,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: ScheduleUiConstants.selectionSheetGap),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: items.length + 1,
                separatorBuilder: (context, index) => Divider(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
                  height: ScheduleUiConstants.selectionSheetDividerHeight,
                ),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(
                          ScheduleUiConstants.selectionSheetItemPadding,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            ScheduleUiConstants.selectionSheetItemBorderRadius,
                          ),
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

                  final item = items[index - 1];

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      item,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      onItemSelected(item);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
