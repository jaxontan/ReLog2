import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';

/// Service for sending push notifications via Supabase Edge Function
final notificationSenderProvider = Provider<NotificationSender>((ref) => NotificationSender());

class NotificationSender {
  final SupabaseClient _client = Supabase.instance.client;

  /// Send chat notification to album members (excluding sender)
  Future<Failure?> sendChatNotification({
    required String albumId,
    required String senderId,
    required String senderName,
    required String message,
    String? messageId,
  }) async {
    return _sendNotification(
      type: 'chat',
      title: 'New message from $senderName',
      body: message.length > 100 ? '${message.substring(0, 100)}...' : message,
      albumId: albumId,
      messageId: messageId,
      excludeUserId: senderId,
    );
  }

  /// Send memory notification to album members
  Future<Failure?> sendMemoryNotification({
    required String albumId,
    required String memoryId,
    required String creatorName,
    required String type, // 'photo', 'video', 'voice', 'note'
    String? notePhase,
  }) async {
    String title = 'New memory in your journal';
    String body = '$creatorName added a $type';
    if (notePhase != null) body += ' ($notePhase)';

    return _sendNotification(
      type: 'memory',
      title: title,
      body: body,
      albumId: albumId,
      memoryId: memoryId,
    );
  }

  /// Send system notification (trip ended, member joined, etc.)
  Future<Failure?> sendSystemNotification({
    required String albumId,
    required String title,
    required String body,
    String? excludeUserId,
  }) async {
    return _sendNotification(
      type: 'system',
      title: title,
      body: body,
      albumId: albumId,
      excludeUserId: excludeUserId,
    );
  }

  /// Internal method to call the edge function
  Future<Failure?> _sendNotification({
    required String type,
    required String title,
    required String body,
    String? albumId,
    String? memoryId,
    String? messageId,
    String? excludeUserId,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'send-notification',
        body: {
          'type': type,
          'title': title,
          'body': body,
          'album_id': albumId,
          'memory_id': memoryId,
          'message_id': messageId,
          'exclude_user_id': excludeUserId,
        },
      );

      if (response.data['success'] == true) {
        return null;
      }

      return NotificationFailure(response.data['error']?.toString() ?? 'Failed to send notification');
    } catch (e) {
      return NotificationFailure('Failed to send notification: $e');
    }
  }
}