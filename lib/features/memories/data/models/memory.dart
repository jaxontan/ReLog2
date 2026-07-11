class Memory {
  final String id;
  final String albumId;
  final String userId;
  final String type; // photo | video | voice | note
  final String? notePhase; // before | mid | confession | after
  final String? storagePath;
  final String? textBody;
  final double? lat;
  final double? lng;
  final DateTime capturedAt;
  final bool isConfessionLocked;

  const Memory({
    required this.id,
    required this.albumId,
    required this.userId,
    required this.type,
    this.notePhase,
    this.storagePath,
    this.textBody,
    this.lat,
    this.lng,
    required this.capturedAt,
    this.isConfessionLocked = false,
  });

  bool get isNote => type == 'note';
  bool get hasLocation => lat != null && lng != null;

  Map<String, dynamic> toMap() => {
        'albumId': albumId,
        'userId': userId,
        'type': type,
        if (notePhase != null) 'notePhase': notePhase,
        if (storagePath != null) 'storagePath': storagePath,
        if (textBody != null) 'textBody': textBody,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        'capturedAt': capturedAt.toIso8601String(),
        'isConfessionLocked': isConfessionLocked,
      };

  factory Memory.fromMap(String id, Map<String, dynamic> map) => Memory(
        id: id,
        albumId: map['albumId'] ?? '',
        userId: map['userId'] ?? '',
        type: map['type'] ?? 'photo',
        notePhase: map['notePhase'],
        storagePath: map['storagePath'],
        textBody: map['textBody'],
        lat: (map['lat'] as num?)?.toDouble(),
        lng: (map['lng'] as num?)?.toDouble(),
        capturedAt: DateTime.tryParse(map['capturedAt'] ?? '') ?? DateTime.now(),
        isConfessionLocked: map['isConfessionLocked'] ?? false,
      );
}
