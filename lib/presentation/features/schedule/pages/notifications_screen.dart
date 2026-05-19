import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../auth/blocs/auth_cubit.dart';
import '../../auth/blocs/auth_state.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Get current user profile
    final authState = context.watch<AuthCubit>().state;
    final userProfile = authState.maybeWhen(
      authenticated: (user) => user,
      orElse: () => null,
    );

    if (userProfile == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Сповіщення'),
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final bool isTeacher = userProfile.role == AppConstants.teacherRole;
    final String currentUserId = userProfile.uid;

    // Build the query
    Query query = FirebaseFirestore.instance.collection('notifications');
    if (isTeacher) {
      query = query.where('teacherName', isEqualTo: userProfile.name);
    } else {
      query = query.where('groupId', isEqualTo: userProfile.groupId ?? '');
    }
    // We order by createdAt descending (newest first)
    query = query.orderBy('createdAt', descending: true);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Сповіщення'),
        centerTitle: true,
        actions: [
          if (!isTeacher)
            StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const SizedBox.shrink();
                }

                // Check if there are any unread notifications
                final unreadDocs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>? ?? {};
                  final isReadBy = data['isReadBy'] as Map<String, dynamic>? ?? {};
                  return isReadBy[currentUserId] != true;
                }).toList();

                if (unreadDocs.isEmpty) return const SizedBox.shrink();

                return IconButton(
                  icon: const Icon(Icons.mark_chat_read_outlined),
                  tooltip: 'Позначити всі як прочитані',
                  onPressed: () async {
                    final batch = FirebaseFirestore.instance.batch();
                    for (final doc in unreadDocs) {
                      batch.update(doc.reference, {
                        'isReadBy.$currentUserId': true,
                      });
                    }
                    await batch.commit();
                  },
                );
              },
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'Помилка: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_outlined,
                    size: 64,
                    color: colorScheme.outline.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Немає нових сповіщень',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>? ?? {};
              final subjectName = data['subjectName'] ?? 'Предмет';
              final teacherName = data['teacherName'] ?? 'Викладач';
              final oldDateText = data['oldDateText'] ?? '';
              final newDateText = data['newDateText'] ?? '';
              final groupId = data['groupId'] ?? '';
              final timestamp = data['createdAt'] as Timestamp?;
              final isReadBy = data['isReadBy'] as Map<String, dynamic>? ?? {};
              final isUnread = !isTeacher && isReadBy[currentUserId] != true;

              final String formattedTime = timestamp != null
                  ? DateFormat('dd.MM.yyyy HH:mm').format(timestamp.toDate())
                  : '';

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: isUnread
                      ? () async {
                          await doc.reference.update({
                            'isReadBy.$currentUserId': true,
                          });
                        }
                      : null,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isUnread
                          ? colorScheme.primary.withValues(alpha: 0.05)
                          : colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isUnread
                            ? colorScheme.primary.withValues(alpha: 0.3)
                            : colorScheme.outlineVariant,
                        width: isUnread ? 1.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon / Badge
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isUnread
                                ? colorScheme.primary.withValues(alpha: 0.1)
                                : colorScheme.surfaceContainerHighest,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.swap_horiz,
                            color: isUnread ? colorScheme.primary : colorScheme.outline,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Notification details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      subjectName,
                                      style: textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  if (isUnread)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isTeacher
                                    ? 'Ви перенесли пару для групи $groupId'
                                    : 'Викладач: $teacherName',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(Icons.history, size: 14, color: colorScheme.outline),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Було: $oldDateText',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: colorScheme.outline,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.event_available, size: 14, color: colorScheme.primary),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Стало: $newDateText',
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Text(
                                  formattedTime,
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colorScheme.outline,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
