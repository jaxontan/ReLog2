import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/view_models/auth_view_model.dart';
import '../view_models/album_view_model.dart';

class AlbumDetailScreen extends ConsumerWidget {
  final String albumId;
  const AlbumDetailScreen({super.key, required this.albumId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumAsync = ref.watch(albumDetailProvider(albumId));
    final userId = ref.watch(authServiceProvider).currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(albumAsync.asData?.value?.title ?? 'Album'),
        actions: [
          if (albumAsync.asData?.value != null &&
              albumAsync.asData!.value!.isActive &&
              albumAsync.asData!.value!.creatorId == userId)
            TextButton(
              onPressed: () async {
                final ok = await ref.read(endTripAction(albumId))(userId!);
                if (ok && context.mounted) {
                  ref.invalidate(albumDetailProvider(albumId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Trip ended! Memories are now frozen.')),
                  );
                }
              },
              child: Text('End Trip', style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
        ],
      ),
      body: albumAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (album) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(album.title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                '${album.membersCount} members · ${album.photoCount} photos',
                style: TextStyle(color: Colors.grey[600]),
              ),
              if (album.isActive) ...[
                const SizedBox(height: 4),
                Text('Code: ${album.inviteCode}',
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 16, letterSpacing: 2)),
              ],
              const SizedBox(height: 24),
              if (album.isActive) ...[
                _ActionTile(icon: Icons.camera_alt, title: 'Capture Memory',
                    subtitle: 'Photo, video, or voice', onTap: () => context.go('/albums/$albumId/capture')),
                _ActionTile(icon: Icons.map, title: 'Map View',
                    subtitle: 'See memories on the map', onTap: () => context.go('/albums/$albumId/map')),
                _ActionTile(icon: Icons.edit_note, title: 'Before Trip Note',
                    subtitle: 'Pre-trip thoughts', onTap: () => context.go('/albums/$albumId/notes/before')),
                _ActionTile(icon: Icons.note_add, title: 'Mid-Trip Note',
                    subtitle: 'In-the-moment thoughts', onTap: () => context.go('/albums/$albumId/notes/mid')),
                _ActionTile(icon: Icons.lock, title: 'Confession Note',
                    subtitle: 'Revealed after trip ends', onTap: () => context.go('/albums/$albumId/notes/confession')),
                _ActionTile(icon: Icons.book, title: 'After Trip Journal',
                    subtitle: 'Reflect on the journey', onTap: () => context.go('/albums/$albumId/notes/after')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon; final String title, subtitle; final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.title, required this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(leading: Icon(icon), title: Text(title), subtitle: Text(subtitle), onTap: onTap),
  );
}
