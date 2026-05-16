import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { added, subtracted }

class CoinTransaction {
  final String id;
  final int amount;
  final TransactionType type;
  final String reason;
  final DateTime timestamp;

  const CoinTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.reason,
    required this.timestamp,
  });

  factory CoinTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CoinTransaction(
      id: doc.id,
      amount: (data['amount'] as num?)?.toInt() ?? 0,
      type: (data['type'] == 'added')
          ? TransactionType.added
          : TransactionType.subtracted,
      reason: data['reason'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'amount': amount,
        'type': type == TransactionType.added ? 'added' : 'subtracted',
        'reason': reason,
        'timestamp': Timestamp.fromDate(timestamp),
      };
}
