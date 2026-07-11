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
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ReLog2', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () => ref.read(signOutAction)()),
        ],
      ),
      body: albums.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) => list.isEmpty
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.map, size: 64, color: scheme.primary.withValues(alpha: 0.4)),
                const SizedBox(height: 16),
                const Text('No albums yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                const Text('Create or join an album to start', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 24),
                FilledButton.icon(icon: const Icon(Icons.add), label: const Text('Create Album'), onPressed: () => context.go('/albums/create')),
                const SizedBox(height: 8),
                OutlinedButton.icon(icon: const Icon(Icons.group_add), label: const Text('Join Album'), onPressed: () => context.go('/albums/join')),
              ]),
            )
            : Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(children: [
                    Text('${list.length} album${list.length == 1 ? '' : 's'}', style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.w500)),
                    const Spacer(),
                    TextButton.icon(onPressed: () => context.go('/albums/create'), icon: const Icon(Icons.add, size: 18), label: const Text('New'), style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8))),
                    const SizedBox(width: 4),
                    TextButton.icon(onPressed: () => context.go('/albums/join'), icon: const Icon(Icons.group_add, size: 18), label: const Text('Join'), style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8))),
                  ]),
                ),
                Expanded(child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final a = list[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => context.go('/albums/${a.id}'),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(children: [
                            Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(
                                color: a.isActive ? scheme.primaryContainer : scheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(a.isActive ? Icons.explore : Icons.flag, color: a.isActive ? scheme.primary : Colors.grey, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(a.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                              const SizedBox(height: 3),
                              Row(children: [
                                Icon(Icons.people, size: 13, color: Colors.grey), const SizedBox(width: 4),
                                Text('${a.membersCount}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                const SizedBox(width: 10),
                                Icon(Icons.photo_library, size: 13, color: Colors.grey), const SizedBox(width: 4),
                                Text('${a.photoCount}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                if (!a.isActive) ...[const SizedBox(width: 10), const Icon(Icons.lock, size: 13, color: Colors.grey)],
                              ]),
                            ])),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ]),
                        ),
                      ),
                    );
                  },
                )),
              ]),
      ),
    );
  }
}
