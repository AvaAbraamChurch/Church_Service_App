import 'package:cloud_firestore/cloud_firestore.dart';

/// A child's entry in the per-day, per-game played queue (read-only history).
/// Firestore path: club_days/{YYYY-MM-DD}/game_sessions/{gameId}/played_queue/{docId}
class PlayedQueueEntry {
  final String id;
  final String childId;
  final String childName;
  final DateTime playedAt;

  const PlayedQueueEntry({
    required this.id,
    required this.childId,
    required this.childName,
    required this.playedAt,
  });

  factory PlayedQueueEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final ts = data['playedAt'];
    return PlayedQueueEntry(
      id: doc.id,
      childId: (data['childId'] ?? '').toString(),
      childName: (data['childName'] ?? '').toString(),
      playedAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'childId': childId,
        'childName': childName,
        'playedAt': Timestamp.fromDate(playedAt),
      };
}
