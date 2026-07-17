import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import '../../../../../app/design/design_system.dart';
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
    final scheme = context.scheme;

    return DSPage(
      appBar: AppBar(
        title: const Text('Join Journal'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DSSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.vpn_key_outlined, size: 40, color: scheme.onSecondaryContainer),
            ),
            const SizedBox(height: DSSpacing.lg),
            Text(
              'Join a Journal',
              style: DSTypography.headlineMedium.copyWith(fontWeight: FontWeight.bold, color: scheme.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DSSpacing.sm),
            Text(
              'Enter the 6-character invite code shared by the journal creator.',
              style: DSTypography.bodyMedium.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DSSpacing.xxl),
            // Form
            DSTextField(
              controller: _codeCtrl,
              hint: 'e.g. ABC123',
              label: 'Invite Code',
              prefixIcon: Icons.vpn_key_outlined,
              suffixIcon: IconButton(
                icon: const Icon(Icons.content_paste_outlined),
                onPressed: () async {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  if (data?.text != null) {
                    _codeCtrl.text = data!.text!.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
                    if (_codeCtrl.text.length > 6) _codeCtrl.text = _codeCtrl.text.substring(0, 6);
                    setState(() {}); // Update character count
                  }
                },
                tooltip: 'Paste from clipboard',
              ),
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _join(),
            ),
            const SizedBox(height: DSSpacing.xl),
            FilledButton(
              onPressed: _joining || _codeCtrl.text.length < 6 ? null : _join,
              child: _joining
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Join Journal'),
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
    final auth = ref.read(authServiceProvider);
    final userId = auth.currentUser?.id;
    if (userId == null) return;
    final (album, error) = await repo.joinAlbum(code, userId);
    if (mounted) {
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text((error as AlbumFailure).message)),
        );
        setState(() => _joining = false);
      } else if (album != null) {
        context.go('/albums/${album.id}');
      }
    }
  }
}