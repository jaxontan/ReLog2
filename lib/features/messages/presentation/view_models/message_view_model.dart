import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';
import '../../../../features/auth/presentation/view_models/auth_view_model.dart';
import '../../data/repositories/message_repository.dart';
import '../../data/models/message.dart';

final messageRepositoryProvider = Provider<MessageRepository>((_) => MessageRepository());

// Stream of messages for an album (real-time)
final albumMessagesProvider = StreamProvider.autoDispose.family<List<Message>, String>(
  (ref, albumId) {
    final repo = ref.watch(messageRepositoryProvider);
    return repo.messagesStream(albumId, limit: 100);
  },
);

// Send message action
final sendMessageAction = Provider.autoDispose<
    Future<(Message?, Failure?)> Function({
  required String albumId,
  required String content,
  MessageType type,
  Map<String, dynamic> metadata,
})>((ref) {
  return ({
    required String albumId,
    required String content,
    MessageType type = MessageType.text,
    Map<String, dynamic> metadata = const {},
  }) async {
    final repo = ref.read(messageRepositoryProvider);
    final userId = ref.read(authServiceProvider).currentUser?.id;
    if (userId == null) return (null, AuthFailure('Not authenticated'));
    return repo.sendMessage(
      albumId: albumId,
      userId: userId,
      content: content,
      type: type,
      metadata: metadata,
    );
  };
});

// System message action (for events)
final sendSystemMessageAction = Provider.autoDispose<
    Future<void> Function({
  required String albumId,
  required String event,
  String? targetUserId,
  String? targetUserEmail,
  Map<String, dynamic> metadata,
})>((ref) {
  return ({
    required String albumId,
    required String event,
    String? targetUserId,
    String? targetUserEmail,
    Map<String, dynamic> metadata = const {},
  }) async {
    final repo = ref.read(messageRepositoryProvider);
    await repo.sendSystemMessage(
      albumId: albumId,
      event: event,
      targetUserId: targetUserId,
      targetUserEmail: targetUserEmail,
      additionalMetadata: metadata,
    );
  };
});

// Pagination state for loading older messages
class MessagesPaginationState {
  final bool isLoadingMore;
  final DateTime? oldestLoaded;
  final bool hasMore;

  const MessagesPaginationState({
    this.isLoadingMore = false,
    this.oldestLoaded,
    this.hasMore = true,
  });

  MessagesPaginationState copyWith({
    bool? isLoadingMore,
    DateTime? oldestLoaded,
    bool? hasMore,
  }) {
    return MessagesPaginationState(
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      oldestLoaded: oldestLoaded ?? this.oldestLoaded,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

final messagesPaginationProvider =
    StateNotifierProvider.autoDispose.family<MessagesPaginationNotifier, MessagesPaginationState, String>(
  (ref, albumId) => MessagesPaginationNotifier(ref, albumId),
);

class MessagesPaginationNotifier extends StateNotifier<MessagesPaginationState> {
  final Ref ref;
  final String albumId;
  final MessageRepository _repo;

  MessagesPaginationNotifier(this.ref, this.albumId)
      : _repo = ref.read(messageRepositoryProvider),
        super(const MessagesPaginationState());

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final messages = await _repo.getMessages(
        albumId,
        limit: 30,
        before: state.oldestLoaded,
      );
      if (messages.isEmpty) {
        state = state.copyWith(isLoadingMore: false, hasMore: false);
      } else {
        state = state.copyWith(
          isLoadingMore: false,
          oldestLoaded: messages.last.createdAt,
          hasMore: messages.length >= 30,
        );
      }
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }
}