import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/view_models/auth_view_model.dart';
import '../../data/repositories/album_repository.dart';
import '../../data/models/album.dart';

final albumRepositoryProvider = Provider<AlbumRepository>((_) => AlbumRepository());

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
