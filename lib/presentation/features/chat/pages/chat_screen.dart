import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/string_extensions.dart';
import '../../../../data/models/user_profile.dart';
import '../../../../l10n/app_localizations.dart';
import '../models/chat_room_info.dart';
import 'group_members_screen.dart';
import 'profile_view_screen.dart';

class ChatScreen extends StatefulWidget {
  final UserProfile userProfile;
  final ChatRoomInfo room;

  const ChatScreen({super.key, required this.userProfile, required this.room});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isSending = false;
  bool _isAtBottom = true;
  final Set<String> _pendingReceipts = {};
  final Set<String> _receiptsToUpdate = {};
  Timer? _receiptsTimer;
  Timer? _typingTimer;
  DateTime? _lastReadUpdate;
  bool _isMarkingRead = false;
  bool _hasMarkedReadOnOpen = false;

  DocumentReference<Map<String, dynamic>>? get _roomRef {
    return _firestore.collection('chat_rooms').doc(widget.room.id);
  }

  CollectionReference<Map<String, dynamic>>? get _messagesRef {
    final room = _roomRef;
    if (room == null) return null;
    return room.collection('messages');
  }

  CollectionReference<Map<String, dynamic>>? get _typingRef {
    final room = _roomRef;
    if (room == null) return null;
    return room.collection('typing');
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _messageController.addListener(_handleTyping);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _markRoomRead(force: true),
    );
  }

  @override
  void dispose() {
    _receiptsTimer?.cancel();
    _flushPendingReceipts();
    _setTyping(false);
    _typingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final isAtBottom = _scrollController.offset <= 60;
    if (_isAtBottom != isAtBottom) {
      _isAtBottom = isAtBottom;
    }
  }

  Future<void> _markRoomRead({bool force = false}) async {
    final roomRef = _roomRef;
    if (roomRef == null) return;
    if (_isMarkingRead) return;

    final now = DateTime.now();
    if (!force &&
        _lastReadUpdate != null &&
        now.difference(_lastReadUpdate!) < const Duration(seconds: 2)) {
      return;
    }

    _isMarkingRead = true;
    try {
      await roomRef.update({
        'roomType': widget.room.type,
        'roomLabel': widget.room.label,
        'lastReadAt.${widget.userProfile.uid}': FieldValue.serverTimestamp(),
      });
      _lastReadUpdate = now;
    } catch (_) {
      // Fallback if the room document doesn't exist yet
      try {
        await roomRef.set({
          'roomType': widget.room.type,
          'roomLabel': widget.room.label,
          'lastReadAt': {
            widget.userProfile.uid: FieldValue.serverTimestamp(),
          }
        }, SetOptions(merge: true));
        _lastReadUpdate = now;
      } catch (__) {}
    } finally {
      _isMarkingRead = false;
    }
  }

  void _handleTyping() {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      _setTyping(false);
      return;
    }

    _setTyping(true);
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () => _setTyping(false));
  }

  Future<void> _setTyping(bool isTyping) async {
    final typingRef = _typingRef;
    if (typingRef == null) return;
    try {
      await typingRef.doc(widget.userProfile.uid).set({
        'isTyping': isTyping,
        'uid': widget.userProfile.uid,
        'name': widget.userProfile.name,
        'role': widget.userProfile.role,
        'avatarUrl': widget.userProfile.avatarUrl ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) {
      return;
    }

    setState(() => _isSending = true);
    _messageController.clear();
    await _setTyping(false);

    final messagesRef = _messagesRef;
    final roomRef = _roomRef;
    if (messagesRef == null || roomRef == null) {
      if (mounted) {
        setState(() => _isSending = false);
      }
      return;
    }

    try {
      await messagesRef.add({
        'text': text,
        'senderId': widget.userProfile.uid,
        'senderName': widget.userProfile.name,
        'senderRole': widget.userProfile.role,
        'senderAvatarUrl': widget.userProfile.avatarUrl ?? '',
        'deliveredTo': {widget.userProfile.uid: true},
        'readBy': {widget.userProfile.uid: true},
        'createdAt': FieldValue.serverTimestamp(),
      });

      await roomRef.set({
        'roomType': widget.room.type,
        'roomLabel': widget.room.label,
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessage': text,
        'lastSenderId': widget.userProfile.uid,
      }, SetOptions(merge: true));

      await _markRoomRead(force: true);
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }

    if (mounted) {
      setState(() => _isSending = false);
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) {
      return '';
    }
    return DateFormat('HH:mm').format(timestamp.toDate());
  }

  String _roleLabel(String role, AppLocalizations l10n) {
    return role == AppConstants.teacherRole ? l10n.teacher : l10n.students;
  }

  void _markMessageAsRead(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final uid = widget.userProfile.uid;
    final data = doc.data();
    final senderId = (data['senderId'] ?? '').toString();
    if (senderId.isEmpty || senderId == uid) return;

    final readBy = (data['readBy'] as Map?) ?? {};
    final read = readBy[uid] == true;

    if (read) return;
    if (_pendingReceipts.contains(doc.id)) return;

    _pendingReceipts.add(doc.id);
    _receiptsToUpdate.add(doc.id);

    _scheduleBatchReceiptsUpdate();
  }

  void _scheduleBatchReceiptsUpdate() {
    _receiptsTimer?.cancel();
    _receiptsTimer = Timer(const Duration(milliseconds: 500), () {
      _flushPendingReceipts();
    });
  }

  void _flushPendingReceipts() async {
    if (_receiptsToUpdate.isEmpty) return;

    final toUpdate = Set<String>.from(_receiptsToUpdate);
    _receiptsToUpdate.clear();

    final uid = widget.userProfile.uid;
    final batch = _firestore.batch();
    final messagesRef = _messagesRef;
    if (messagesRef == null) return;

    for (final docId in toUpdate) {
      final docRef = messagesRef.doc(docId);
      batch.update(docRef, {
        'deliveredTo.$uid': true,
        'readBy.$uid': true,
      });
    }

    try {
      await batch.commit();
      await _markRoomRead(force: true);
    } catch (_) {}
  }

  String _statusLabel(Map<String, dynamic> data, AppLocalizations l10n) {
    final uid = widget.userProfile.uid;
    final deliveredTo = (data['deliveredTo'] as Map?) ?? {};
    final readBy = (data['readBy'] as Map?) ?? {};
    final deliveredCount = deliveredTo.keys
        .where((key) => key.toString() != uid)
        .length;
    final readCount = readBy.keys.where((key) => key.toString() != uid).length;

    if (readCount > 0) return l10n.read;
    if (deliveredCount > 0) return l10n.delivered;
    return l10n.sent;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final messagesRef = _messagesRef;
    final typingRef = _typingRef;

    // Extract group ID from room ID (format: 'group_XX-YY')
    final isGroupChat = widget.room.type == 'group';
    final groupId = isGroupChat && widget.room.id.startsWith('group_')
        ? widget.room.id.replaceFirst('group_', '')
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.room.label),
        centerTitle: true,
        actions: [
          if (isGroupChat && groupId != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: IconButton(
                icon: const Icon(Icons.people),
                tooltip: l10n.students,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => GroupMembersScreen(groupId: groupId),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: messagesRef
                  ?.orderBy('createdAt', descending: true)
                  .limit(200)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text(snapshot.error.toString()));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!_hasMarkedReadOnOpen) {
                  _hasMarkedReadOnOpen = true;
                  _markRoomRead(force: true);
                }

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return Center(child: Text(l10n.noMessages));
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    _markMessageAsRead(doc);
                    final data = doc.data();
                    final text = (data['text'] ?? '').toString();
                    final senderId = (data['senderId'] ?? '').toString();
                    final senderName = (data['senderName'] ?? '').toString();
                    final senderRole = (data['senderRole'] ?? '').toString();
                    final senderAvatarUrl = (data['senderAvatarUrl'] ?? '')
                        .toString();
                    final timestamp = data['createdAt'] as Timestamp?;
                    final isMe = senderId == widget.userProfile.uid;
                    final statusLabel = isMe ? _statusLabel(data, l10n) : null;

                    return _MessageBubble(
                      message: text,
                      senderName: senderName,
                      senderId: senderId,
                      senderRole: _roleLabel(senderRole, l10n),
                      senderAvatarUrl: senderAvatarUrl,
                      timeLabel: _formatTimestamp(timestamp),
                      isMe: isMe,
                      statusLabel: statusLabel,
                    );
                  },
                );
              },
            ),
          ),
          _TypingIndicator(
            typingRef: typingRef,
            currentUserId: widget.userProfile.uid,
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: l10n.messageHint,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _isSending ? null : _sendMessage,
                    icon: const Icon(Icons.send),
                    tooltip: l10n.send,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String message;
  final String senderName;
  final String senderId;
  final String senderRole;
  final String senderAvatarUrl;
  final String timeLabel;
  final bool isMe;
  final String? statusLabel;

  const _MessageBubble({
    required this.message,
    required this.senderName,
    required this.senderId,
    required this.senderRole,
    required this.senderAvatarUrl,
    required this.timeLabel,
    required this.isMe,
    this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alignment = isMe ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = isMe
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;
    final textColor = isMe
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;


    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: isMe
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isMe) ...[
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProfileViewScreen(
                        userId: senderId,
                        initialName: senderName,
                        initialAvatarUrl: senderAvatarUrl,
                      ),
                    ),
                  );
                },
                child: _UserAvatar(
                  avatarUrl: senderAvatarUrl,
                  name: senderName,
                  radius: 16,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.65,
              ),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (!isMe) ...[
                    Text(
                      senderName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    message,
                    style: TextStyle(color: textColor, fontSize: 14),
                  ),
                  if (timeLabel.isNotEmpty ||
                      (!isMe && senderRole.isNotEmpty)) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: isMe
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      children: [
                        if (!isMe && senderRole.isNotEmpty) ...[
                          Text(
                            senderRole,
                            style: TextStyle(
                              fontSize: 10,
                              color: textColor.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                        if (!isMe &&
                            senderRole.isNotEmpty &&
                            timeLabel.isNotEmpty)
                          const SizedBox(width: 8),
                        if (timeLabel.isNotEmpty) ...[
                          Text(
                            timeLabel,
                            style: TextStyle(
                              fontSize: 10,
                              color: textColor.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                        if (isMe && statusLabel != null && timeLabel.isNotEmpty)
                          const SizedBox(width: 8),
                        if (isMe && statusLabel != null) ...[
                          Text(
                            statusLabel!,
                            style: TextStyle(
                              fontSize: 10,
                              color: textColor.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  final CollectionReference<Map<String, dynamic>>? typingRef;
  final String currentUserId;

  const _TypingIndicator({
    required this.typingRef,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    if (typingRef == null) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: typingRef!.where('isTyping', isEqualTo: true).snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final now = DateTime.now();
        final entries = docs
            .where((doc) {
              final data = doc.data();
              final uid = (data['uid'] ?? doc.id).toString();
              if (uid == currentUserId) return false;
              final ts = data['updatedAt'] as Timestamp?;
              if (ts == null) return true;
              final diff = now.difference(ts.toDate());
              return diff.inSeconds <= 6;
            })
            .map((doc) {
              final data = doc.data();
              return _TypingUser(
                name: (data['name'] ?? '').toString().trim(),
                role: (data['role'] ?? '').toString().trim(),
                avatarUrl: (data['avatarUrl'] ?? '').toString().trim(),
              );
            })
            .where((entry) => entry.name.isNotEmpty)
            .toList();

        if (entries.isEmpty) {
          return const SizedBox.shrink();
        }

        entries.sort((a, b) => a.name.compareTo(b.name));
        final label = l10n.typing;

        return Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                ...entries.map((entry) {
                  final roleLabel = entry.role == AppConstants.teacherRole
                      ? l10n.teachers
                      : l10n.students;
                  return _TypingChip(
                    name: entry.name,
                    roleLabel: roleLabel,
                    avatarUrl: entry.avatarUrl,
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TypingUser {
  final String name;
  final String role;
  final String avatarUrl;

  const _TypingUser({
    required this.name,
    required this.role,
    required this.avatarUrl,
  });
}

class _TypingChip extends StatelessWidget {
  final String name;
  final String roleLabel;
  final String avatarUrl;

  const _TypingChip({
    required this.name,
    required this.roleLabel,
    required this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _UserAvatar(
            avatarUrl: avatarUrl,
            name: name,
            radius: 10,
            textStyle: TextStyle(
              fontSize: 8,
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$name ($roleLabel)',
            style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface),
          ),
        ],
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
