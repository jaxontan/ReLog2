import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../app/design/design_system.dart';
import '../../../memories/data/repositories/memory_repository.dart';
import '../../../memories/data/models/memory.dart';

final albumMapMarkersProvider = FutureProvider.autoDispose.family<List<Memory>, String>(
  (ref, albumId) async => ref.read(memoryRepositoryProvider).albumMapMarkers(albumId),
);

class MapScreen extends ConsumerWidget {
  final String albumId;
  const MapScreen({super.key, required this.albumId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final markers = ref.watch(albumMapMarkersProvider(albumId));
    final scheme = context.scheme;

    return DSPage(
      appBar: AppBar(
        title: const Text('Map View'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.go('/albums/$albumId'),
        ),
      ),
      child: markers.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(DSSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: scheme.error),
                const SizedBox(height: DSSpacing.md),
                Text('Error loading map', style: DSTypography.titleMedium.copyWith(color: scheme.onSurface)),
                const SizedBox(height: DSSpacing.sm),
                Text(e.toString(), style: DSTypography.bodyMedium.copyWith(color: scheme.onSurfaceVariant), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
        data: (memories) {
          final coords = memories.where((m) => m.lat != null && m.lng != null).map((m) => LatLng(m.lat!, m.lng!)).toList();
          final center = coords.isEmpty
              ? const LatLng(1.3521, 103.8198) // Singapore default
              : LatLng(
                  coords.map((c) => c.latitude).reduce((a, b) => a + b) / coords.length,
                  coords.map((c) => c.longitude).reduce((a, b) => a + b) / coords.length,
                );

          return FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: coords.isEmpty ? 13 : 14,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.relog2.app',
                maxZoom: 19,
              ),
              MarkerLayer(
                markers: memories
                    .where((m) => m.lat != null && m.lng != null)
                    .map((m) => Marker(
                          point: LatLng(m.lat!, m.lng!),
                          width: 50,
                          height: 50,
                          child: GestureDetector(
                            onTap: () => _showMemoryDetail(context, m),
                            child: _MemoryMarker(memory: m),
                          ),
                        ))
                    .toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}

void _showMemoryDetail(BuildContext context, Memory memory) {
  final scheme = Theme.of(context).colorScheme;
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => Container(
      margin: const EdgeInsets.all(DSSpacing.lg),
      padding: const EdgeInsets.all(DSSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(DSRadius.xl),
        boxShadow: DSElevation.level3,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: memory.type == 'photo' ? Colors.red.withValues(alpha: 0.15) : scheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(DSRadius.md),
                ),
                child: Icon(
                  memory.type == 'photo' ? Icons.camera_alt_outlined :
                  memory.type == 'video' ? Icons.videocam_outlined :
                  memory.type == 'voice' ? Icons.mic_outlined : Icons.edit_outlined,
                  color: memory.type == 'photo' ? Colors.red : scheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: DSSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      memory.type == 'note' ? memory.notePhase?.toUpperCase() ?? 'NOTE' : memory.type.toUpperCase(),
                      style: DSTypography.labelMedium.copyWith(color: scheme.primary, fontWeight: FontWeight.w600),
                    ),
                    if (memory.textBody != null && memory.textBody!.isNotEmpty)
                      Text(
                        memory.textBody!,
                        style: DSTypography.bodyMedium.copyWith(color: scheme.onSurface),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DSSpacing.md),
          if (memory.textBody != null && memory.textBody!.isNotEmpty) ...[
            Text(
              memory.textBody!,
              style: DSTypography.bodyMedium.copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: DSSpacing.md),
          ],
          if (memory.lat != null && memory.lng != null) ...[
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 16, color: scheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  'Lat: ${memory.lat!.toStringAsFixed(4)}, Lng: ${memory.lng!.toStringAsFixed(4)}',
                  style: DSTypography.bodySmall.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: DSSpacing.md),
          ],
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _MemoryMarker extends StatelessWidget {
  final Memory memory;
  const _MemoryMarker({required this.memory});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isPhoto = memory.type == 'photo';
    final isNote = memory.type == 'note';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: isPhoto ? Colors.red : scheme.primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: DSElevation.level2,
          ),
          child: Icon(
            isPhoto ? Icons.camera_alt_outlined : (isNote ? Icons.edit_outlined : Icons.mic_outlined),
            color: Colors.white,
            size: 18,
          ),
        ),
        if (isPhoto)
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(DSRadius.full),
            ),
            child: Text(
              '${memory.albumId.hashCode % 100}',
              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }
}