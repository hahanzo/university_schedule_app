import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/injection.dart';
import '../../../../data/models/user_profile.dart';
import '../../../../domain/repositories/schedule_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../models/chat_room_info.dart';
import 'chat_screen.dart';

class ChatRoomsScreen extends StatefulWidget {
  final UserProfile userProfile;

  const ChatRoomsScreen({super.key, required this.userProfile});

  @override
  State<ChatRoomsScreen> createState() => _ChatRoomsScreenState();
}

class _ChatRoomsScreenState extends State<ChatRoomsScreen> {
  final ScheduleRepository _scheduleRepository = getIt<ScheduleRepository>();
  final FirebaseFirestore _firestore = getIt<FirebaseFirestore>();

  bool _isLoading = true;
  String? _errorCode;
  List<String> _groupIds = [];

  bool get _isTeacher => widget.userProfile.role == AppConstants.teacherRole;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  @override
  void didUpdateWidget(covariant ChatRoomsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userProfile.role != widget.userProfile.role ||
        oldWidget.userProfile.groupId != widget.userProfile.groupId ||
        oldWidget.userProfile.teacherId != widget.userProfile.teacherId) {
      _loadRooms();
    }
  }

  Future<void> _loadRooms() async {
    setState(() {
      _isLoading = true;
      _errorCode = null;
    });

    try {
      if (_isTeacher) {
        final teacherId = widget.userProfile.teacherId?.trim() ?? '';
        if (teacherId.isEmpty) {
          _errorCode = 'missing_teacher';
          _groupIds = [];
        } else {
          _groupIds = await _scheduleRepository.getGroupsForTeacher(teacherId);
        }
      } else {
        final groupId = widget.userProfile.groupId?.trim() ?? '';
        if (groupId.isEmpty) {
          _errorCode = 'missing_group';
          _groupIds = [];
        } else {
          _groupIds = [groupId];
        }
      }
    } catch (e) {
      _errorCode = 'load_error';
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  List<ChatRoomInfo> _buildRooms(AppLocalizations l10n) {
    final seen = <String>{};
    final rooms = <ChatRoomInfo>[];
    for (final groupId in _groupIds) {
      final baseGroup = _groupPrefix(groupId);
      if (seen.contains(baseGroup)) continue;
      seen.add(baseGroup);
      rooms.add(
        ChatRoomInfo(
          id: 'group_$baseGroup',
          label: '${l10n.group}: $baseGroup',
          type: 'group',
        ),
      );
    }
    return rooms;
  }

  String _groupPrefix(String groupId) {
    final parts = groupId.trim().split('-');
    if (parts.length >= 2) {
      return '${parts[0]}-${parts[1]}';
    }
    return groupId.trim();
  }

  int _compareRooms(
    ChatRoomInfo a,
    ChatRoomInfo b,
    Map<String, Map<String, dynamic>> roomMeta,
  ) {
    final aMeta = roomMeta[a.id];
    final bMeta = roomMeta[b.id];
    final aTime = aMeta?['updatedAt'] as Timestamp?;
    final bTime = bMeta?['updatedAt'] as Timestamp?;
    if (aTime != null && bTime != null) {
      return bTime.compareTo(aTime);
    }
    if (aTime != null) return -1;
    if (bTime != null) return 1;
    return a.label.compareTo(b.label);
  }

  String _errorMessage(AppLocalizations l10n) {
    switch (_errorCode) {
      case 'missing_teacher':
        return l10n.selectTeacher;
      case 'missing_group':
        return l10n.selectGroup;
      default:
        return l10n.chatLoadError;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rooms = _buildRooms(l10n);
    final roomQuery = _firestore
        .collection('chat_rooms')
        .where('roomType', isEqualTo: 'group');

    return Scaffold(
      appBar: AppBar(title: Text(l10n.chat), centerTitle: true),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadRooms,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorCode != null
                  ? ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          _errorMessage(l10n),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _loadRooms,
                          child: Text(l10n.retry),
                        ),
                      ],
                    )
                  : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: roomQuery.snapshots(),
                      builder: (context, snapshot) {
                        final roomDocs = snapshot.data?.docs ?? [];
                        final roomMeta = <String, Map<String, dynamic>>{};
                        for (final doc in roomDocs) {
                          roomMeta[doc.id] = doc.data();
                        }

                        if (rooms.isEmpty) {
                          return ListView(
                            children: [
                              const SizedBox(height: 120),
                              Center(child: Text(l10n.noChats)),
                            ],
                          );
                        }

                        rooms.sort(
                          (a, b) => _compareRooms(a, b, roomMeta),
                        );

                        return ListView.separated(
                          itemCount: rooms.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final room = rooms[index];
                            final meta = roomMeta[room.id];
                            return _RoomTile(
                              room: room,
                              roomMeta: meta,
                              userProfile: widget.userProfile,
                            );
                          },
                        );
                      },
                    ),
        ),
      ),
    );
  }
}

class _RoomTile extends StatelessWidget {
  final ChatRoomInfo room;
  final Map<String, dynamic>? roomMeta;
  final UserProfile userProfile;

  const _RoomTile({
    required this.room,
    required this.roomMeta,
    required this.userProfile,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lastMessage = (roomMeta?['lastMessage'] ?? '').toString();
    final subtitle = lastMessage.isEmpty ? l10n.noMessages : lastMessage;

    return ListTile(
      title: Text(room.label),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: const Icon(Icons.forum),
      ),
      trailing: _UnreadBadge(
        roomId: room.id,
        roomMeta: roomMeta,
        currentUserId: userProfile.uid,
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            userProfile: userProfile,
            room: room,
          ),
        ),
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  final String roomId;
  final Map<String, dynamic>? roomMeta;
  final String currentUserId;

  const _UnreadBadge({
    required this.roomId,
    required this.roomMeta,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lastMessage = (roomMeta?['lastMessage'] ?? '').toString();
    if (lastMessage.trim().isEmpty) {
      return const Icon(Icons.chevron_right);
    }

    final readMap = (roomMeta?['lastReadAt'] as Map?) ?? {};
    final readAt = readMap[currentUserId] as Timestamp?;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _unreadMessagesStream(roomId, readAt),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Icon(Icons.chevron_right);
        }

        final docs = snapshot.data!.docs;
        var unreadCount = 0;
        for (final doc in docs) {
          final data = doc.data();
          final senderId = (data['senderId'] ?? '').toString();
          if (senderId != currentUserId) {
            unreadCount += 1;
          }
        }

        if (unreadCount == 0) {
          return const Icon(Icons.chevron_right);
        }

        final displayCount = unreadCount > 99 ? '99+' : unreadCount.toString();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            displayCount,
            style: TextStyle(
              color: theme.colorScheme.onPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      },
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _unreadMessagesStream(
    String? roomId,
    Timestamp? readAt,
  ) {
    final firestore = FirebaseFirestore.instance;
    final roomRef = roomId == null
        ? null
        : firestore.collection('chat_rooms').doc(roomId).collection('messages');
    if (roomRef == null) {
      return const Stream.empty();
    }

    if (readAt != null) {
      return roomRef
          .where('createdAt', isGreaterThan: readAt)
          .orderBy('createdAt', descending: true)
          .limit(200)
          .snapshots();
    }

    return roomRef
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots();
  }
}
