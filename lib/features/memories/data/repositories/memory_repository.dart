import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/storage/r2_storage.dart';
import '../models/memory.dart';

final memoryRepositoryProvider = Provider<MemoryRepository>((_) => MemoryRepository());

class MemoryRepository {
  final SupabaseClient _client = Supabase.instance.client;
  final R2Storage _r2 = R2Storage();

  Future<(Memory?, Failure?)> saveMemory({
    required String albumId, required String userId, required String type,
    String? notePhase, String? textBody, File? mediaFile,
    double? lat, double? lng, bool isConfessionLocked = false,
  }) async {
    try {
      String? storagePath;
      if (mediaFile != null) {
        final ext = mediaFile.path.split('.').last;
        final path = 'albums/$albumId/${DateTime.now().millisecondsSinceEpoch}.$ext';
        await _r2.upload(path, mediaFile);
        storagePath = path;
      }
      final res = await _client.from('memories').insert({
        'album_id': albumId,
        'user_id': userId,
        'type': type,
        if (notePhase != null) 'note_phase': notePhase,
        if (storagePath != null) 'storage_path': storagePath,
        if (textBody != null) 'text_body': textBody,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        'is_confession_locked': isConfessionLocked,
      }).select().single();
      if (mediaFile != null) {
        // ponytail: read-modify-write counter. Add .rpc increment when race matters.
        final album = await _client.from('albums').select('photo_count').eq('id', albumId).maybeSingle();
        if (album != null) {
          await _client.from('albums').update({
            'photo_count': (album['photo_count'] as int) + 1,
          }).eq('id', albumId);
        }
      }
      return (_mapMemory(res), null);
    } catch (e) {
      return (null, StorageFailure(e.toString()));
    }
  }

  Future<List<Memory>> albumMemories(String albumId) async {
    final data = await _client.from('memories')
        .select().eq('album_id', albumId).order('captured_at', ascending: false);
    return data.map((r) => _mapMemory(r)).toList();
  }

  Future<List<Memory>> albumMapMarkers(String albumId) async {
    final data = await _client.from('memories')
        .select().eq('album_id', albumId).not('lat', 'is', null);
    return data.map((r) => _mapMemory(r)).where((m) => m.hasLocation).toList();
  }

  String? publicUrl(String storagePath) {
    try { return _r2.publicUrl(storagePath); }
    catch (_) { return null; }
  }

  Memory _mapMemory(Map<String, dynamic> row) => Memory(
        id: row['id'] as String,
        albumId: row['album_id'] as String,
        userId: row['user_id'] as String,
        type: row['type'] as String,
        notePhase: row['note_phase'] as String?,
        storagePath: row['storage_path'] as String?,
        textBody: row['text_body'] as String?,
        lat: (row['lat'] as num?)?.toDouble(),
        lng: (row['lng'] as num?)?.toDouble(),
        capturedAt: DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
        isConfessionLocked: row['is_confession_locked'] as bool? ?? false,
      );
}
