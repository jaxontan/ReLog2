import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';
import '../../../../app/design/design_system.dart';
import '../../../auth/presentation/view_models/auth_view_model.dart';
import '../../data/repositories/memory_repository.dart';
import '../../data/models/memory.dart';

final memoryDetailProvider = FutureProvider.autoDispose.family<Memory, String>((ref, memoryId) async {
  final repo = ref.read(memoryRepositoryProvider);
  final (memory, error) = await repo.getMemory(memoryId);
  if (error != null) throw error;
  return memory!;
});

class MemoryDetailScreen extends ConsumerStatefulWidget {
  final String memoryId;
  const MemoryDetailScreen({super.key, required this.memoryId});

  @override
  ConsumerState<MemoryDetailScreen> createState() => _MemoryDetailScreenState();
}

class _MemoryDetailScreenState extends ConsumerState<MemoryDetailScreen> {
  final _audioPlayer = AudioPlayer();
  VideoPlayerController? _videoController;
  bool _playing = false;

  @override
  void dispose() {
    _audioPlayer.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _playAudio(String storagePath) async {
    if (_playing) {
      await _audioPlayer.stop();
      setState(() => _playing = false);
      return;
    }

    final repo = ref.read(memoryRepositoryProvider);
    final url = repo.publicUrl(storagePath);
    if (url == null) return;

    setState(() => _playing = true);
    try {
      await _audioPlayer.setUrl(url);
      await _audioPlayer.play();
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          if (mounted) setState(() => _playing = false);
        }
      });
    } catch (_) {
      if (mounted) setState(() => _playing = false);
    }
  }

  Future<void> _initVideo(String storagePath) async {
    final repo = ref.read(memoryRepositoryProvider);
    final url = repo.publicUrl(storagePath);
    if (url == null) return;

    _videoController?.dispose();
    _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
    await _videoController!.initialize();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final memoryAsync = ref.watch(memoryDetailProvider(widget.memoryId));
    final scheme = context.scheme;
    final currentUser = ref.watch(authServiceProvider).currentUser;

    return DSPage(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
        title: Text('Memory', style: DSTypography.titleLarge.copyWith(color: scheme.onSurface)),
        backgroundColor: scheme.surface,
        elevation: 0,
      ),
      child: memoryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(message: e.toString()),
        data: (memory) {
          final isOwn = currentUser?.id == memory.userId;
          final isConfessionLocked = memory.isConfessionLocked && memory.type == 'note' && memory.notePhase == 'confession';

          // Initialize video controller for video memories
          if (memory.type == 'video' && memory.storagePath != null && _videoController == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _initVideo(memory.storagePath!);
            });
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(DSSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type badge
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: DSSpacing.md, vertical: DSSpacing.xs),
                            decoration: BoxDecoration(
                              color: _typeColor(memory.type, scheme).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(DSRadius.full),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_typeIcon(memory.type), size: DSIconSize.sm, color: _typeColor(memory.type, scheme)),
                                const SizedBox(width: DSSpacing.xs),
                                Text(
                                  memory.type.toUpperCase(),
                                  style: DSTypography.labelSmall.copyWith(
                                    color: _typeColor(memory.type, scheme),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (memory.notePhase != null) ...[
                            const SizedBox(width: DSSpacing.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: DSSpacing.md, vertical: DSSpacing.xs),
                              decoration: BoxDecoration(
                                color: scheme.primaryContainer,
                                borderRadius: BorderRadius.circular(DSRadius.full),
                              ),
                              child: Text(
                                memory.notePhase!.toUpperCase(),
                                style: DSTypography.labelSmall.copyWith(
                                  color: scheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: DSSpacing.lg),
                      // Media content
                      _buildMediaContent(memory, scheme, isConfessionLocked),
                      const SizedBox(height: DSSpacing.xl),
                      // Text body for notes
                      if (memory.textBody != null && memory.textBody!.isNotEmpty && !isConfessionLocked) ...[
                        DSCard(
                          padding: const EdgeInsets.all(DSSpacing.lg),
                          child: Text(
                            memory.textBody!,
                            style: DSTypography.journalBody.copyWith(color: scheme.onSurface),
                          ),
                        ),
                        const SizedBox(height: DSSpacing.lg),
                      ],
                      if (isConfessionLocked) ...[
                        DSCard(
                          padding: const EdgeInsets.all(DSSpacing.lg),
                          child: Row(
                            children: [
                              Icon(Icons.lock_outline, color: scheme.error, size: DSIconSize.md),
                              const SizedBox(width: DSSpacing.md),
                              Expanded(
                                child: Text(
                                  'This confession is locked until the trip ends.',
                                  style: DSTypography.bodyMedium.copyWith(color: scheme.onSurfaceVariant),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: DSSpacing.lg),
                      ],
                      // Location
                      if (memory.lat != null && memory.lng != null) ...[
                        DSCard(
                          padding: const EdgeInsets.all(DSSpacing.lg),
                          child: Row(
                            children: [
                              Icon(Icons.location_on_outlined, color: scheme.primary, size: DSIconSize.md),
                              const SizedBox(width: DSSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Location', style: DSTypography.labelMedium.copyWith(color: scheme.onSurfaceVariant)),
                                    Text(
                                      'Lat: ${memory.lat!.toStringAsFixed(4)}, Lng: ${memory.lng!.toStringAsFixed(4)}',
                                      style: DSTypography.bodyMedium.copyWith(color: scheme.onSurface, fontFamily: 'monospace'),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () => context.go('/albums/${memory.albumId}/map'),
                                child: const Text('View on Map'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: DSSpacing.lg),
                      ],
                      // Timestamp
                      DSCard(
                        padding: const EdgeInsets.all(DSSpacing.lg),
                        child: Row(
                          children: [
                            Icon(Icons.access_time_outlined, color: scheme.onSurfaceVariant, size: DSIconSize.md),
                            const SizedBox(width: DSSpacing.md),
                            Text(
                              'Captured ${_formatDateTime(memory.capturedAt)}',
                              style: DSTypography.bodyMedium.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      if (isOwn) ...[
                        const SizedBox(height: DSSpacing.lg),
                        FilledButton.icon(
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Delete Memory'),
                          style: FilledButton.styleFrom(
                            backgroundColor: scheme.error,
                            foregroundColor: scheme.onError,
                            minimumSize: const Size(double.infinity, 56),
                          ),
                          onPressed: () => _confirmDelete(memory),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMediaContent(Memory memory, ColorScheme scheme, bool isConfessionLocked) {
    if (memory.type == 'photo' && memory.storagePath != null) {
      final repo = ref.read(memoryRepositoryProvider);
      final url = repo.publicUrl(memory.storagePath!);
      return DSCard(
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(DSRadius.lg),
          child: url != null
              ? Image.network(
                  url,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _mediaPlaceholder(scheme),
                )
              : _mediaPlaceholder(scheme),
        ),
      );
    }

    if (memory.type == 'video' && memory.storagePath != null) {
      final repo = ref.read(memoryRepositoryProvider);
      final url = repo.publicUrl(memory.storagePath!);
      return DSCard(
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(DSRadius.lg),
          child: url != null
              ? Column(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: _videoController?.value.isInitialized == true
                          ? VideoPlayer(_videoController!)
                          : Container(
                              color: Colors.black,
                              child: const Center(child: CircularProgressIndicator()),
                            ),
                    ),
                    if (_videoController?.value.isInitialized == true)
                      Padding(
                        padding: const EdgeInsets.all(DSSpacing.sm),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Icon(
                                _videoController!.value.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                color: scheme.primary,
                                size: 28,
                              ),
                              onPressed: () {
                                setState(() {
                                  _videoController!.value.isPlaying
                                      ? _videoController!.pause()
                                      : _videoController!.play();
                                });
                              },
                            ),
                            Text(
                              _formatDuration(_videoController!.value.duration),
                              style: DSTypography.bodySmall.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    if (memory.textBody != null && memory.textBody!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(DSSpacing.md),
                        child: Text(memory.textBody!, style: DSTypography.bodyMedium.copyWith(color: scheme.onSurface)),
                      ),
                  ],
                )
              : _mediaPlaceholder(scheme),
        ),
      );
    }

    if (memory.type == 'voice' && memory.storagePath != null) {
      final repo = ref.read(memoryRepositoryProvider);
      final url = repo.publicUrl(memory.storagePath!);
      return DSCard(
        padding: const EdgeInsets.all(DSSpacing.lg),
        child: Row(
          children: [
            GestureDetector(
              onTap: url != null ? () => _playAudio(memory.storagePath!) : null,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _playing ? scheme.primary : scheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _playing ? Icons.stop : Icons.play_arrow,
                  color: _playing ? scheme.onPrimary : scheme.onPrimaryContainer,
                  size: DSIconSize.lg,
                ),
              ),
            ),
            const SizedBox(width: DSSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Voice Message', style: DSTypography.titleSmall.copyWith(color: scheme.onSurface)),
                  const SizedBox(height: DSSpacing.xs),
                  Text(
                    memory.metadata?['duration'] != null
                        ? '${memory.metadata!['duration']}s'
                        : 'Tap to play',
                    style: DSTypography.bodySmall.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (url != null)
              Icon(Icons.cloud_download_outlined, color: scheme.onSurfaceVariant, size: DSIconSize.md),
          ],
        ),
      );
    }

    // Note type without text body (shouldn't happen but handle gracefully)
    return DSCard(
      padding: const EdgeInsets.all(DSSpacing.lg),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_typeIcon(memory.type), size: 48, color: scheme.onSurfaceVariant),
            const SizedBox(height: DSSpacing.md),
            Text('No content', style: DSTypography.bodyMedium.copyWith(color: scheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _mediaPlaceholder(ColorScheme scheme) {
    return Container(
      height: 200,
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(Icons.broken_image_outlined, size: 48, color: scheme.onSurfaceVariant),
      ),
    );
  }

  IconData _typeIcon(String type) {
    return switch (type) {
      'photo' => Icons.camera_alt_outlined,
      'video' => Icons.videocam_outlined,
      'voice' => Icons.mic_outlined,
      'note' => Icons.edit_note_outlined,
      _ => Icons.help_outline,
    };
  }

  Color _typeColor(String type, ColorScheme scheme) {
    return switch (type) {
      'photo' => Colors.red,
      'video' => Colors.blue,
      'voice' => Colors.orange,
      'note' => scheme.primary,
      _ => scheme.onSurfaceVariant,
    };
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _confirmDelete(Memory memory) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Memory?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final repo = ref.read(memoryRepositoryProvider);
      final error = await repo.deleteMemory(memory.id);
      if (mounted) {
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: ${error.message}')),
          );
        } else {
          context.pop();
        }
      }
    }
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DSSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: scheme.error),
            const SizedBox(height: DSSpacing.md),
            Text('Error loading memory', style: DSTypography.titleMedium.copyWith(color: scheme.onSurface)),
            const SizedBox(height: DSSpacing.sm),
            Text(message, style: DSTypography.bodyMedium.copyWith(color: scheme.onSurfaceVariant), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}