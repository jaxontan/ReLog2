import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../../core/error/failures.dart';
import '../models/memory.dart';

final memoryRepositoryProvider = Provider<MemoryRepository>((_) => MemoryRepository());

class MemoryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CollectionReference get _memories => _firestore.collection('memories');

  Future<(Memory?, Failure?)> saveMemory({
    required String albumId,
    required String userId,
    required String type,
    String? notePhase,
    String? textBody,
    File? mediaFile,
    double? lat,
    double? lng,
    bool isConfessionLocked = false,
  }) async {
    try {
      String? storagePath;
      if (mediaFile != null) {
        final ext = mediaFile.path.split('.').last;
        final ref = _storage.ref().child('albums/$albumId/${DateTime.now().millisecondsSinceEpoch}.$ext');
        await ref.putFile(mediaFile);
        storagePath = ref.fullPath;
      }
      final doc = await _memories.add({
        'albumId': albumId,
        'userId': userId,
        'type': type,
        if (notePhase != null) 'notePhase': notePhase,
        if (storagePath != null) 'storagePath': storagePath,
        if (textBody != null) 'textBody': textBody,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        'capturedAt': FieldValue.serverTimestamp(),
        'isConfessionLocked': isConfessionLocked,
      });
      // Increment photo count if media
      if (mediaFile != null) {
        await _firestore.collection('albums').doc(albumId).update({
          'photoCount': FieldValue.increment(1),
        });
      }
      final snap = await doc.get();
      return (Memory.fromMap(doc.id, snap.data() as Map<String, dynamic>), null);
    } catch (e) {
      return (null, StorageFailure(e.toString()));
    }
  }

  Stream<List<Memory>> albumMemories(String albumId) {
    return _memories
        .where('albumId', isEqualTo: albumId)
        .orderBy('capturedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Memory.fromMap(d.id, d.data() as Map<String, dynamic>))
            .toList());
  }

  // ponytail: O(n) scan for map markers. Add geo index if > 1000 memories per album.
  Stream<List<Memory>> albumMapMarkers(String albumId) {
    return _memories
        .where('albumId', isEqualTo: albumId)
        .where('lat', isNotEqualTo: null)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Memory.fromMap(d.id, d.data() as Map<String, dynamic>))
            .where((m) => m.hasLocation)
            .toList());
  }

  Future<String?> downloadUrl(String storagePath) async {
    try {
      return await _storage.ref(storagePath).getDownloadURL();
    } catch (_) {
      return null;
    }
  }
}
