/// Real-time chat screen for an album
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:record/record.dart';
import 'package:intl/intl.dart';
import '../../../../app/design/design_system.dart';
import '../widgets/message_bubble.dart';
import '../view_models/message_view_model.dart';
import '../../data/models/message.dart';
import '../../../../features/auth/presentation/view_models/auth_view_model.dart';
import '../../../../features/albums/presentation/view_models/album_view_model.dart';
import '../../../../features/memories/data/repositories/memory_repository.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String albumId;
  final String albumTitle;

  const ChatScreen({
    super.key,
    required this.albumId,
    required this.albumTitle,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _recorder = AudioRecorder();
  bool _showEmojiPicker = false;
  bool _isRecording = false;
  bool _isSendingVoice = false;
  bool _isMuted = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: DSAnimation.fast,
        curve: DSAnimation.decelerate,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    _scrollToBottom();

    final action = ref.read(sendMessageAction);
    final (_, error) = await action(
      albumId: widget.albumId,
      content: text,
    );

    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _startVoiceRecording() async {
    if (await _recorder.hasPermission()) {
      setState(() => _isRecording = true);
      final path = '${Directory.systemTemp.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
    }
  }

  Future<void> _stopVoiceRecording() async {
    final path = await _recorder.stop();
    setState(() => _isRecording = false);
    if (path != null) {
      setState(() => _isSendingVoice = true);
      final action = ref.read(sendMessageAction);
      final (_, error) = await action(
        albumId: widget.albumId,
        content: 'Voice message',
        type: MessageType.voice,
        metadata: {'duration': 0}, // Duration would be calculated in production
      );
      if (mounted) {
        setState(() => _isSendingVoice = false);
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.message), backgroundColor: Theme.of(context).colorScheme.error),
          );
        }
      }
    }
  }

  void _showMembers() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final membersAsync = ref.watch(albumMembersProvider(widget.albumId));
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: const EdgeInsets.all(DSSpacing.lg),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(DSRadius.xl)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Members', style: DSTypography.titleLarge.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              )),
              const SizedBox(height: DSSpacing.md),
              Expanded(
                child: membersAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Text('Failed to load members', style: DSTypography.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    )),
                  ),
                  data: (members) => ListView.separated(
                    itemCount: members.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final member = members[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: Text(
                            member.email.isNotEmpty ? member.email[0].toUpperCase() : '?',
                            style: DSTypography.labelMedium.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        title: Text(member.email, style: DSTypography.bodyLarge.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        )),
                        subtitle: Text(
                          member.isCreator ? 'Creator' : 'Member · Joined ${DateFormat('MMM d').format(member.joinedAt)}',
                          style: DSTypography.bodySmall.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        trailing: member.isCreator
                            ? Icon(Icons.star, size: 16, color: Theme.of(context).colorScheme.tertiary)
                            : null,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSharedMedia() {
    final repo = ref.read(memoryRepositoryProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => FutureBuilder(
        future: repo.albumMemories(widget.albumId),
        builder: (context, snapshot) {
          final memories = snapshot.data ?? [];
          final mediaMemories = memories.where((m) => m.storagePath != null && m.type != 'note').toList();
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(DSSpacing.lg),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(DSRadius.xl)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Shared Media', style: DSTypography.titleLarge.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                )),
                const SizedBox(height: DSSpacing.sm),
                Text('${mediaMemories.length} items', style: DSTypography.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )),
                const SizedBox(height: DSSpacing.md),
                Expanded(
                  child: mediaMemories.isEmpty
                      ? Center(
                          child: Text('No media shared yet', style: DSTypography.bodyMedium.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          )),
                        )
                      : GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1,
                          ),
                          itemCount: mediaMemories.length,
                          itemBuilder: (context, index) {
                            final memory = mediaMemories[index];
                            final url = repo.publicUrl(memory.storagePath!);
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(DSRadius.sm),
                              child: url != null
                                  ? Image.network(
                                      url,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                        child: Icon(_mediaIcon(memory.type),
                                            color: Theme.of(context).colorScheme.onSurfaceVariant),
                                      ),
                                    )
                                  : Container(
                                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                      child: Icon(_mediaIcon(memory.type),
                                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                                    ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _mediaIcon(String type) {
    return switch (type) {
      'photo' => Icons.photo_outlined,
      'video' => Icons.videocam_outlined,
      'voice' => Icons.mic_outlined,
      _ => Icons.insert_photo_outlined,
    };
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isMuted ? 'Notifications muted' : 'Notifications unmuted'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final messagesAsync = ref.watch(albumMessagesProvider(widget.albumId));

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(widget.albumTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'members':
                  _showMembers();
                  break;
                case 'media':
                  _showSharedMedia();
                  break;
                case 'mute':
                  _toggleMute();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'members',
                child: ListTile(
                  leading: Icon(Icons.people_outline),
                  title: Text('Members'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'media',
                child: ListTile(
                  leading: Icon(Icons.photo_library_outlined),
                  title: Text('Shared Media'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'mute',
                child: ListTile(
                  leading: Icon(_isMuted ? Icons.notifications_off : Icons.notifications_outlined),
                  title: Text(_isMuted ? 'Unmute' : 'Mute Notifications'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: scheme.error),
                    const SizedBox(height: DSSpacing.md),
                    Text('Failed to load messages', style: DSTypography.titleMedium.copyWith(color: scheme.onSurface)),
                    const SizedBox(height: DSSpacing.sm),
                    Text(e.toString(), style: DSTypography.bodyMedium.copyWith(color: scheme.onSurfaceVariant), textAlign: TextAlign.center),
                    const SizedBox(height: DSSpacing.lg),
                    FilledButton.icon(
                      onPressed: () => ref.invalidate(albumMessagesProvider(widget.albumId)),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return _EmptyChatState(
                    albumTitle: widget.albumTitle,
                    onSendFirstMessage: () => _controller.text = 'Hey everyone! ',
                  );
                }

                // Reverse for display (oldest first)
                final displayMessages = messages.reversed.toList();

                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: DSSpacing.lg, vertical: DSSpacing.md),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = displayMessages[index];
                    final isCurrentUser = message.userId == ref.watch(authServiceProvider).currentUser?.id;
                    final showAvatar = index == 0 || displayMessages[index - 1].userId != message.userId;

                    return GestureDetector(
                      onLongPress: () => _showMessageOptions(message),
                      child: MessageBubble(
                        message: message,
                        isOwn: isCurrentUser,
                        showAvatar: showAvatar,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Input area
          _ChatInputArea(
            controller: _controller,
            onSend: _sendMessage,
            onEmojiToggle: () => setState(() => _showEmojiPicker = !_showEmojiPicker),
            showEmojiPicker: _showEmojiPicker,
            isRecording: _isRecording,
            isSendingVoice: _isSendingVoice,
            onStartVoice: _startVoiceRecording,
            onStopVoice: _stopVoiceRecording,
          ),
        ],
      ),
    );
  }

  void _showMessageOptions(Message message) {
    final isCurrentUser = message.userId == ref.watch(authServiceProvider).currentUser?.id;
    final scheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(DSSpacing.lg),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(DSRadius.xl)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCurrentUser) ...[
              ListTile(
                leading: Icon(Icons.reply_outlined, color: scheme.onSurface),
                title: const Text('Reply'),
                onTap: () {
                  Navigator.pop(context);
                  _controller.text = '@${message.userId} ';
                  FocusScope.of(context).requestFocus(FocusNode());
                },
              ),
              ListTile(
                leading: Icon(Icons.copy_outlined, color: scheme.onSurface),
                title: const Text('Copy'),
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(text: message.content));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: const Text('Copied!'), backgroundColor: scheme.primary),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: scheme.error),
                title: Text('Delete', style: TextStyle(color: scheme.error)),
                onTap: () async {
                  Navigator.pop(context);
                  final messenger = ScaffoldMessenger.of(context);
                  final repo = ref.read(messageRepositoryProvider);
                  final error = await repo.deleteMessage(message.id);
                  if (!mounted) return;
                  if (error != null) {
                    messenger.showSnackBar(
                      SnackBar(content: Text(error.message), backgroundColor: scheme.error),
                    );
                  } else {
                    messenger.showSnackBar(
                      SnackBar(content: const Text('Message deleted'), backgroundColor: scheme.primary),
                    );
                  }
                },
              ),
            ] else ...[
              ListTile(
                leading: Icon(Icons.reply_outlined, color: scheme.onSurface),
                title: const Text('Reply'),
                onTap: () {
                  Navigator.pop(context);
                  _controller.text = '@${message.userId} ';
                  FocusScope.of(context).requestFocus(FocusNode());
                },
              ),
              ListTile(
                leading: Icon(Icons.copy_outlined, color: scheme.onSurface),
                title: const Text('Copy'),
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(text: message.content));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: const Text('Copied!'), backgroundColor: scheme.primary),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.flag_outlined, color: scheme.error),
                title: Text('Report', style: TextStyle(color: scheme.error)),
                onTap: () {
                  Navigator.pop(context);
                  _showReportDialog(message);
                },
              ),
            ],
            const SizedBox(height: DSSpacing.md),
          ],
        ),
      ),
    );
  }

  void _showReportDialog(Message message) {
    final scheme = Theme.of(context).colorScheme;
    final reportReasons = ['Spam', 'Inappropriate content', 'Harassment', 'Other'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: scheme.surface,
        title: const Text('Report Message'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: DSSpacing.sm),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                hintText: 'Select a reason',
                hintStyle: DSTypography.bodyMedium.copyWith(color: scheme.onSurfaceVariant.withValues(alpha: 0.6)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(DSRadius.md)),
              ),
              items: reportReasons.map((reason) {
                return DropdownMenuItem(value: reason, child: Text(reason));
              }).toList(),
              onChanged: (_) {},
              validator: (v) => v == null ? 'Please select a reason' : null,
            ),
            const SizedBox(height: DSSpacing.md),
            Text(
              'Your report will be reviewed by our team.',
              style: DSTypography.bodySmall.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Report submitted for review'),
                  backgroundColor: scheme.primary,
                ),
              );
            },
            child: const Text('Submit Report'),
          ),
        ],
      ),
    );
  }
}

