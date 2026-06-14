import 'package:cloud_firestore/cloud_firestore.dart';

enum SubscriptionRequestStatus { pending, approved }

extension SubscriptionRequestStatusX on SubscriptionRequestStatus {
  String get code => switch (this) {
        SubscriptionRequestStatus.pending => 'pending',
        SubscriptionRequestStatus.approved => 'approved',
      };

  static SubscriptionRequestStatus fromCode(String? value) {
    return SubscriptionRequestStatus.values.firstWhere(
      (e) => e.code == value,
      orElse: () => SubscriptionRequestStatus.pending,
    );
  }

  String get labelAr => switch (this) {
        SubscriptionRequestStatus.pending => 'قيد المراجعة',
        SubscriptionRequestStatus.approved => 'تمت الموافقة',
      };
}

class ClubSubscriptionRequest {
  final String id;
  final String childId;
  final String childName;
  final String childFullName;
  final String childClass;
  final String childShortId;
  final SubscriptionRequestStatus status;
  final DateTime? requestedAt;
  final DateTime? approvedAt;
  final String? approvedBy;

  const ClubSubscriptionRequest({
    required this.id,
    required this.childId,
    required this.childName,
    required this.childFullName,
    required this.childClass,
    required this.childShortId,
    required this.status,
    this.requestedAt,
    this.approvedAt,
    this.approvedBy,
  });

  factory ClubSubscriptionRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ClubSubscriptionRequest(
      id: doc.id,
      childId: data['childId'] ?? '',
      childName: data['childName'] ?? '',
      childFullName: data['childFullName'] ?? '',
      childClass: data['childClass'] ?? '',
      childShortId: data['childShortId'] ?? '',
      status: SubscriptionRequestStatusX.fromCode(data['status']),
      requestedAt: (data['requestedAt'] as Timestamp?)?.toDate(),
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
      approvedBy: data['approvedBy'],
    );
  }

  Map<String, dynamic> toMap() => {
        'childId': childId,
        'childName': childName,
        'childFullName': childFullName,
        'childClass': childClass,
        'childShortId': childShortId,
        'status': status.code,
        if (requestedAt != null) 'requestedAt': Timestamp.fromDate(requestedAt!),
        if (approvedAt != null) 'approvedAt': Timestamp.fromDate(approvedAt!),
        if (approvedBy != null) 'approvedBy': approvedBy,
      };
}
