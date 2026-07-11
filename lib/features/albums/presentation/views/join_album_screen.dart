import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../view_models/album_view_model.dart';
import '../../../auth/presentation/view_models/auth_view_model.dart';
import '../../../../core/error/failures.dart';

class JoinAlbumScreen extends ConsumerStatefulWidget {
  const JoinAlbumScreen({super.key});

  @override
  ConsumerState<JoinAlbumScreen> createState() => _JoinAlbumScreenState();
}

class _JoinAlbumScreenState extends ConsumerState<JoinAlbumScreen> {
  final _codeCtrl = TextEditingController();
  bool _joining = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Album')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _codeCtrl,
              decoration: const InputDecoration(
                labelText: 'Invite Code',
                hintText: 'e.g. ABC123',
                prefixIcon: Icon(Icons.vpn_key),
              ),
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              onSubmitted: (_) => _join(),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter the 6-character code shared by the album creator.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _joining || _codeCtrl.text.length < 6 ? null : _join,
              child: _joining
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Join'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _join() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.length != 6) return;
    setState(() => _joining = true);
    final repo = ref.read(albumRepositoryProvider);
    // ponytail: direct repo call, joinAlbum needs a user ID. Grab from auth.
    final auth = ref.read(authServiceProvider);
    final userId = auth.currentUser?.id;
    if (userId == null) return;
    final (album, error) = await repo.joinAlbum(code, userId);
    if (mounted) {
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text((error as AlbumFailure).message)));
        setState(() => _joining = false);
      } else if (album != null) {
        context.go('/albums/${album.id}');
      }
    }
  }
}
