import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../view_models/album_view_model.dart';
import '../../../auth/presentation/view_models/auth_view_model.dart';
import '../../../../core/error/failures.dart';

class CreateAlbumScreen extends ConsumerStatefulWidget {
  const CreateAlbumScreen({super.key});

  @override
  ConsumerState<CreateAlbumScreen> createState() => _CreateAlbumScreenState();
}

class _CreateAlbumScreenState extends ConsumerState<CreateAlbumScreen> {
  final _titleCtrl = TextEditingController();
  bool _creating = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Album')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Album Name',
                hintText: 'e.g. Japan 2026',
                prefixIcon: Icon(Icons.album),
              ),
              autofocus: true,
              onSubmitted: (_) => _create(),
            ),
            const SizedBox(height: 8),
            const Text(
              'An invite code will be generated to share with your group.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _creating ? null : _create,
              child: _creating
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _create() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    setState(() => _creating = true);
    final repo = ref.read(albumRepositoryProvider);
    final userId = ref.read(authServiceProvider).currentUser?.id;
    if (userId == null) return;
    final (albumId, error) = await repo.createAlbum(title, userId);
    if (mounted) {
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text((error as AlbumFailure).message)));
        setState(() => _creating = false);
      } else {
        context.go('/albums/$albumId');
      }
    }
  }
}
