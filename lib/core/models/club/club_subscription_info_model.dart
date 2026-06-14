import 'package:cloud_firestore/cloud_firestore.dart';

class ClubSubscriptionInfo {
  static const String docId = 'main';

  final String id;
  final String title;
  final String description;
  final DateTime? updatedAt;
  final String? updatedBy;

  const ClubSubscriptionInfo({
    required this.id,
    required this.title,
    required this.description,
    this.updatedAt,
    this.updatedBy,
  });

  factory ClubSubscriptionInfo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ClubSubscriptionInfo(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      updatedBy: data['updatedBy'],
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
        if (updatedBy != null) 'updatedBy': updatedBy,
      };
}

