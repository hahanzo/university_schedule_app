import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/dev_constants.dart';
import '../../../../core/injection.dart';
import '../../../../data/models/user_profile.dart';
import '../../../../domain/repositories/schedule_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../auth/blocs/auth_cubit.dart';
import '../widgets/social_link_row.dart';

class ProfileEditScreen extends StatefulWidget {
  final UserProfile userProfile;

  const ProfileEditScreen({super.key, required this.userProfile});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _picker = ImagePicker();
  final _scheduleRepository = getIt<ScheduleRepository>();

  bool _isSaving = false;
  bool _isLoadingOptions = true;
  String? _optionsError;
  String? _submitError;
  String? _selectedGroupId;
  XFile? _pickedAvatar;
  bool _removeAvatar = false;
  List<String> _groups = [];
  final List<Map<String, String>> _socialEntries = [];

  bool get _isTeacher => widget.userProfile.role == AppConstants.teacherRole;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.userProfile.name;
    _selectedGroupId = widget.userProfile.groupId;
    widget.userProfile.socialLinks?.forEach((k, v) {
      _socialEntries.add({'platform': k, 'url': v});
    });
    _loadOptions();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    if (_isTeacher) {
      setState(() => _isLoadingOptions = false);
      return;
    }
    setState(() {
      _isLoadingOptions = true;
      _optionsError = null;
    });
    try {
      _groups = await _scheduleRepository.getAllAvailableGroups();
      if (_selectedGroupId != null && !_groups.contains(_selectedGroupId)) {
        _selectedGroupId = null;
      }
    } catch (e) {
      _optionsError = e.toString();
    }
    if (mounted) setState(() => _isLoadingOptions = false);
  }

  Future<void> _pickAvatar() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: AvatarConstants.maxDimension,
      maxHeight: AvatarConstants.maxDimension,
      imageQuality: AvatarConstants.imageQuality,
    );
    if (!mounted || image == null) return;
    setState(() {
      _pickedAvatar = image;
      _removeAvatar = false;
    });
  }

  void _removeAvatarImage() => setState(() {
        _pickedAvatar = null;
        _removeAvatar = true;
      });

  void _addSocialEntry() =>
      setState(() => _socialEntries.add({'platform': '', 'url': ''}));

  void _removeSocialEntry(int index) =>
      setState(() => _socialEntries.removeAt(index));

  Future<void> _saveProfile() async {
    if (_isSaving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_isTeacher && (_selectedGroupId ?? '').trim().isEmpty) {
      setState(() => _submitError = AppLocalizations.of(context)!.selectGroup);
      return;
    }

    final socialLinks = <String, String>{};
    for (final entry in _socialEntries) {
      final platform = (entry['platform'] ?? '').trim();
      final url = (entry['url'] ?? '').trim();
      if (platform.isNotEmpty && url.isNotEmpty) socialLinks[platform] = url;
    }

    setState(() {
      _isSaving = true;
      _submitError = null;
    });

    try {
      await context.read<AuthCubit>().updateProfile(
            name: _nameController.text.trim(),
            socialLinks: socialLinks,
            groupId: _isTeacher ? null : _selectedGroupId,
            avatarFilePath: _pickedAvatar?.path,
            avatarUrl: _removeAvatar ? '' : null,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(
          () => _submitError = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final avatarUrl = _removeAvatar ? '' : (widget.userProfile.avatarUrl ?? '').trim();
    final showAvatar = _pickedAvatar != null || avatarUrl.isNotEmpty;

    final ImageProvider? avatarImage = _pickedAvatar != null
        ? FileImage(File(_pickedAvatar!.path))
        : avatarUrl.isNotEmpty
            ? NetworkImage(avatarUrl)
            : null;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.editProfile), centerTitle: true),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _AvatarSection(
                avatarImage: avatarImage,
                showAvatar: showAvatar,
                onPickAvatar: _pickAvatar,
                onRemoveAvatar: _removeAvatarImage,
                l10n: l10n,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.fullName,
                  helperText: _isTeacher
                      ? 'This name appears in the schedule as the teacher'
                      : null,
                ),
                validator: _isTeacher
                    ? null
                    : (value) {
                        final t = value?.trim() ?? '';
                        if (t.isEmpty) return "Name is required.";
                        if (t.length < 2) return 'Minimum 2 characters.';
                        return null;
                      },
              ),
              const SizedBox(height: 16),
              if (!_isTeacher) ...[
                Text(
                  l10n.group,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                _GroupSelector(
                  isLoading: _isLoadingOptions,
                  error: _optionsError,
                  groups: _groups,
                  selectedGroupId: _selectedGroupId,
                  onGroupChanged: (v) => setState(() {
                    _selectedGroupId = v;
                    _submitError = null;
                  }),
                  onRetry: _loadOptions,
                  l10n: l10n,
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.contacts,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  TextButton.icon(
                    onPressed: _addSocialEntry,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l10n.add),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_socialEntries.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    l10n.noResults,
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ),
              ..._socialEntries.asMap().entries.map((e) => SocialLinkRow(
                    key: ValueKey(e.key),
                    initialPlatform: e.value['platform'] ?? '',
                    initialUrl: e.value['url'] ?? '',
                    onChanged: (platform, url) =>
                        _socialEntries[e.key] = {'platform': platform, 'url': url},
                    onRemove: () => _removeSocialEntry(e.key),
                  )),
              if (_submitError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _submitError!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.save),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarSection extends StatelessWidget {
  final ImageProvider? avatarImage;
  final bool showAvatar;
  final VoidCallback onPickAvatar;
  final VoidCallback onRemoveAvatar;
  final AppLocalizations l10n;

  const _AvatarSection({
    required this.avatarImage,
    required this.showAvatar,
    required this.onPickAvatar,
    required this.onRemoveAvatar,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: AvatarConstants.avatarRadius,
            backgroundColor: colorScheme.primaryContainer,
            backgroundImage: avatarImage,
            child: showAvatar
                ? null
                : Icon(
                    Icons.person,
                    size: AvatarConstants.avatarIconSize,
                    color: colorScheme.onPrimaryContainer,
                  ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onPickAvatar,
                icon: const Icon(Icons.photo_camera),
                label: Text(l10n.changePhoto),
              ),
              if (showAvatar)
                TextButton.icon(
                  onPressed: onRemoveAvatar,
                  icon: const Icon(Icons.delete_outline),
                  label: Text(l10n.removePhoto),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GroupSelector extends StatelessWidget {
  final bool isLoading;
  final String? error;
  final List<String> groups;
  final String? selectedGroupId;
  final ValueChanged<String?> onGroupChanged;
  final VoidCallback onRetry;
  final AppLocalizations l10n;

  const _GroupSelector({
    required this.isLoading,
    required this.error,
    required this.groups,
    required this.selectedGroupId,
    required this.onGroupChanged,
    required this.onRetry,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(error!,
              style:
                  TextStyle(color: Theme.of(context).colorScheme.error)),
          const SizedBox(height: 8),
          FilledButton(onPressed: onRetry, child: Text(l10n.retry)),
        ],
      );
    }
    return DropdownButtonFormField<String>(
      initialValue: selectedGroupId,
      items: groups
          .map((g) => DropdownMenuItem(value: g, child: Text(g)))
          .toList(),
      onChanged: onGroupChanged,
      decoration: const InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
  }
}
