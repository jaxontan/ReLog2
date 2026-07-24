import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/presentation/view_models/auth_view_model.dart';
import '../../data/repositories/album_repository.dart';
import '../../data/models/album.dart';

final albumRepositoryProvider = Provider<AlbumRepository>((_) => AlbumRepository());

/// Simple member representation for UI display.
class AlbumMember {
  final String id;
  final String userId;
  final String email;
  final String role;
  final DateTime joinedAt;

  const AlbumMember({
    required this.id,
    required this.userId,
    required this.email,
    required this.role,
    required this.joinedAt,
  });

  bool get isCreator => role == 'creator';
}

// ponytail: FutureProvider replaces Firestore StreamProvider. Refresh on navigate.
final albumListProvider = FutureProvider.autoDispose<List<Album>>((ref) async {
  final userId = ref.watch(authServiceProvider).currentUser?.id;
  if (userId == null) return [];
  return ref.read(albumRepositoryProvider).userAlbums(userId);
});

final albumDetailProvider = FutureProvider.autoDispose.family<Album, String>((ref, albumId) async {
  final repo = ref.read(albumRepositoryProvider);
  final (album, error) = await repo.getAlbum(albumId);
  if (error != null) throw error;
  return album!;
});

final endTripAction = Provider.autoDispose.family<Future<bool> Function(String userId), String>(
  (ref, albumId) => (String userId) async {
    final repo = ref.read(albumRepositoryProvider);
    final error = await repo.endTrip(albumId, userId);
    return error == null;
  },
);

/// Fetches members for an album, including their email from auth.users.
final albumMembersProvider = FutureProvider.autoDispose.family<List<AlbumMember>, String>((ref, albumId) async {
  final client = Supabase.instance.client;
  final data = await client
      .from('members')
      .select('id, user_id, role, joined_at, auth.users!inner(email)')
      .eq('album_id', albumId);

  return data.map((row) {
    final user = row['auth.users'] as Map<String, dynamic>;
    return AlbumMember(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      email: user['email'] as String? ?? 'Unknown',
      role: row['role'] as String? ?? 'member',
      joinedAt: DateTime.tryParse(row['joined_at'] as String? ?? '') ?? DateTime.now(),
    );
  }).toList();
});
