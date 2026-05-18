import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/injection.dart';
import '../../../../core/utils/string_extensions.dart';
import '../../../../data/models/user_profile.dart';
import '../../../../domain/repositories/schedule_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../auth/blocs/auth_cubit.dart';
import '../../auth/blocs/auth_state.dart';
import '../blocs/settings_cubit.dart';
import '../blocs/settings_state.dart';
import '../widgets/settings_choice_tile.dart';
import 'profile_edit_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ScheduleRepository _scheduleRepository = getIt<ScheduleRepository>();
  Map<String, String> _teacherNames = {};

  @override
  void initState() {
    super.initState();
    _loadTeacherNames();
  }

  Future<void> _loadTeacherNames() async {
    try {
      _teacherNames = await _scheduleRepository.getAllAvailableTeachers();
    } catch (_) {}

    if (mounted) {
      setState(() {});
    }
  }

  String _roleLabel(AppLocalizations l10n, String role) {
    return role == AppConstants.teacherRole ? l10n.teacher : l10n.students;
  }

  String _teacherLabel(String? teacherId, AppLocalizations l10n) {
    if (teacherId == null || teacherId.trim().isEmpty) {
      return l10n.notSet;
    }
    return _teacherNames[teacherId] ?? teacherId;
  }

  String _groupLabel(String? groupId, AppLocalizations l10n) {
    if (groupId == null || groupId.trim().isEmpty) {
      return l10n.notSet;
    }
    return groupId;
  }

  List<_ProfileContactItem> _buildContacts(UserProfile user) {
    final contacts = <_ProfileContactItem>[];
    final links = user.socialLinks ?? {};
    for (final entry in links.entries) {
      if (entry.value.trim().isNotEmpty) {
        contacts.add(
          _ProfileContactItem(
            icon: _socialIcon(entry.key),
            label: entry.key,
            value: entry.value.trim(),
          ),
        );
      }
    }
    return contacts;
  }

  IconData _socialIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'telegram':
        return Icons.send;
      case 'instagram':
        return Icons.camera_alt;
      case 'facebook':
        return Icons.facebook;
      case 'whatsapp':
        return Icons.chat;
      case 'телефон':
      case 'phone':
        return Icons.phone;
      case 'linkedin':
        return Icons.work;
      case 'youtube':
        return Icons.play_circle;
      default:
        return Icons.link;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings), centerTitle: true),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          final userProfile = authState.maybeWhen(
            authenticated: (user) => user,
            orElse: () => null,
          );

          return ListView(
            padding: const EdgeInsets.all(
              SettingsUiConstants.horizontalPadding,
            ),
            children: [
              if (userProfile != null) ...[
                if (userProfile.role == AppConstants.teacherRole &&
                    userProfile.name.trim().isEmpty) ...[
                  _MissingNameBanner(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ProfileEditScreen(userProfile: userProfile),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                _ProfileCard(
                  userProfile: userProfile,
                  roleLabel: _roleLabel(l10n, userProfile.role),
                  groupLabel: _groupLabel(userProfile.groupId, l10n),
                  teacherLabel: _teacherLabel(userProfile.teacherId, l10n),
                  contacts: _buildContacts(userProfile),
                  onEdit: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          ProfileEditScreen(userProfile: userProfile),
                    ),
                  ),
                ),
                const SizedBox(
                  height: SettingsUiConstants.verticalPaddingSmall,
                ),
              ],

              // Theme section
              BlocBuilder<SettingsCubit, SettingsState>(
                builder: (context, state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Text(
                          l10n.theme,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SettingsChoiceTile<ThemeMode>(
                        title: l10n.system,
                        value: ThemeMode.system,
                        groupValue: state.themeMode,
                        onChanged: (v) =>
                            context.read<SettingsCubit>().changeTheme(v!),
                      ),
                      SettingsChoiceTile<ThemeMode>(
                        title: l10n.light,
                        value: ThemeMode.light,
                        groupValue: state.themeMode,
                        onChanged: (v) =>
                            context.read<SettingsCubit>().changeTheme(v!),
                      ),
                      SettingsChoiceTile<ThemeMode>(
                        title: l10n.dark,
                        value: ThemeMode.dark,
                        groupValue: state.themeMode,
                        onChanged: (v) =>
                            context.read<SettingsCubit>().changeTheme(v!),
                      ),
                    ],
                  );
                },
              ),
              const Divider(height: 32),

              // Locale section
              BlocBuilder<SettingsCubit, SettingsState>(
                builder: (context, state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Text(
                          l10n.language,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SettingsChoiceTile<Locale>(
                        title: l10n.ukrainian,
                        value: const Locale('uk'),
                        groupValue: state.locale,
                        onChanged: (v) =>
                            context.read<SettingsCubit>().changeLocale(v!),
                      ),
                      SettingsChoiceTile<Locale>(
                        title: l10n.english,
                        value: const Locale('en'),
                        groupValue: state.locale,
                        onChanged: (v) =>
                            context.read<SettingsCubit>().changeLocale(v!),
                      ),
                    ],
                  );
                },
              ),
              const Divider(height: 32),

              // Sign out
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: Text(
                  l10n.signOut,
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () => context.read<AuthCubit>().signOut(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final UserProfile userProfile;
  final String roleLabel;
  final String groupLabel;
  final String teacherLabel;
  final List<_ProfileContactItem> contacts;
  final VoidCallback onEdit;

  const _ProfileCard({
    required this.userProfile,
    required this.roleLabel,
    required this.groupLabel,
    required this.teacherLabel,
    required this.contacts,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final avatarUrl = (userProfile.avatarUrl ?? '').trim();

    return Card(
      margin: const EdgeInsets.only(
        bottom: SettingsUiConstants.userCardMarginBottom,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.profile,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _UserAvatar(
                  avatarUrl: avatarUrl,
                  name: userProfile.name,
                  radius: 28,
                  textStyle: TextStyle(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userProfile.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userProfile.email,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${l10n.status}: $roleLabel',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (userProfile.role != AppConstants.teacherRole) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${l10n.group}: $groupLabel',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit),
                  tooltip: l10n.editProfile,
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class _ProfileContactItem {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileContactItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _MissingNameBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _MissingNameBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: theme.colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                Icons.edit_note,
                color: theme.colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.enterYourName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.nameIsDisplayedAsTeacher,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer.withValues(
                          alpha: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final double radius;
  final TextStyle? textStyle;

  const _UserAvatar({
    required this.avatarUrl,
    required this.name,
    required this.radius,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
    final url = (avatarUrl ?? '').trim().resolveEmulatorUrl();

    final fallback = Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: textStyle ??
            TextStyle(
              fontSize: radius * 0.75,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimaryContainer,
            ),
      ),
    );

    if (url.isEmpty) {
      return fallback;
    }

    return ClipOval(
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return fallback;
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: radius * 2,
              height: radius * 2,
              color: theme.colorScheme.primaryContainer,
              alignment: Alignment.center,
              child: SizedBox(
                width: radius,
                height: radius,
                child: const CircularProgressIndicator(strokeWidth: 1.5),
              ),
            );
          },
        ),
      ),
    );
  }
}
