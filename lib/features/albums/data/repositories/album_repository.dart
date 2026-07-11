import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/error/failures.dart';
import '../models/album.dart';

class AlbumRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _albums => _firestore.collection('albums');

  Future<(String?, Failure?)> createAlbum(String title, String userId) async {
    try {
      final code = Album.generateInviteCode();
      final doc = await _albums.add({
        'title': title,
        'creatorId': userId,
        'inviteCode': code,
        'status': 'active',
        'photoCount': 0,
        'membersCount': 1,
        'createdAt': FieldValue.serverTimestamp(),
      });
      // Creator is member #1
      await _firestore.collection('members').add({
        'albumId': doc.id,
        'userId': userId,
        'role': 'creator',
        'joinedAt': FieldValue.serverTimestamp(),
      });
      return (doc.id, null);
    } catch (e) {
      return (null, AlbumFailure(e.toString()));
    }
  }

  Future<(Album?, Failure?)> joinAlbum(String inviteCode, String userId) async {
    try {
      final query = await _albums.where('inviteCode', isEqualTo: inviteCode).limit(1).get();
      if (query.docs.isEmpty) return (null, const AlbumFailure('Invalid invite code'));
      final doc = query.docs.first;
      // ponytail: atomic increment. Firestore handles race.
      await _firestore.collection('members').add({
        'albumId': doc.id,
        'userId': userId,
        'role': 'member',
        'joinedAt': FieldValue.serverTimestamp(),
      });
      await doc.reference.update({'membersCount': FieldValue.increment(1)});
      return (Album.fromMap(doc.id, doc.data() as Map<String, dynamic>), null);
    } catch (e) {
      return (null, AlbumFailure(e.toString()));
    }
  }

  Stream<List<Album>> userAlbums(String userId) {
    return _firestore
        .collection('members')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .asyncMap((snap) async {
      if (snap.docs.isEmpty) return [];
      final albumIds = snap.docs.map((d) => ((d.data() as Map<String, dynamic>)['albumId'] as String)).toList();
      // ponytail: Firestore 'in' query limited to 30. Paginate if > 30 albums.
      if (albumIds.isEmpty) return [];
      final albumSnap = await _albums.where(FieldPath.documentId, whereIn: albumIds).get();
      return albumSnap.docs
          .map((d) => Album.fromMap(d.id, d.data() as Map<String, dynamic>))
          .toList();
    });
  }

  Future<(Album?, Failure?)> getAlbum(String albumId) async {
    try {
      final doc = await _albums.doc(albumId).get();
      if (!doc.exists) return (null, const AlbumFailure('Album not found'));
      return (Album.fromMap(doc.id, doc.data() as Map<String, dynamic>), null);
    } catch (e) {
      return (null, AlbumFailure(e.toString()));
    }
  }

  Future<Failure?> endTrip(String albumId, String userId) async {
    try {
      final doc = await _albums.doc(albumId).get();
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null || data['creatorId'] != userId) {
        return const AlbumFailure('Only the creator can end the trip');
      }
      await doc.reference.update({
        'status': 'ended',
        'endedAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      return AlbumFailure(e.toString());
    }
  }
}
