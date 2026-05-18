import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/string_extensions.dart';
import '../../../../data/models/user_profile.dart';
import '../../../../l10n/app_localizations.dart';
import 'profile_view_screen.dart';

class GroupMembersScreen extends StatefulWidget {
  final String groupId;

  const GroupMembersScreen({super.key, required this.groupId});

  @override
  State<GroupMembersScreen> createState() => _GroupMembersScreenState();
}

class _GroupMembersScreenState extends State<GroupMembersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Future<List<UserProfile>> _membersFuture;

  @override
  void initState() {
    super.initState();
    _membersFuture = _loadGroupMembers();
  }

  Future<List<UserProfile>> _loadGroupMembers() async {
    try {
      // Fetch all students with groupId prefix matching the group ID
      final studentsSnapshot = await _firestore
          .collection('users')
          .where('groupId', isGreaterThanOrEqualTo: widget.groupId)
          .where('groupId', isLessThanOrEqualTo: '${widget.groupId}\uf8ff')
          .get();

      // Fetch schedule documents matching the group ID prefix to get unique teacherIds
      final scheduleSnapshot = await _firestore
          .collection('schedule')
          .where('groupId', isGreaterThanOrEqualTo: widget.groupId)
          .where('groupId', isLessThanOrEqualTo: '${widget.groupId}\uf8ff')
          .get();

      final teacherIds = scheduleSnapshot.docs
          .map((doc) => doc.data()['teacherId'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      final members = <UserProfile>[];

      // Add students
      for (final doc in studentsSnapshot.docs) {
        final data = doc.data();
        members.add(_parseUserProfile(doc.id, data));
      }

      // Fetch teachers whose teacherId is in teacherIds
      if (teacherIds.isNotEmpty) {
        // Fetch teachers from the 'users' collection (who have logged in)
        final teachersSnapshot = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'teacher')
            .where('teacherId', whereIn: teacherIds)
            .get();

        for (final doc in teachersSnapshot.docs) {
          final data = doc.data();
          members.add(_parseUserProfile(doc.id, data));
        }
      }

      // Sort by name
      members.sort((a, b) => a.name.compareTo(b.name));
      return members;
    } catch (e) {
      print('Error loading group members: $e');
      rethrow;
    }
  }

  UserProfile _parseUserProfile(String docId, Map<String, dynamic> data) {
    Map<String, String>? socialLinks;
    final rawSocial = data['socialLinks'];
    if (rawSocial is Map) {
      socialLinks =
          rawSocial.map((k, v) => MapEntry(k.toString(), v.toString()));
    }

    return UserProfile(
      uid: docId,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'student',
      avatarUrl: data['avatarUrl'] as String?,
      socialLinks: socialLinks,
      groupId: data['groupId'] as String?,
      teacherId: data['teacherId'] as String?,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.members),
        centerTitle: true,
      ),
      body: FutureBuilder<List<UserProfile>>(
        future: _membersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            );
          }

          final members = snapshot.data ?? [];

          if (members.isEmpty) {
            return const SizedBox.shrink();
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: members.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final member = members[index];

              return ListTile(
                leading: _UserAvatar(
                  avatarUrl: member.avatarUrl,
                  name: member.name,
                  radius: 20,
                ),
                title: Text(member.name),
                subtitle: Text(
                  member.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: member.role == AppConstants.teacherRole
                    ? Chip(
                        label: Text(
                          l10n.teacher,
                          style: const TextStyle(fontSize: 11),
                        ),
                        backgroundColor:
                            theme.colorScheme.primary.withValues(alpha: 0.2),
                      )
                    : null,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProfileViewScreen(
                        userId: member.uid,
                        initialName: member.name,
                        initialAvatarUrl: member.avatarUrl,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
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
