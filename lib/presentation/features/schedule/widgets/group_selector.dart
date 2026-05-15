import 'package:flutter/material.dart';
import 'package:university_schedule_app/l10n/app_localizations.dart';

class GroupSelector extends StatefulWidget {
  final List<String> selectedGroups;
  final List<String> availableGroups;
  final Function(String) onGroupToggle;

  const GroupSelector({
    super.key,
    required this.selectedGroups,
    required this.availableGroups,
    required this.onGroupToggle,
  });

  @override
  State<GroupSelector> createState() => _GroupSelectorState();
}

class _GroupSelectorState extends State<GroupSelector> {
  late TextEditingController _searchController;
  late List<String> _filteredGroups;
  late List<String> _sortedAvailableGroups;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _sortedAvailableGroups = _getSortedGroups(widget.availableGroups);
    _updateFilter('');
  }

  List<String> _getSortedGroups(List<String> groups) {
    final sorted = groups.toSet().toList();
    sorted.sort();
    return sorted;
  }

  void _updateFilter(String query) {
    if (query.isEmpty) {
      _filteredGroups = _sortedAvailableGroups;
    } else {
      final lowerQuery = query.toLowerCase();
      _filteredGroups = _sortedAvailableGroups
          .where((g) => g.toLowerCase().contains(lowerQuery))
          .toList();
    }
    setState(() {});
  }

  @override
  void didUpdateWidget(GroupSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.availableGroups != widget.availableGroups) {
      _sortedAvailableGroups = _getSortedGroups(widget.availableGroups);
      _updateFilter(_searchController.text);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleToggle(String group, bool isSelected) {
    if (!isSelected) {
      // User wants to uncheck
      if (widget.selectedGroups.length <= 1) {
        // Can't uncheck last one
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.minOneGroup),
            duration: const Duration(milliseconds: 1500),
          ),
        );
        return;
      }
    }
    widget.onGroupToggle(group);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.selectGroups,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          // Search field
          TextField(
            controller: _searchController,
            onChanged: _updateFilter,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.searchGroup,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _updateFilter('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Chips list
          Expanded(
            child: _filteredGroups.isEmpty
                ? Center(
                    child: Text(
                      AppLocalizations.of(context)!.groupsNotFound,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _filteredGroups.map((group) {
                        final isSelected =
                            widget.selectedGroups.contains(group);
                        return FilterChip(
                          key: ValueKey(group),
                          label: Text(group),
                          selected: isSelected,
                          onSelected: (value) => _handleToggle(group, value),
                          backgroundColor: Colors.transparent,
                          selectedColor:
                              colorScheme.primary.withValues(alpha: 0.2),
                          side: BorderSide(
                            color: isSelected
                                ? colorScheme.primary
                                : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                // onSurface is dark in light mode — ensures readable text on green
                foregroundColor: colorScheme.onSurface,
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
              child: Text(AppLocalizations.of(context)!.done),
            ),
          ),
        ],
      ),
    );
  }
}
