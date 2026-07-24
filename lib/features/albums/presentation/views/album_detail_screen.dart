import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import '../../../../app/design/design_system.dart';
import '../../../auth/presentation/view_models/auth_view_model.dart';
import '../view_models/album_view_model.dart';
import '../../data/models/album.dart';
import '../../../../core/storage/r2_storage.dart';

class AlbumDetailScreen extends ConsumerWidget {
  final String albumId;
  const AlbumDetailScreen({super.key, required this.albumId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumAsync = ref.watch(albumDetailProvider(albumId));
    final userId = ref.watch(authServiceProvider).currentUser?.id;
    final scheme = context.scheme;
    final r2 = R2Storage();

    String _getCoverUrl(Album album) {
      if (album.coverImagePath != null && album.coverImagePath!.isNotEmpty) {
        return r2.publicUrl(album.coverImagePath!);
      }
      return '';
    }

    return DSPage(
      appBar: AppBar(
        title: Text(albumAsync.asData?.value?.title ?? 'Journal'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (albumAsync.asData?.value != null &&
              albumAsync.asData!.value.isActive &&
              albumAsync.asData!.value.creatorId == userId)
            TextButton(
              onPressed: () async {
                final ok = await ref.read(endTripAction(albumId))(userId!);
                if (ok && context.mounted) {
                  ref.invalidate(albumDetailProvider(albumId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Journey ended! Memories are now frozen.'),
                      backgroundColor: scheme.primary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: Text('End Journey', style: TextStyle(color: scheme.error, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      child: albumAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(DSSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: scheme.error),
                const SizedBox(height: DSSpacing.md),
                Text('Error loading journal', style: DSTypography.titleMedium.copyWith(color: scheme.onSurface)),
                const SizedBox(height: DSSpacing.sm),
                Text(e.toString(), style: DSTypography.bodyMedium.copyWith(color: scheme.onSurfaceVariant), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
        data: (album) => CustomScrollView(
          slivers: [
            // Cover Image
            if (album.hasCoverImage)
              SliverToBoxAdapter(
                child: Container(
                  height: 240,
                  margin: const EdgeInsets.fromLTRB(DSSpacing.xl, DSSpacing.xl, DSSpacing.xl, DSSpacing.lg),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(DSRadius.lg),
                    color: scheme.surfaceContainerHighest,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(DSRadius.lg),
                    child: Image.network(
                      _getCoverUrl(album),
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Icon(Icons.explore_outlined, size: 48, color: scheme.onSurfaceVariant.withValues(alpha: 0.3)),
                      ),
                    ),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: DSSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text(album.title, style: DSTypography.headlineSmall.copyWith(color: scheme.onSurface)),
                    const SizedBox(height: DSSpacing.xs),
                    Text(
                      '${album.membersCount} companions · ${album.photoCount} findings',
                      style: DSTypography.bodyMedium.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    if (album.isActive) ...[
                      const SizedBox(height: DSSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: DSSpacing.md, vertical: DSSpacing.xs),
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          borderRadius: BorderRadius.circular(DSRadius.full),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.vpn_key_outlined, size: DSIconSize.sm, color: scheme.onPrimaryContainer),
                            const SizedBox(width: DSSpacing.xs),
                            Text(
                              'Code: ${album.inviteCode}',
                              style: DSTypography.labelMedium.copyWith(
                                color: scheme.onPrimaryContainer,
                                fontFamily: 'monospace',
                                letterSpacing: 2,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: DSSpacing.sm),
                            InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: album.inviteCode));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Invite code copied!'),
                                    backgroundColor: scheme.primary,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(DSRadius.full),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(Icons.content_copy_outlined, size: 16, color: scheme.onPrimaryContainer),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: DSSpacing.xl),
                    // Actions
                    if (album.isActive) ...[
                      _ActionCard(
                        icon: Icons.camera_alt_outlined,
                        title: 'Capture Memory',
                        subtitle: 'Photo, video, or voice',
                        onTap: () => context.go('/albums/$albumId/capture'),
                        color: scheme.primary,
                      ),
                      const SizedBox(height: DSSpacing.md),
                      _ActionCard(
                        icon: Icons.map_outlined,
                        title: 'Map View',
                        subtitle: 'See memories on the map',
                        onTap: () => context.go('/albums/$albumId/map'),
                        color: scheme.secondary,
                      ),
                      const SizedBox(height: DSSpacing.md),
                      _ActionCard(
                        icon: Icons.edit_note_outlined,
                        title: 'Before Trip Note',
                        subtitle: 'Pre-journey thoughts',
                        onTap: () => context.go('/albums/$albumId/notes/before'),
                        color: scheme.tertiary,
                      ),
                      const SizedBox(height: DSSpacing.md),
                      _ActionCard(
                        icon: Icons.note_add_outlined,
                        title: 'Mid-Trip Note',
                        subtitle: 'In-the-moment thoughts',
                        onTap: () => context.go('/albums/$albumId/notes/mid'),
                        color: scheme.primary,
                      ),
                      const SizedBox(height: DSSpacing.md),
                      _ActionCard(
                        icon: Icons.lock_outline,
                        title: 'Confession Note',
                        subtitle: 'Revealed after journey ends',
                        onTap: () => context.go('/albums/$albumId/notes/confession'),
                        color: scheme.error,
                      ),
                      const SizedBox(height: DSSpacing.md),
                      _ActionCard(
                        icon: Icons.book_outlined,
                        title: 'After Trip Journal',
                        subtitle: 'Reflect on the journey',
                        onTap: () => context.go('/albums/$albumId/notes/after'),
                        color: scheme.secondary,
                      ),
                      const SizedBox(height: DSSpacing.md),
                      _ActionCard(
                        icon: Icons.chat_bubble_outline,
                        title: 'Group Chat',
                        subtitle: 'Chat with your companions',
                        onTap: () => context.go('/albums/$albumId/chat?title=${Uri.encodeComponent(album.title)}'),
                        color: scheme.primary,
                      ),
                    ] else ...[
                      // Ended state
                      DSCard(
                        padding: const EdgeInsets.all(DSSpacing.lg),
                        child: Column(
                          children: [
                            Icon(Icons.flag_outlined, size: 48, color: scheme.primary),
                            const SizedBox(height: DSSpacing.md),
                            Text(
                              'Journey Completed',
                              style: DSTypography.titleLarge.copyWith(color: scheme.onSurface),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: DSSpacing.sm),
                            Text(
                              'This journal has ended. All memories are preserved. Confession notes are now revealed.',
                              style: DSTypography.bodyMedium.copyWith(color: scheme.onSurfaceVariant),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: DSSpacing.xxl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;

    return DSCard(
      onTap: onTap,
      padding: const EdgeInsets.all(DSSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(DSRadius.md),
            ),
            child: Icon(icon, color: color, size: DSIconSize.md),
          ),
          const SizedBox(width: DSSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: DSTypography.titleSmall.copyWith(color: scheme.onSurface, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle, style: DSTypography.bodySmall.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}