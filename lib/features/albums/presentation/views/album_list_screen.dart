import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../view_models/album_view_model.dart';
import '../../../auth/presentation/view_models/auth_view_model.dart';

class AlbumListScreen extends ConsumerWidget {
  const AlbumListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albums = ref.watch(albumListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ReLog2'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(signOutAction)(),
          ),
        ],
      ),
      body: albums.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) => list.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.photo_album, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('No albums yet', style: TextStyle(fontSize: 18)),
                    const SizedBox(height: 8),
                    const Text('Create or join an album to start'),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => context.go('/albums/create'),
                      icon: const Icon(Icons.add),
                      label: const Text('Create Album'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => context.go('/albums/join'),
                      icon: const Icon(Icons.group_add),
                      label: const Text('Join Album'),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final album = list[i];
                  return Card(
                    child: ListTile(
                      leading: Icon(album.isActive ? Icons.map : Icons.map_outlined),
                      title: Text(album.title),
                      subtitle: Text('${album.membersCount} members · ${album.photoCount} photos'),
                      trailing: album.isActive
                          ? null
                          : const Chip(label: Text('Ended', style: TextStyle(fontSize: 11))),
                      onTap: () => context.go('/albums/${album.id}'),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: albums.maybeWhen(
        orElse: () => null,
        data: (list) => list.isNotEmpty
            ? FloatingActionButton(
                onPressed: () => context.go('/albums/create'),
                child: const Icon(Icons.add),
              )
            : null,
      ),
    );
  }
}
