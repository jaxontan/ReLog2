import 'dart:math';

class Album {
  final String id;
  final String title;
  final String creatorId;
  final String inviteCode;
  final String status; // active | ended
  final int photoCount;
  final int membersCount;
  final DateTime createdAt;
  final DateTime? endedAt;

  const Album({
    required this.id,
    required this.title,
    required this.creatorId,
    required this.inviteCode,
    required this.status,
    this.photoCount = 0,
    this.membersCount = 1,
    required this.createdAt,
    this.endedAt,
  });

  bool get isActive => status == 'active';

  Map<String, dynamic> toMap() => {
        'title': title,
        'creatorId': creatorId,
        'inviteCode': inviteCode,
        'status': status,
        'photoCount': photoCount,
        'membersCount': membersCount,
        'createdAt': createdAt.toIso8601String(),
        if (endedAt != null) 'endedAt': endedAt!.toIso8601String(),
      };

  factory Album.fromMap(String id, Map<String, dynamic> map) => Album(
        id: id,
        title: map['title'] ?? '',
        creatorId: map['creatorId'] ?? '',
        inviteCode: map['inviteCode'] ?? '',
        status: map['status'] ?? 'active',
        photoCount: map['photoCount'] ?? 0,
        membersCount: map['membersCount'] ?? 1,
        createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
        endedAt: map['endedAt'] != null ? DateTime.tryParse(map['endedAt']) : null,
      );

  // ponytail: 6-char alphanumeric from stdlib Random. Replace with uuid if collisions happen.
  static String generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(6, (_) => chars[Random().nextInt(chars.length)]).join();
  }
}
