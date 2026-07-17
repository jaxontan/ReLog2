import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../app/design/design_system.dart';
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
        'before' => Icons.edit_note_outlined,
        'mid' => Icons.note_add_outlined,
        'confession' => Icons.lock_outline,
        'after' => Icons.book_outlined,
        _ => Icons.note_outlined,
      };

  bool get _isConfession => widget.phase == 'confession';

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;

    return DSPage(
      appBar: AppBar(
        title: Text(_phaseLabel),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(DSSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Phase header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(DSSpacing.sm),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(DSRadius.md),
                  ),
                  child: Icon(_phaseIcon, color: scheme.onPrimaryContainer, size: DSIconSize.md),
                ),
                const SizedBox(width: DSSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_phaseLabel, style: DSTypography.titleMedium.copyWith(color: scheme.onSurface)),
                      if (_isConfession)
                        Text(
                          'Revealed after trip ends',
                          style: DSTypography.bodySmall.copyWith(color: scheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
                if (_isConfession) ...[
                  const SizedBox(width: DSSpacing.sm),
                  Icon(Icons.lock_outline, size: 16, color: scheme.onSurfaceVariant),
                ],
              ],
            ),
            const SizedBox(height: DSSpacing.lg),
            // Editor
            Expanded(
              child: TextField(
                controller: _bodyCtrl,
                decoration: InputDecoration(
                  hintText: _hintForPhase(),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(DSRadius.md)),
                  contentPadding: const EdgeInsets.all(DSSpacing.lg),
                  filled: true,
                  fillColor: scheme.surfaceContainerHighest,
                ),
                expands: true,
                maxLines: null,
                textAlignVertical: TextAlignVertical.top,
                style: DSTypography.bodyLarge,
              ),
            ),
            if (_isConfession) ...[
              const SizedBox(height: DSSpacing.md),
              Text(
                'This note will be locked until the album creator ends the trip.',
                style: DSTypography.bodySmall.copyWith(color: scheme.onSurfaceVariant),
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