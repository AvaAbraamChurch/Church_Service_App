import 'package:cloud_firestore/cloud_firestore.dart';

/// Attendance request created by a child and reviewed by priest/super-servant/servant.
/// Stored in Firestore collection: `attendance_requests`.
class AttendanceRequestModel {
  final String id;
  final String childId;
  final String childName;
  final String childClass;
  final String childGender; // stored as json string (see gender_enum helpers)

  /// One of: holy_mass, sunday_school, hymns, bible
  final String attendanceKey;

  /// Date requested (day precision).
  final DateTime requestedDate;

  /// pending | accepted | declined
  final String status;

  final DateTime createdAt;
  final DateTime? updatedAt;

  final String? reviewedById;
  final String? reviewedByName;
  final String? decisionReason;
  final String? linkedAttendanceId;

  const AttendanceRequestModel({
    required this.id,
    required this.childId,
    required this.childName,
    required this.childClass,
    required this.childGender,
    required this.attendanceKey,
    required this.requestedDate,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.reviewedById,
    this.reviewedByName,
    this.decisionReason,
    this.linkedAttendanceId,
  });

  bool get isPending => status == 'pending';

  Map<String, dynamic> toMap() {
    final day = DateTime(requestedDate.year, requestedDate.month, requestedDate.day);

    return {
      'childId': childId,
      'childName': childName,
      'childClass': childClass,
      'childGender': childGender,
      'attendanceKey': attendanceKey,
      'requestedDate': Timestamp.fromDate(day),
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      if (reviewedById != null) 'reviewedById': reviewedById,
      if (reviewedByName != null) 'reviewedByName': reviewedByName,
      if (decisionReason != null) 'decisionReason': decisionReason,
      if (linkedAttendanceId != null) 'linkedAttendanceId': linkedAttendanceId,
    };
  }

  factory AttendanceRequestModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};

    DateTime _asDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    return AttendanceRequestModel(
      id: doc.id,
      childId: (data['childId'] ?? '').toString(),
      childName: (data['childName'] ?? '').toString(),
      childClass: (data['childClass'] ?? '').toString(),
      childGender: (data['childGender'] ?? '').toString(),
      attendanceKey: (data['attendanceKey'] ?? '').toString(),
      requestedDate: _asDate(data['requestedDate']),
      status: (data['status'] ?? 'pending').toString(),
      createdAt: _asDate(data['createdAt']),
      updatedAt: data['updatedAt'] == null ? null : _asDate(data['updatedAt']),
      reviewedById: data['reviewedById']?.toString(),
      reviewedByName: data['reviewedByName']?.toString(),
      decisionReason: data['decisionReason']?.toString(),
      linkedAttendanceId: data['linkedAttendanceId']?.toString(),
    );
  }
}
