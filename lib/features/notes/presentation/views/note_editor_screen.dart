import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../memories/data/repositories/memory_repository.dart';
import '../../../auth/presentation/view_models/auth_view_model.dart';
import '../../../../core/error/failures.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  final String albumId;
  final String phase; // before | mid | confession | after
  const NoteEditorScreen({super.key, required this.albumId, required this.phase});

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  final _bodyCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _bodyCtrl.dispose();
    super.dispose();
  }

  String get _phaseLabel => switch (widget.phase) {
        'before' => 'Before Trip',
        'mid' => 'Mid-Trip',
        'confession' => 'Confession',
        'after' => 'After Trip',
        _ => 'Note',
      };

  IconData get _phaseIcon => switch (widget.phase) {
        'before' => Icons.edit_note,
        'mid' => Icons.note_add,
        'confession' => Icons.lock,
        'after' => Icons.book,
        _ => Icons.note,
      };

  bool get _isConfession => widget.phase == 'confession';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_phaseLabel),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_phaseIcon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(_phaseLabel, style: Theme.of(context).textTheme.titleMedium),
                if (_isConfession) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.lock, size: 16),
                  const SizedBox(width: 4),
                  const Text('Revealed after trip ends', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _bodyCtrl,
                decoration: InputDecoration(
                  hintText: _hintForPhase(),
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.all(16),
                ),
                expands: true,
                maxLines: null,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
            if (_isConfession) ...[
              const SizedBox(height: 8),
              const Text(
                'This note will be locked until the album creator ends the trip.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _hintForPhase() => switch (widget.phase) {
        'before' => 'What are you most excited about?',
        'mid' => "What's happening right now?",
        'confession' => 'A secret to share with the group later...',
        'after' => 'How did the trip change you?',
        _ => 'Write your thoughts...',
      };

  Future<void> _save() async {
    final body = _bodyCtrl.text.trim();
    if (body.isEmpty) return;
    setState(() => _saving = true);
    final repo = ref.read(memoryRepositoryProvider);
    final userId = ref.read(authServiceProvider).currentUser?.id;
    if (userId == null) return;
    final (_, error) = await repo.saveMemory(
      albumId: widget.albumId,
      userId: userId,
      type: 'note',
      notePhase: widget.phase,
      textBody: body,
      isConfessionLocked: _isConfession,
    );
    if (mounted) {
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text((error as StorageFailure).message)));
        setState(() => _saving = false);
      } else {
        context.go('/albums/${widget.albumId}');
      }
    }
  }
}
