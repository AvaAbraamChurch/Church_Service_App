import '../../utils/userType_enum.dart';
import '../../utils/attendance_enum.dart';

/// Immutable attendance model representing user attendance records.
///
/// Fields:
/// - id (document id)
/// - userId (reference to user)
/// - userName (for display purposes)
/// - userType (enum - priest, sister, servant, child)
/// - date (attendance date)
/// - status (enum - present, absent, late, excused)
/// - checkInTime (optional - when user checked in)
/// - checkOutTime (optional - when user checked out)
/// - notes (optional - additional notes)
/// - attendanceType (optional - specific event/service reference)
/// - recordedBy (optional - who recorded the attendance)
/// - createdAt (when record was created)
class AttendanceModel {
  final String id;
  final String userId;
  final String userName;
  final UserType userType;
  final DateTime date;
  final AttendanceStatus status;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String? notes;
  final String? attendanceType;
  final String? recordedBy;
  final DateTime createdAt;

  const AttendanceModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userType,
    required this.date,
    required this.status,
    this.checkInTime,
    this.checkOutTime,
    this.notes,
    this.attendanceType,
    this.recordedBy,
    required this.createdAt,
  });

  AttendanceModel copyWith({
    String? id,
    String? userId,
    String? userName,
    UserType? userType,
    DateTime? date,
    AttendanceStatus? status,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    String? notes,
    String? attendanceType,
    String? recordedBy,
    DateTime? createdAt,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userType: userType ?? this.userType,
      date: date ?? this.date,
      status: status ?? this.status,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      notes: notes ?? this.notes,
      attendanceType: attendanceType ?? this.attendanceType,
      recordedBy: recordedBy ?? this.recordedBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // JSON/Map helpers (Firestore-friendly)
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userType': userTypeToJson(userType),
      'date': date.toIso8601String(),
      'status': status.toJson(),
      if (checkInTime != null) 'checkInTime': checkInTime!.toIso8601String(),
      if (checkOutTime != null) 'checkOutTime': checkOutTime!.toIso8601String(),
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      if (attendanceType != null) 'attendanceType': attendanceType,
      if (recordedBy != null) 'recordedBy': recordedBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AttendanceModel.fromMap(Map<String, dynamic>? map, {required String id}) {
    final data = map ?? const <String, dynamic>{};
    return AttendanceModel(
      id: id,
      userId: (data['userId'] ?? '').toString(),
      userName: (data['userName'] ?? data['name'] ?? '').toString(),
      userType: userTypeFromJson(data['userType']),
      date: _parseDateTime(data['date']) ?? DateTime.now(),
      status: AttendanceStatusExtension.fromJson(data['status']?.toString()),
      checkInTime: _parseDateTime(data['checkInTime']),
      checkOutTime: _parseDateTime(data['checkOutTime']),
      notes: data['notes']?.toString(),
      attendanceType: data['attendanceType']?.toString(),
      recordedBy: data['recordedBy']?.toString(),
      createdAt: _parseDateTime(data['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        ...toMap(),
      };

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel.fromMap(json, id: (json['id'] ?? '').toString());
  }

  /// Helper method to parse DateTime from various formats
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    // Handle Firestore Timestamp if needed
    if (value is Map && value.containsKey('_seconds')) {
      return DateTime.fromMillisecondsSinceEpoch(value['_seconds'] * 1000);
    }
    return null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AttendanceModel &&
        other.id == id &&
        other.userId == userId &&
        other.userName == userName &&
        other.userType == userType &&
        other.date == date &&
        other.status == status &&
        other.checkInTime == checkInTime &&
        other.checkOutTime == checkOutTime &&
        other.notes == notes &&
        other.attendanceType == attendanceType &&
        other.recordedBy == recordedBy &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      userName,
      userType,
      date,
      status,
      checkInTime,
      checkOutTime,
      notes,
      attendanceType,
      recordedBy,
      createdAt,
    );
  }

  @override
  String toString() {
    return 'AttendanceModel(id: $id, userId: $userId, userName: $userName, userType: $userType, date: $date, status: $status)';
  }
}

