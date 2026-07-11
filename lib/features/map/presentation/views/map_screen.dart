import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../memories/data/repositories/memory_repository.dart';
import '../../../memories/data/models/memory.dart';

// ponytail: FutureProvider replaces Firestore StreamProvider. Refresh on navigate.
final albumMapMarkersProvider = FutureProvider.autoDispose.family<List<Memory>, String>(
  (ref, albumId) async => ref.read(memoryRepositoryProvider).albumMapMarkers(albumId),
);

class MapScreen extends ConsumerWidget {
  final String albumId;
  const MapScreen({super.key, required this.albumId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final markers = ref.watch(albumMapMarkersProvider(albumId));

    return Scaffold(
      appBar: AppBar(title: const Text('Map')),
      body: markers.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (memories) {
          final coords = memories.map((m) => LatLng(m.lat!, m.lng!)).toList();
          final center = coords.isEmpty
              ? const LatLng(1.3521, 103.8198)
              : LatLng(
                  coords.map((c) => c.latitude).reduce((a, b) => a + b) / coords.length,
                  coords.map((c) => c.longitude).reduce((a, b) => a + b) / coords.length,
                );
          return FlutterMap(
            options: MapOptions(initialCenter: center, initialZoom: 13),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
              MarkerLayer(
                markers: memories.map((m) => Marker(
                  point: LatLng(m.lat!, m.lng!),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(m.isNote ? Icons.edit_location : Icons.location_on,
                        color: m.isNote ? Colors.deepPurple : Colors.red, size: 30),
                    if (m.type == 'photo')
                      const Icon(Icons.camera_alt, size: 14, color: Colors.black54),
                  ]),
                )).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}
