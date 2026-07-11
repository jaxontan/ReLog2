import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../view_models/album_view_model.dart';
import '../../../auth/presentation/view_models/auth_view_model.dart';
import '../../../auth/data/services/auth_service.dart';

class AlbumListScreen extends ConsumerWidget {
  const AlbumListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albums = ref.watch(albumListProvider);
    final scheme = Theme.of(context).colorScheme;
    final user = ref.watch(authServiceProvider).currentUser;
    final initials = (user?.email ?? '?')[0].toUpperCase();

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(10),
          child: CircleAvatar(backgroundColor: Colors.orange, child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ),
        title: const Text('relog2', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: const [IconButton(icon: Icon(Icons.search), onPressed: null)], // ponytail: no-op, add when search exists
      ),
      body: albums.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Text('Shared Albums', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Text('Collaborate and relive moments together.', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('+ Create New Album', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                onPressed: () => context.go('/albums/create'),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (list.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(48), child: Text('No albums yet', style: TextStyle(fontSize: 16, color: Colors.grey))))
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final a = list[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => context.go('/albums/${a.id}'),
                        child: Column(children: [
                          // ponytail: cover image placeholder block
                          Container(
                            height: 160,
                            color: const Color(0xFFE8F5E9),
                            child: Center(child: Icon(Icons.photo_album, size: 40, color: Colors.grey[400])),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(children: [
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(a.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 4),
                                // ponytail: timestamp from createdAt, relative formatting deferred
                                Text('Active now', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                              ])),
                              // ponytail: photo count pill
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                                child: Text('${a.photoCount} Photos', style: TextStyle(color: Colors.grey[700], fontSize: 12, fontWeight: FontWeight.w500)),
                              ),
                            ]),
                          ),
                        ]),
                      ),
                    ),
                  );
                },
              ),
            ),
        ]),
      ),
    );
  }
}