class _EmptyChatState extends StatelessWidget {
  final String albumTitle;
  final VoidCallback onSendFirstMessage;

  const _EmptyChatState({
    required this.albumTitle,
    required this.onSendFirstMessage,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DSSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.chat_bubble_outline, size: 40, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(height: DSSpacing.lg),
            Text(
              'No messages yet',
              style: DSTypography.titleLarge.copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: DSSpacing.sm),
            Text(
              'Be the first to say something in "$albumTitle"!',
              style: DSTypography.bodyMedium.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DSSpacing.xl),
            FilledButton.icon(
              onPressed: onSendFirstMessage,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Send First Message'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatInputArea extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onEmojiToggle;
  final bool showEmojiPicker;
  final bool isRecording;
  final bool isSendingVoice;
  final VoidCallback onStartVoice;
  final VoidCallback onStopVoice;

  const _ChatInputArea({
    required this.controller,
    required this.onSend,
    required this.onEmojiToggle,
    required this.showEmojiPicker,
    this.isRecording = false,
    this.isSendingVoice = false,
    required this.onStartVoice,
    required this.onStopVoice,
  });

  @override
  State<_ChatInputArea> createState() => _ChatInputAreaState();
}

class _ChatInputAreaState extends State<_ChatInputArea> {
  late FocusNode _focusNode;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(DSSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.showEmojiPicker && !widget.isRecording)
              SizedBox(
                height: 250,
                child: _EmojiPicker(onEmojiSelected: (emoji) {
                  widget.controller.text += emoji;
                  widget.controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: widget.controller.text.length),
                  );
                }),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!widget.isRecording)
                  IconButton(
                    icon: Icon(
                      widget.showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions_outlined,
                      color: scheme.onSurfaceVariant,
                    ),
                    onPressed: widget.onEmojiToggle,
                  ),
                if (widget.isRecording) ...[
                  const SizedBox(width: DSSpacing.sm),
                  Container(
                    width: 12, height: 12,
                    decoration: BoxDecoration(
                      color: scheme.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: DSSpacing.sm),
                  Expanded(
                    child: Text(
                      'Recording...',
                      style: DSTypography.bodyMedium.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ),
                ],
                if (!widget.isRecording) ...[
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(DSRadius.full),
                      ),
                      child: TextField(
                        controller: widget.controller,
                        focusNode: _focusNode,
                        maxLines: null,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Message...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: DSSpacing.lg,
                            vertical: DSSpacing.md,
                          ),
                        ),
                        onSubmitted: (_) => widget.onSend(),
                      ),
                    ),
                  ),
                  const SizedBox(width: DSSpacing.sm),
                ],
                AnimatedContainer(
                  duration: DSAnimation.fast,
                  child: widget.isRecording
                      ? IconButton(
                          icon: widget.isSendingVoice
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.stop, color: Colors.red, size: 28),
                          onPressed: widget.isSendingVoice ? null : widget.onStopVoice,
                        )
                      : (_hasText
                          ? IconButton(
                              icon: Icon(Icons.send, color: scheme.primary),
                              onPressed: widget.onSend,
                            )
                          : IconButton(
                              icon: Icon(
                                Icons.mic_outlined,
                                color: scheme.onSurfaceVariant,
                              ),
                              onPressed: widget.onStartVoice,
                            )),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmojiPicker extends StatelessWidget {
  final void Function(String) onEmojiSelected;

  const _EmojiPicker({required this.onEmojiSelected});

  static const _categories = {
    'Smileys': ['😀', '😃', '😄', '😁', '😆', '😅', '😂', '🤣', '😊', '😇', '🙂', '🙃', '😉', '😌', '😍', '🥰', '😘', '😗', '😙', '😚', '😋', '😛', '😝', '😜', '🤪', '🤨', '🧐', '🤓', '😎', '🤩', '🥳', '😏', '😒', '😞', '😔', '😟', '😕', '🙁', '☹️', '😣', '😖', '😫', '😩', '🥺', '😢', '😭', '😤', '😠', '😡', '🤬', '🤯', '😳', '🥵', '🥶', '😱', '😨', '😰', '😥', '😓', '🤗', '🤔', '🤭', '🤫', '🤥', '😶', '😐', '😑', '😬', '🙄', '😯', '😦', '😧', '😮', '😲', '🥱', '😴', '🤤', '😪', '😵', '🤐', '🥴', '🤢', '🤮', '🤧', '😷', '🤒', '🤕', '🤑', '🤠'],
    'Gestures': ['👋', '🤚', '🖐️', '✋', '🖖', '👌', '🤏', '✌️', '🤞', '🤟', '🤘', '🤙', '👈', '👉', '👆', '🖕', '👇', '☝️', '👍', '👎', '✊', '👊', '🤛', '🤜', '👏', '🙌', '👐', '🤲', '🤝', '🙏', '✍️', '💅', '🤳', '💪', '🦾', '🦵', '🦿', '🦶', '👂', '🦻', '👃', '🧠', '🫀', '🫁', '🦷', '🦴', '👀', '👁️', '👅', '👄', '🫦'],
    'Travel': ['🌍', '🌎', '🌏', '🌐', '🗺️', '🗾', '🧭', '🏔️', '⛰️', '🌋', '🗻', '🏕️', '⛺', '🏖️', '🏝️', '🏜️', '🏞️', '🏟️', '🏛️', '🏗️', '🏘️', '🏙️', '🌃', '🌆', '🌇', '🌉', '♨️', '🎠', '🎡', '🎢', '💈', '🎪', '🚂', '🚃', '🚄', '🚅', '🚆', '🚇', '🚈', '🚉', '🚊', '🚝', '🚞', '🚋', '🚌', '🚍', '🚎', '🚐', '🚑', '🚒', '🚓', '🚔', '🚕', '🚖', '🚗', '🚘', '🚙', '🛻', '🚚', '🚛', '🚨', '🚲', '🛴', '🛵', '🏍️', '🛺', '🚜', '🚁', '🛩️', '✈️', '🛫', '🛬', '🛸', '🚀', '🛰️', '🛎️', '🧳', '🛍️', '🎒', '🧢', '🧣', '🧤', '🧥', '🧦', '👗', '👘', '👙', '👚', '👛', '👜', '👝', '🎒', '👞', '👟', '🥾', '🥿', '👠', '👡', '🩰', '👢', '👑', '👒', '🎩', '🎓', '⛑️', '🪖', '🎪', '🎭', '🎨', '🎤', '🎧', '🎷', '🎸', '🎻', '🎺', '🥁', '🎲', '🎯', '🎳', '🎮', '🕹️', '🎰', '🎴', '🃏', '🀄', '🎪'],
  };

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _categories.length,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: _categories.keys.map((k) => Tab(text: k)).toList(),
          ),
          Expanded(
            child: TabBarView(
              children: _categories.values.map((emojis) => GridView.builder(
                padding: const EdgeInsets.all(DSSpacing.md),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  childAspectRatio: 1,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: emojis.length,
                itemBuilder: (context, index) => InkWell(
                  onTap: () => onEmojiSelected(emojis[index]),
                  borderRadius: BorderRadius.circular(DSRadius.md),
                  child: Center(
                    child: Text(emojis[index], style: const TextStyle(fontSize: 24)),
                  ),
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}