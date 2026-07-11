import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/view_models/auth_view_model.dart';
import '../../data/repositories/album_repository.dart';
import '../../data/models/album.dart';

final albumRepositoryProvider = Provider<AlbumRepository>((_) => AlbumRepository());

// ponytail: StreamProvider handles loading/data/error automatically. No StateNotifier needed.
final albumListProvider = StreamProvider.autoDispose<List<Album>>((ref) {
  final userId = ref.watch(authServiceProvider).currentUser?.uid ?? '';
  return ref.watch(albumRepositoryProvider).userAlbums(userId);
});

final albumDetailProvider = FutureProvider.autoDispose.family<Album, String>((ref, albumId) async {
  final repo = ref.watch(albumRepositoryProvider);
  final (album, error) = await repo.getAlbum(albumId);
  if (error != null) throw error;
  return album!;
});

// ponytail: end-trip is a one-shot action, call the repo directly from the screen
final endTripAction = Provider.autoDispose.family<Future<bool> Function(String userId), String>(
  (ref, albumId) => (String userId) async {
    final repo = ref.read(albumRepositoryProvider);
    final error = await repo.endTrip(albumId, userId);
    return error == null;
  },
);
