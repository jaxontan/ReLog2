import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/storage/r2_storage.dart';
import '../models/album.dart';

class AlbumRepository {
  final SupabaseClient _client = Supabase.instance.client;
  final R2Storage _r2 = R2Storage();

  Future<(String?, Failure?)> createAlbum(
    String title,
    String userId, {
    File? coverImage,
  }) async {
    try {
      String? coverPath;
      if (coverImage != null) {
        final ext = coverImage.path.split('.').last.toLowerCase();
        final path = 'albums/covers/${DateTime.now().millisecondsSinceEpoch}.$ext';
        await _r2.upload(path, coverImage);
        coverPath = path;
      }

      final code = Album.generateInviteCode();
      final res = await _client.from('albums').insert({
        'title': title,
        'creator_id': userId,
        'invite_code': code,
        'status': 'active',
        'photo_count': 0,
        'members_count': 1,
        if (coverPath != null) 'cover_image_path': coverPath,
      }).select().single();

      await _client.from('members').insert({
        'album_id': res['id'],
        'user_id': userId,
        'role': 'creator',
      });

      return (res['id'] as String, null);
    } catch (e) {
      return (null, AlbumFailure(e.toString()));
    }
  }

  Future<(Album?, Failure?)> joinAlbum(String inviteCode, String userId) async {
    try {
      final data = await _client.from('albums').select().eq('invite_code', inviteCode).maybeSingle();
      if (data == null) return (null, const AlbumFailure('Invalid invite code'));
      final albumId = data['id'] as String;
      await _client.from('members').insert({
        'album_id': albumId,
        'user_id': userId,
        'role': 'member',
      });
      // ponytail: read-modify-write for counter. Add .rpc increment when race matters.
      await _client.from('albums').update({
        'members_count': (data['members_count'] as int) + 1,
      }).eq('id', albumId);
      return (_mapAlbum(data), null);
    } catch (e) {
      return (null, AlbumFailure(e.toString()));
    }
  }

  Future<List<Album>> userAlbums(String userId) async {
    // ponytail: join through foreign key members.album_id -> albums.id.
    // Supabase PostgREST embeds: select('albums(*)') on members table.
    final data = await _client.from('members').select('albums(*)').eq('user_id', userId);
    return data.map((row) => _mapAlbum(row['albums'] as Map<String, dynamic>)).toList();
  }

  Future<(Album?, Failure?)> getAlbum(String albumId) async {
    try {
      final data = await _client.from('albums').select().eq('id', albumId).maybeSingle();
      if (data == null) return (null, const AlbumFailure('Album not found'));
      return (_mapAlbum(data), null);
    } catch (e) {
      return (null, AlbumFailure(e.toString()));
    }
  }

  Future<Failure?> endTrip(String albumId, String userId) async {
    try {
      final data = await _client.from('albums').select().eq('id', albumId).maybeSingle();
      if (data == null || (data['creator_id'] as String) != userId) {
        return const AlbumFailure('Only the creator can end the trip');
      }
      await _client.from('albums').update({'status': 'ended'}).eq('id', albumId);
      return null;
    } catch (e) {
      return AlbumFailure(e.toString());
    }
  }

  Future<String?> updateCoverImage(String albumId, File coverImage) async {
    try {
      final ext = coverImage.path.split('.').last.toLowerCase();
      final path = 'albums/covers/${albumId}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      await _r2.upload(path, coverImage);

      await _client.from('albums').update({'cover_image_path': path}).eq('id', albumId);
      return _r2.publicUrl(path);
    } catch (e) {
      return null;
    }
  }

  // ponytail: SQL snake_case columns → Dart camelCase model.
  Album _mapAlbum(Map<String, dynamic> row) => Album(
        id: row['id'] as String,
        title: row['title'] as String,
        creatorId: row['creator_id'] as String,
        inviteCode: row['invite_code'] as String,
        status: row['status'] as String,
        photoCount: row['photo_count'] as int? ?? 0,
        membersCount: row['members_count'] as int? ?? 1,
        createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
        endedAt: row['ended_at'] != null ? DateTime.tryParse(row['ended_at'] as String) : null,
        coverImagePath: row['cover_image_path'] as String?,
        // coverImageUrl computed at runtime via R2 publicUrl
      );
}
