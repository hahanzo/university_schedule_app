import 'package:flutter/foundation.dart';

@immutable
class ChatRoomInfo {
  final String id;
  final String label;
  final String type;

  const ChatRoomInfo({
    required this.id,
    required this.label,
    required this.type,
  });
}
