import 'package:flutter/material.dart';
import 'package:university_schedule_app/l10n/app_localizations.dart';

// Extracts the prefix before the first dash: 'KN-11-1' → 'KN'
String groupPrefix(String groupId) {
  final idx = groupId.indexOf('-');
  return idx == -1 ? groupId : groupId.substring(0, idx);
}

enum _CategoryStatus { none, partial, all }

class GroupSelector extends StatefulWidget {
  final List<String> selectedGroups;
  final List<String> availableGroups;
  final Function(List<String>) onGroupsChanged;

  const GroupSelector({
    super.key,
    required this.selectedGroups,
    required this.availableGroups,
    required this.onGroupsChanged,
  });

  @override
  State<GroupSelector> createState() => _GroupSelectorState();
}

class _GroupSelectorState extends State<GroupSelector> {
  late TextEditingController _searchController;
  late Map<String, List<String>> _categories;

  // Local state — no network calls until Done is pressed
  late List<String> _localSelected;

  String _searchQuery = '';
  final Set<String> _expandedPrefixes = {};

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _localSelected = List.from(widget.selectedGroups);
    _categories = _buildCategories(widget.availableGroups);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map<String, List<String>> _buildCategories(List<String> groups) {
    final sorted = [...groups]..sort();
    final map = <String, List<String>>{};
    for (final g in sorted) {
      (map[groupPrefix(g)] ??= []).add(g);
    }
    final keys = map.keys.toList()..sort();
    return {for (final k in keys) k: map[k]!};
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (_searchQuery.isNotEmpty) {
        for (final entry in _categories.entries) {
          if (entry.value.any((g) => g.toLowerCase().contains(_searchQuery))) {
            _expandedPrefixes.add(entry.key);
          }
        }
      }
    });
  }

  bool get _areAllSelected =>
      _localSelected.length == widget.availableGroups.length;

  _CategoryStatus _statusOf(List<String> subgroups) {
    if (_areAllSelected) return _CategoryStatus.all;
    final count = subgroups.where((g) => _localSelected.contains(g)).length;
    if (count == 0) return _CategoryStatus.none;
    if (count == subgroups.length) return _CategoryStatus.all;
    return _CategoryStatus.partial;
  }

  void _selectAll() => setState(() {
    _localSelected = List.from(widget.availableGroups);
  });

  void _deselectAll() => setState(() {
    _localSelected = widget.availableGroups.isNotEmpty
        ? [widget.availableGroups.first]
        : [];
  });

  void _toggleCategory(String prefix, List<String> subgroups) {
    final status = _statusOf(subgroups);
    setState(() {
      if (status == _CategoryStatus.all) {
        // Deselect the whole category
        final remaining = _localSelected
            .where((g) => groupPrefix(g) != prefix)
            .toList();
        _localSelected = remaining.isEmpty ? [subgroups.first] : remaining;
      } else {
        // Select all in category
        for (final g in subgroups) {
          if (!_localSelected.contains(g)) _localSelected.add(g);
        }
      }
    });
  }

  void _toggleSubgroup(String group) {
    setState(() {
      if (_areAllSelected) {
        // Switch to only this one
        _localSelected = [group];
        return;
      }
      if (_localSelected.contains(group)) {
        if (_localSelected.length > 1) _localSelected.remove(group);
        // else: can't remove the last group — silently ignore
      } else {
        _localSelected.add(group);
      }
    });
  }

  void _apply() {
    widget.onGroupsChanged(_localSelected);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.selectGroups,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: l10n.searchGroup,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
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
          const SizedBox(height: 8),

          Expanded(
            child: ListView(
              children: [
                // "All groups" row
                _AllGroupsRow(
                  isSelected: _areAllSelected,
                  label: l10n.allGroups,
                  colorScheme: colorScheme,
                  onTap: _areAllSelected ? _deselectAll : _selectAll,
                ),
                const Divider(height: 16),

                // Category sections
                for (final entry in _categories.entries) ...[
                  Builder(
                    builder: (ctx) {
                      final prefix = entry.key;
                      final subgroups = entry.value;
                      final visible = _searchQuery.isEmpty
                          ? subgroups
                          : subgroups
                                .where(
                                  (g) => g.toLowerCase().contains(_searchQuery),
                                )
                                .toList();

                      if (visible.isEmpty) return const SizedBox.shrink();

                      final status = _statusOf(subgroups);
                      final isExpanded = _expandedPrefixes.contains(prefix);
                      final selectedCount = _areAllSelected
                          ? subgroups.length
                          : subgroups
                                .where((g) => _localSelected.contains(g))
                                .length;

                      return _CategorySection(
                        prefix: prefix,
                        subgroups: visible,
                        status: status,
                        selectedCount: selectedCount,
                        localSelected: _localSelected,
                        areAllSelected: _areAllSelected,
                        isExpanded: isExpanded,
                        colorScheme: colorScheme,
                        onExpansionToggle: () => setState(() {
                          if (isExpanded) {
                            _expandedPrefixes.remove(prefix);
                          } else {
                            _expandedPrefixes.add(prefix);
                          }
                        }),
                        onCategoryToggle: () =>
                            _toggleCategory(prefix, subgroups),
                        onSubgroupToggle: _toggleSubgroup,
                      );
                    },
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _apply,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onSurface,
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
              child: Text(l10n.done),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─── All Groups Row ─────────────────────────────────────────────────────────

class _AllGroupsRow extends StatelessWidget {
  final bool isSelected;
  final String label;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _AllGroupsRow({
    required this.isSelected,
    required this.label,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        backgroundColor: Colors.transparent,
        selectedColor: colorScheme.primary.withValues(alpha: 0.15),
        checkmarkColor: colorScheme.primary,
        side: BorderSide(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.outline.withValues(alpha: 0.5),
          width: isSelected ? 2 : 1,
        ),
        labelStyle: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? colorScheme.primary : colorScheme.onSurface,
        ),
      ),
    );
  }
}

// ─── Category Section ───────────────────────────────────────────────────────

class _CategorySection extends StatelessWidget {
  final String prefix;
  final List<String> subgroups;
  final _CategoryStatus status;
  final int selectedCount;
  final List<String> localSelected;
  final bool areAllSelected;
  final bool isExpanded;
  final ColorScheme colorScheme;
  final VoidCallback onExpansionToggle;
  final VoidCallback onCategoryToggle;
  final void Function(String) onSubgroupToggle;

  const _CategorySection({
    required this.prefix,
    required this.subgroups,
    required this.status,
    required this.selectedCount,
    required this.localSelected,
    required this.areAllSelected,
    required this.isExpanded,
    required this.colorScheme,
    required this.onExpansionToggle,
    required this.onCategoryToggle,
    required this.onSubgroupToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isFullSelected = status == _CategoryStatus.all;
    final isPartial = status == _CategoryStatus.partial;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Prefix chip
            GestureDetector(
              onTap: onCategoryToggle,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isFullSelected
                      ? colorScheme.primary.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isFullSelected
                        ? colorScheme.primary
                        : colorScheme.outline.withValues(alpha: 0.45),
                    width: isFullSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      prefix,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isFullSelected
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                      ),
                    ),
                    // Badge: count of selected subgroups when partial
                    if (isPartial) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$selectedCount',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Spacer(),
            // Expand / collapse arrow
            IconButton(
              icon: AnimatedRotation(
                turns: isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.keyboard_arrow_down, size: 20),
              ),
              onPressed: onExpansionToggle,
              splashRadius: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ],
        ),

        // Subgroup chips — expand/collapse
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: isExpanded
              ? Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8, left: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: subgroups.map((group) {
                      // Individual chip is highlighted only when category
                      // is partially selected (not all of category selected)
                      final isSelected =
                          !areAllSelected &&
                          localSelected.contains(group) &&
                          status != _CategoryStatus.all;
                      return FilterChip(
                        key: ValueKey(group),
                        label: Text(group),
                        selected: isSelected,
                        onSelected: (_) => onSubgroupToggle(group),
                        backgroundColor: Colors.transparent,
                        selectedColor: colorScheme.primary.withValues(
                          alpha: 0.15,
                        ),
                        checkmarkColor: colorScheme.primary,
                        side: BorderSide(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.outline.withValues(alpha: 0.45),
                          width: isSelected ? 2 : 1,
                        ),
                        labelStyle: TextStyle(
                          fontSize: 13,
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                        ),
                      );
                    }).toList(),
                  ),
                )
              : const SizedBox.shrink(),
        ),

        const Divider(height: 10),
      ],
    );
  }
}
