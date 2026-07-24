import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../app/design/design_system.dart';
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
  File? _coverImage;
  final _picker = ImagePicker();

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCoverImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (picked != null && mounted) {
      setState(() => _coverImage = File(picked.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;

    return DSPage(
      appBar: AppBar(
        title: const Text('Create Journal'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(DSSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.menu_book_outlined, size: 40, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(height: DSSpacing.lg),
            Text(
              'New Journal',
              style: DSTypography.headlineMedium.copyWith(fontWeight: FontWeight.bold, color: scheme.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DSSpacing.sm),
            Text(
              'Give your journal a name and share the invite code with your companions.',
              style: DSTypography.bodyMedium.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DSSpacing.xxl),
            // Cover Image Picker
            GestureDetector(
              onTap: _pickCoverImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(DSRadius.lg),
                  border: Border.all(color: scheme.outlineVariant, width: 2, style: BorderStyle.solid),
                ),
                child: _coverImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(DSRadius.lg),
                        child: Image.file(
                          _coverImage!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, size: 48, color: scheme.onSurfaceVariant),
                          const SizedBox(height: DSSpacing.md),
                          Text(
                            'Add Cover Image (Optional)',
                            style: DSTypography.titleSmall.copyWith(color: scheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: DSSpacing.xs),
                          Text(
                            'Tap to select from gallery',
                            style: DSTypography.bodySmall.copyWith(color: scheme.onSurfaceVariant.withValues(alpha: 0.7)),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: DSSpacing.xxl),
            // Form
            DSTextField(
              controller: _titleCtrl,
              hint: 'e.g. Japan 2026',
              label: 'Journal Name',
              prefixIcon: Icons.album_outlined,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _create(),
            ),
            const SizedBox(height: DSSpacing.md),
            Text(
              'A unique 6-character invite code will be generated automatically.',
              style: DSTypography.bodySmall.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DSSpacing.xl),
            FilledButton(
              onPressed: _creating ? null : _create,
              child: _creating
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Create Journal'),
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
    final (albumId, error) = await repo.createAlbum(title, userId, coverImage: _coverImage);
    if (mounted) {
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text((error as AlbumFailure).message)),
        );
        setState(() => _creating = false);
      } else {
        context.go('/albums/$albumId');
      }
    }
  }
}