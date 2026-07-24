/// Chat message bubble widget
library messages.widgets.message_bubble;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../app/design/design_system.dart';
import '../../../../features/auth/presentation/view_models/auth_view_model.dart';
import '../../data/models/message.dart';

class MessageBubble extends ConsumerWidget {
  final Message message;
  final bool isOwn;
  final String? senderName;
  final String? senderAvatar;
  final bool showAvatar;
  final bool showTime;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isOwn,
    this.senderName,
    this.senderAvatar,
    this.showAvatar = true,
    this.showTime = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final currentUser = ref.watch(authServiceProvider).currentUser;

    final isSystem = message.isSystem;

    if (isSystem) {
      return _SystemMessageBubble(message: message);
    }

    final isCurrentUser = currentUser?.id == message.userId;
    final showName = !isOwn && !isCurrentUser;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DSSpacing.md, vertical: DSSpacing.xs),
      child: Row(
        mainAxisAlignment: isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isOwn && showAvatar) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              backgroundImage: senderAvatar != null ? NetworkImage(senderAvatar!) : null,
              child: senderAvatar == null
                  ? Text(
                      senderName?.isNotEmpty == true
                          ? senderName![0].toUpperCase()
                          : '?',
                      style: DSTypography.labelMedium.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: DSSpacing.sm),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (showName && senderName != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 2),
                    child: Text(
                      senderName!,
                      style: DSTypography.labelSmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  decoration: BoxDecoration(
                    color: isOwn
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(DSRadius.lg),
                      topRight: const Radius.circular(DSRadius.lg),
                      bottomLeft: isOwn ? const Radius.circular(DSRadius.lg) : Radius.zero,
                      bottomRight: isOwn ? Radius.zero : const Radius.circular(DSRadius.lg),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: DSSpacing.md,
                    vertical: DSSpacing.sm,
                  ),
                  child: _buildMessageContent(context, isOwn),
                ),
                if (showTime)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 12,
                      right: 12,
                      top: 2,
                    ),
                    child: Text(
                      message.displayTime,
                      style: DSTypography.labelSmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (isOwn && showAvatar) ...[
            const SizedBox(width: DSSpacing.sm),
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: currentUser?.email != null
                  ? Text(
                      currentUser!.email![0].toUpperCase(),
                      style: DSTypography.labelMedium.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : const Icon(Icons.person, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context, bool isOwn) {
    final scheme = Theme.of(context).colorScheme;

    switch (message.type) {
      case MessageType.image:
        if (message.metadata['url'] != null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(DSRadius.md),
                child: Image.network(
                  message.metadata['url'] as String,
                  width: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 150,
                    color: scheme.surfaceContainerHighest,
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
              if (message.content.isNotEmpty) ...[
                const SizedBox(height: DSSpacing.xs),
                Text(
                  message.content,
                  style: DSTypography.bodyMedium.copyWith(
                    color: isOwn ? scheme.onPrimary : scheme.onSurface,
                  ),
                ),
              ],
            ],
          );
        }
        return const SizedBox.shrink();

      case MessageType.voice:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.mic,
              color: isOwn ? scheme.onPrimary : scheme.primary,
              size: 20,
            ),
            const SizedBox(width: DSSpacing.sm),
            Text(
              message.metadata['duration'] != null
                  ? '${(message.metadata['duration'] as num).toInt()}s'
                  : 'Voice message',
              style: DSTypography.bodyMedium.copyWith(
                color: isOwn ? scheme.onPrimary : scheme.onSurface,
              ),
            ),
          ],
        );

      case MessageType.location:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on,
              color: isOwn ? scheme.onPrimary : scheme.secondary,
              size: 20,
            ),
            const SizedBox(width: DSSpacing.sm),
            Text(
              'Location shared',
              style: DSTypography.bodyMedium.copyWith(
                color: isOwn ? scheme.onPrimary : scheme.onSurface,
              ),
            ),
          ],
        );

      case MessageType.system:
        return _SystemMessageBubble(message: message);

      case MessageType.text:
      default:
        return Text(
          message.content,
          style: DSTypography.bodyMedium.copyWith(
            color: isOwn ? scheme.onPrimary : scheme.onSurface,
            height: 1.4,
          ),
        );
    }
  }
}

class _SystemMessageBubble extends StatelessWidget {
  final Message message;

  const _SystemMessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: DSSpacing.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: DSSpacing.md,
          vertical: DSSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(DSRadius.full),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getSystemIcon(message.systemEvent),
              size: 14,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: DSSpacing.xs),
            Text(
              message.content,
              style: DSTypography.bodySmall.copyWith(
                color: scheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getSystemIcon(String? event) {
    switch (event) {
      case 'member_joined':
        return Icons.person_add;
      case 'member_left':
        return Icons.logout;
      case 'trip_ended':
        return Icons.flag;
      case 'confession_unlocked':
        return Icons.lock_open;
      default:
        return Icons.info_outline;
    }
  }
}