import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/string_extensions.dart';
import '../../../../data/models/user_profile.dart';
import '../../../../l10n/app_localizations.dart';

class ProfileViewScreen extends StatefulWidget {
  final String userId;
  final String? initialName;
  final String? initialAvatarUrl;

  const ProfileViewScreen({
    super.key,
    required this.userId,
    this.initialName,
    this.initialAvatarUrl,
  });

  @override
  State<ProfileViewScreen> createState() => _ProfileViewScreenState();
}

class _ProfileViewScreenState extends State<ProfileViewScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Future<UserProfile?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  Future<UserProfile?> _loadProfile() async {
    try {
      final doc = await _firestore.collection('users').doc(widget.userId).get();
      final data = doc.data();
      if (data == null) return null;

      Map<String, String>? socialLinks;
      final rawSocial = data['socialLinks'];
      if (rawSocial is Map) {
        socialLinks =
            rawSocial.map((k, v) => MapEntry(k.toString(), v.toString()));
      }

      return UserProfile(
        uid: widget.userId,
        name: data['name'] ?? '',
        email: data['email'] ?? '',
        role: data['role'] ?? 'student',
        avatarUrl: data['avatarUrl'] as String?,
        socialLinks: socialLinks,
        groupId: data['groupId'] as String?,
        teacherId: data['teacherId'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile),
        centerTitle: true,
      ),
      body: FutureBuilder<UserProfile?>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = snapshot.data;
          if (profile == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_off, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noResults,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final avatarUrl = profile.avatarUrl;

          final roleLabel = profile.role == AppConstants.teacherRole
              ? l10n.teacher
              : l10n.students;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Avatar
              Center(
                child: _UserAvatar(
                  avatarUrl: avatarUrl,
                  name: profile.name,
                  radius: 48,
                  textStyle: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Name
              Center(
                child: Text(
                  profile.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),

              // Email
              Center(
                child: Text(
                  profile.email,
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),

              // Status and Group/Teacher
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(
                      label: '${l10n.status}:',
                      value: roleLabel,
                      theme: theme,
                    ),
                    if (profile.role != AppConstants.teacherRole) ...[
                      const SizedBox(height: 12),
                      _InfoRow(
                        label: '${l10n.group}:',
                        value: profile.groupId?.isNotEmpty == true
                            ? profile.groupId!
                            : l10n.notSet,
                        theme: theme,
                      ),
                    ],
                  ],
                ),
              ),

              // Contacts
              if (profile.socialLinks?.isNotEmpty == true) ...[
                const SizedBox(height: 24),
                Text(
                  l10n.contacts,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ...profile.socialLinks!.entries.map((entry) {
                  if (entry.value.trim().isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ContactItem(
                      platform: entry.key,
                      value: entry.value,
                      theme: theme,
                    ),
                  );
                }).toList(),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ContactItem extends StatelessWidget {
  final String platform;
  final String value;
  final ThemeData theme;

  const _ContactItem({
    required this.platform,
    required this.value,
    required this.theme,
  });

  IconData _getIcon(String platform) {
    final lower = platform.toLowerCase();
    if (lower.contains('telegram')) return Icons.send;
    if (lower.contains('instagram')) return Icons.image;
    if (lower.contains('facebook')) return Icons.people;
    if (lower.contains('whatsapp')) return Icons.chat;
    if (lower.contains('phone')) return Icons.phone;
    return Icons.link;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          _getIcon(platform),
          size: 18,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                platform,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
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
