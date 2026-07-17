/// Message model for real-time chat
import 'package:supabase_flutter/supabase_flutter.dart';

enum MessageType { text, image, voice, location, system }

class Message {
  final String id;
  final String albumId;
  final String userId;
  final String content;
  final MessageType type;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Message({
    required this.id,
    required this.albumId,
    required this.userId,
    required this.content,
    required this.type,
    required this.metadata,
    required this.createdAt,
    this.updatedAt,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] as String,
      albumId: map['album_id'] as String,
      userId: map['user_id'] as String,
      content: map['content'] as String,
      type: MessageType.values.byName(map['type'] as String),
      metadata: (map['metadata'] as Map<String, dynamic>?) ?? {},
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'album_id': albumId,
      'user_id': userId,
      'content': content,
      'type': type.name,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Message copyWith({
    String? id,
    String? albumId,
    String? userId,
    String? content,
    MessageType? type,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Message(
      id: id ?? this.id,
      albumId: albumId ?? this.albumId,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      type: type ?? this.type,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper getters for system messages
  bool get isSystem => type == MessageType.system;
  String? get systemEvent => metadata['event'] as String?;
  String? get targetUserId => metadata['target_user_id'] as String?;
  String? get targetUserEmail => metadata['target_user_email'] as String?;

  // For display
  String get displayTime {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}