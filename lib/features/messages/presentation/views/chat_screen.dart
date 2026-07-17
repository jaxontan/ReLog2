/// Real-time chat screen for an album
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/design/design_system.dart';
import '../widgets/message_bubble.dart';
import '../view_models/message_view_model.dart';
import '../../data/models/message.dart';
import '../../../../features/auth/presentation/view_models/auth_view_model.dart';

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
  bool _showEmojiPicker = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
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
                  // TODO: Show members
                  break;
                case 'media':
                  // TODO: Show shared media
                  break;
                case 'mute':
                  // TODO: Mute notifications
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
              const PopupMenuItem(
                value: 'mute',
                child: ListTile(
                  leading: Icon(Icons.notifications_off_outlined),
                  title: Text('Mute Notifications'),
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

                    return MessageBubble(
                      message: message,
                      isOwn: isCurrentUser,
                      showAvatar: showAvatar,
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
                  // TODO: Implement delete
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
                  // TODO: Report message
                },
              ),
            ],
            const SizedBox(height: DSSpacing.md),
          ],
        ),
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

  const _ChatInputArea({
    required this.controller,
    required this.onSend,
    required this.onEmojiToggle,
    required this.showEmojiPicker,
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
            if (widget.showEmojiPicker)
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
                IconButton(
                  icon: Icon(
                    widget.showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions_outlined,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  onPressed: widget.onEmojiToggle,
                ),
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
                      decoration: InputDecoration(
                        hintText: 'Message...',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: DSSpacing.lg,
                          vertical: DSSpacing.md,
                        ),
                      ),
                      onSubmitted: (_) => widget.onSend(),
                    ),
                  ),
                ),
                const SizedBox(width: DSSpacing.sm),
                AnimatedContainer(
                  duration: DSAnimation.fast,
                  child: _hasText
                      ? IconButton(
                          icon: Icon(Icons.send, color: Theme.of(context).colorScheme.primary),
                          onPressed: widget.onSend,
                        )
                      : IconButton(
                          icon: Icon(
                            Icons.mic_outlined,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () {
                            // TODO: Voice message
                          },
                        ),
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