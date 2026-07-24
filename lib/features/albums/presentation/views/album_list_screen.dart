import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../app/design/design_system.dart';
import '../view_models/album_view_model.dart';
import '../../../auth/presentation/view_models/auth_view_model.dart';
import '../../data/models/album.dart';
import '../../../../core/storage/r2_storage.dart';

class AlbumListScreen extends ConsumerWidget {
  const AlbumListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albums = ref.watch(albumListProvider);
    final scheme = context.scheme;
    final user = ref.watch(authServiceProvider).currentUser;
    final initials = (user?.email ?? '?')[0].toUpperCase();

    return DSPage(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(DSSpacing.md),
          child: CircleAvatar(
            backgroundColor: scheme.primaryContainer,
            child: Text(
              initials,
              style: DSTypography.labelLarge.copyWith(color: scheme.onPrimaryContainer, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        title: Text('RELOG2', style: DSTypography.titleLarge.copyWith(fontWeight: FontWeight.w700, letterSpacing: 2)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: const Text('Search coming soon!'), behavior: SnackBarBehavior.floating),
              );
            },
            tooltip: 'Search',
          ),
        ],
      ),
      child: albums.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(message: e.toString()),
        data: (list) => CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(DSSpacing.xl, DSSpacing.xl, DSSpacing.xl, DSSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Shared Journals', style: DSTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold, color: scheme.onSurface)),
                    const SizedBox(height: DSSpacing.xs),
                    Text(
                      'Chronicle your expeditions and collaborative discoveries with your fellow explorers.',
                      style: DSTypography.bodyMedium.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
            // Create button
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: DSSpacing.xl),
                child: FilledButton.icon(
                  icon: const Icon(Icons.add, size: DSIconSize.sm),
                  label: const Text('CREATE NEW JOURNAL'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: DSSpacing.md),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.full)),
                    textStyle: DSTypography.labelLarge.copyWith(letterSpacing: 1),
                  ),
                  onPressed: () => context.go('/albums/create'),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: DSSpacing.md)),
            // List
            if (list.isEmpty)
              SliverFillRemaining(
                child: DSEmptyState(
                  icon: Icons.album_outlined,
                  title: 'No Journals Yet',
                  message: 'Create your first journal to start chronicling adventures with friends.',
                  action: FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Create Journal'),
                    onPressed: () => context.go('/albums/create'),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: DSSpacing.lg, vertical: DSSpacing.md),
                sliver: SliverList.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: DSSpacing.md),
                  itemBuilder: (_, i) {
                    final a = list[i];
                    return _AlbumCard(album: a);
                  },
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: DSSpacing.xxl)),
          ],
        ),
      ),
    );
  }
}

class _AlbumCard extends StatelessWidget {
  final Album album;
  const _AlbumCard({required this.album});

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;

    return DSCard(
      onTap: () => context.go('/albums/${album.id}'),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover image
          Container(
            height: 160,
            width: double.infinity,
            color: scheme.surfaceContainerHighest,
            child: album.hasCoverImage
                ? ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(DSRadius.lg)),
                    child: Image.network(
                      _getCoverUrl(album),
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(scheme),
                    ),
                  )
                : _placeholder(scheme),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(DSSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(album.title, style: DSTypography.titleMedium.copyWith(fontWeight: FontWeight.bold, color: scheme.onSurface)),
                      const SizedBox(height: DSSpacing.xs),
                      Text(
                        album.isActive ? 'Active journey' : 'Journey ended',
                        style: DSTypography.bodySmall.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: DSSpacing.md, vertical: DSSpacing.xs),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(DSRadius.full),
                  ),
                  child: Text(
                    '${album.photoCount} findings',
                    style: DSTypography.labelSmall.copyWith(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getCoverUrl(Album album) {
    if (album.coverImagePath != null && album.coverImagePath!.isNotEmpty) {
      return R2Storage().publicUrl(album.coverImagePath!);
    }
    return '';
  }

  Widget _placeholder(ColorScheme scheme) {
    return Center(
      child: Icon(Icons.explore_outlined, size: 40, color: scheme.onSurfaceVariant.withValues(alpha: 0.3)),
    );
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
            Text('Error loading journals', style: DSTypography.titleMedium.copyWith(color: scheme.onSurface)),
            const SizedBox(height: DSSpacing.sm),
            Text(message, style: DSTypography.bodyMedium.copyWith(color: scheme.onSurfaceVariant), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}