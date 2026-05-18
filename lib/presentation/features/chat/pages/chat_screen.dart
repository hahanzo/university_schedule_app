import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../data/models/user_profile.dart';
import '../../../../l10n/app_localizations.dart';
import '../models/chat_room_info.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _markRoomRead(force: true));
  }

  @override
  void dispose() {
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
      await roomRef.set({
        'lastReadAt.${widget.userProfile.uid}': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      _lastReadUpdate = now;
    } catch (_) {
      // Ignore read update errors.
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

  void _scheduleReceiptsUpdate(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    if (_messagesRef == null) return;
    if (docs.isEmpty) return;
    final uid = widget.userProfile.uid;
    final toUpdate = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

    for (final doc in docs.take(60)) {
      if (_pendingReceipts.contains(doc.id)) continue;
      final data = doc.data();
      final senderId = (data['senderId'] ?? '').toString();
      if (senderId.isEmpty || senderId == uid) continue;

      final deliveredTo = (data['deliveredTo'] as Map?) ?? {};
      final readBy = (data['readBy'] as Map?) ?? {};
      final delivered = deliveredTo[uid] == true;
      final read = readBy[uid] == true;
      if (delivered && read) continue;

      _pendingReceipts.add(doc.id);
      toUpdate.add(doc);
    }

    if (toUpdate.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final batch = _firestore.batch();
      for (final doc in toUpdate) {
        final updates = <String, dynamic>{
          'deliveredTo.$uid': true,
          'readBy.$uid': true,
        };
        batch.set(doc.reference, updates, SetOptions(merge: true));
      }
      try {
        await batch.commit();
        await _markRoomRead(force: true);
      } catch (_) {}
      if (mounted) {
        for (final doc in toUpdate) {
          _pendingReceipts.remove(doc.id);
        }
      }
    });
  }

  String _statusLabel(
    Map<String, dynamic> data,
    AppLocalizations l10n,
  ) {
    final uid = widget.userProfile.uid;
    final deliveredTo = (data['deliveredTo'] as Map?) ?? {};
    final readBy = (data['readBy'] as Map?) ?? {};
    final deliveredCount = deliveredTo.keys
        .where((key) => key.toString() != uid)
        .length;
    final readCount =
        readBy.keys.where((key) => key.toString() != uid).length;

    if (readCount > 0) return l10n.read;
    if (deliveredCount > 0) return l10n.delivered;
    return l10n.sent;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final messagesRef = _messagesRef;
    final typingRef = _typingRef;

    return Scaffold(
      appBar: AppBar(title: Text(widget.room.label), centerTitle: true),
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
                  return Center(
                    child: Text(snapshot.error.toString()),
                  );
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

                _scheduleReceiptsUpdate(docs);

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final text = (data['text'] ?? '').toString();
                    final senderId = (data['senderId'] ?? '').toString();
                    final senderName = (data['senderName'] ?? '').toString();
                    final senderRole = (data['senderRole'] ?? '').toString();
                    final timestamp = data['createdAt'] as Timestamp?;
                    final isMe = senderId == widget.userProfile.uid;
                    final statusLabel =
                        isMe ? _statusLabel(data, l10n) : null;

                    return _MessageBubble(
                      message: text,
                      senderName: senderName,
                      senderRole: _roleLabel(senderRole, l10n),
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
  final String senderRole;
  final String timeLabel;
  final bool isMe;
  final String? statusLabel;

  const _MessageBubble({
    required this.message,
    required this.senderName,
    required this.senderRole,
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
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
            if (timeLabel.isNotEmpty || (!isMe && senderRole.isNotEmpty)) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment:
                    isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
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
                  if (!isMe && senderRole.isNotEmpty && timeLabel.isNotEmpty)
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
        final entries = docs.where((doc) {
          final data = doc.data();
          final uid = (data['uid'] ?? doc.id).toString();
          if (uid == currentUserId) return false;
          final ts = data['updatedAt'] as Timestamp?;
          if (ts == null) return true;
          final diff = now.difference(ts.toDate());
          return diff.inSeconds <= 6;
        }).map((doc) {
          final data = doc.data();
          return _TypingUser(
            name: (data['name'] ?? '').toString().trim(),
            role: (data['role'] ?? '').toString().trim(),
            avatarUrl: (data['avatarUrl'] ?? '').toString().trim(),
          );
        }).where((entry) => entry.name.isNotEmpty).toList();

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
    final initials = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
    final imageProvider = avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: theme.colorScheme.primaryContainer,
            backgroundImage: imageProvider,
            child: imageProvider == null
                ? Text(
                    initials,
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 6),
          Text(
            '$name ($roleLabel)',
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}