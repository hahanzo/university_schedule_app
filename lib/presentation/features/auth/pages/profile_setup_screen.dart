import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/injection.dart';
import '../../../../domain/repositories/schedule_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../data/models/user_profile.dart';
import '../blocs/auth_cubit.dart';

class ProfileSetupScreen extends StatefulWidget {
  final UserProfile userProfile;

  const ProfileSetupScreen({super.key, required this.userProfile});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScheduleRepository _scheduleRepository = getIt<ScheduleRepository>();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;
  String? _submitError;
  String? _selectedId;

  List<String> _groups = [];
  Map<String, String> _teachers = {};

  bool get _isTeacher => widget.userProfile.role == AppConstants.teacherRole;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
      _submitError = null;
    });

    try {
      if (_isTeacher) {
        _teachers = await _scheduleRepository.getAllAvailableTeachers();
        _selectedId = widget.userProfile.teacherId;
      } else {
        _groups = await _scheduleRepository.getAllAvailableGroups();
        _selectedId = widget.userProfile.groupId;
      }
    } catch (e) {
      _loadError = e.toString();
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  List<_SelectionOption> _buildOptions(String query) {
    final normalizedQuery = query.toLowerCase().trim();
    final options = _isTeacher
        ? _teachers.entries
            .map((entry) => _SelectionOption(
                  id: entry.key,
                  label: entry.value,
                ))
            .toList()
        : _groups
            .map((group) => _SelectionOption(id: group, label: group))
            .toList();

    if (normalizedQuery.isEmpty) {
      return options;
    }

    return options
        .where((option) =>
            option.label.toLowerCase().contains(normalizedQuery) ||
            option.id.toLowerCase().contains(normalizedQuery))
        .toList();
  }

  Future<void> _saveSelection() async {
    if (_selectedId == null || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
      _submitError = null;
    });

    try {
      await context.read<AuthCubit>().updateUserSelection(
            groupId: _isTeacher ? null : _selectedId,
            teacherId: _isTeacher ? _selectedId : null,
          );
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _submitError = e.toString().replaceAll('Exception: ', ''));
    }

    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final title = _isTeacher ? l10n.selectTeacher : l10n.selectGroup;
    final searchHint = _isTeacher ? l10n.searchTeacher : l10n.searchGroup;
    final options = _buildOptions(_searchController.text);

    return Scaffold(
      appBar: AppBar(title: Text(title), centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _loadError != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _loadError!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: _loadOptions,
                            child: Text(l10n.retry),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: searchHint,
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: options.isEmpty
                              ? Center(child: Text(l10n.noResults))
                              : ListView.separated(
                                  itemCount: options.length,
                                  separatorBuilder: (_, __) => const Divider(),
                                  itemBuilder: (context, index) {
                                    final option = options[index];
                                    return RadioListTile<String>(
                                      value: option.id,
                                      groupValue: _selectedId,
                                      title: Text(option.label),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedId = value;
                                          _submitError = null;
                                        });
                                      },
                                    );
                                  },
                                ),
                        ),
                        if (_submitError != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _submitError!,
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ],
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed:
                                _selectedId == null || _isSaving ? null : _saveSelection,
                            child: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(l10n.done),
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}

class _SelectionOption {
  final String id;
  final String label;

  const _SelectionOption({required this.id, required this.label});
}
