/// Attendance status enumeration
enum AttendanceStatus {
  present,
  absent,
  late,
  excused,
}

/// Extension for AttendanceStatus JSON serialization
extension AttendanceStatusExtension on AttendanceStatus {
  String toJson() {
    switch (this) {
      case AttendanceStatus.present:
        return 'P';
      case AttendanceStatus.absent:
        return 'A';
      case AttendanceStatus.late:
        return 'L';
      case AttendanceStatus.excused:
        return 'E';
    }
  }

  static AttendanceStatus fromJson(String? value) {
    switch (value?.toUpperCase()) {
      case 'P':
        return AttendanceStatus.present;
      case 'A':
        return AttendanceStatus.absent;
      case 'L':
        return AttendanceStatus.late;
      case 'E':
        return AttendanceStatus.excused;
      default:
        return AttendanceStatus.absent;
    }
  }
}