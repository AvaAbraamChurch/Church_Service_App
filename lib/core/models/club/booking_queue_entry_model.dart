import 'package:cloud_firestore/cloud_firestore.dart';

/// A child's entry in the per-day, per-game booking queue.
/// Firestore path: club_days/{YYYY-MM-DD}/game_sessions/{gameId}/booking_queue/{docId}
class BookingQueueEntry {
  final String id;
  final String childId;
  final String childName;
  final String childShortId;
  final DateTime bookedAt;
  final String status; // "waiting" | "played"

  const BookingQueueEntry({
    required this.id,
    required this.childId,
    required this.childName,
    required this.childShortId,
    required this.bookedAt,
    this.status = 'waiting',
  });

  factory BookingQueueEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final ts = data['bookedAt'];
    return BookingQueueEntry(
      id: doc.id,
      childId: (data['childId'] ?? '').toString(),
      childName: (data['childName'] ?? '').toString(),
      childShortId: (data['childShortId'] ?? '').toString(),
      bookedAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
      status: (data['status'] ?? 'waiting').toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'childId': childId,
        'childName': childName,
        'childShortId': childShortId,
        'bookedAt': Timestamp.fromDate(bookedAt),
        'status': status,
      };
}
