import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';

class TeacherPickerSheet extends StatefulWidget {
  final Map<String, String> teacherNames;
  final List<String> selectedIds;
  final ScrollController scrollController;
  final void Function(List<String> ids) onSelected;

  const TeacherPickerSheet({
    super.key,
    required this.teacherNames,
    required this.selectedIds,
    required this.scrollController,
    required this.onSelected,
  });

  @override
  State<TeacherPickerSheet> createState() => _TeacherPickerSheetState();
}

class _TeacherPickerSheetState extends State<TeacherPickerSheet> {
  String _query = '';
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filtered = widget.teacherNames.entries
        .where((e) => e.value.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade400,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: l10n.search,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: widget.scrollController,
            itemCount: filtered.length,
            itemBuilder: (ctx, i) {
              final entry = filtered[i];
              final isSelected = _selected.contains(entry.key);
              return CheckboxListTile(
                title: Text(entry.value),
                value: isSelected,
                activeColor: Theme.of(context).colorScheme.primary,
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _selected.add(entry.key);
                    } else if (_selected.length > 1) {
                      _selected.remove(entry.key);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.minOneGroup)),
                      );
                    }
                  });
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _selected.isNotEmpty
                  ? () => widget.onSelected(_selected.toList())
                  : null,
              child: Text(l10n.done),
            ),
          ),
        ),
      ],
    );
  }
}
