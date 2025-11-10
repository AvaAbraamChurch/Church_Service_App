abstract class AttendanceState {}

// Initial state
class AttendanceInitial extends AttendanceState {}

// ==================== User States ====================
class getAllUsersLoading extends AttendanceState {}

class getAllUsersSuccess extends AttendanceState {}

class getAllUsersError extends AttendanceState {
  final String error;
  getAllUsersError(this.error);
}

// ==================== Attendance History States ====================
class getUserAttendanceHistoryLoading extends AttendanceState {}

class getUserAttendanceHistorySuccess extends AttendanceState {}

class getUserAttendanceHistoryError extends AttendanceState {
  final String error;
  getUserAttendanceHistoryError(this.error);
}

// ==================== Take Attendance States ====================
class takeAttendanceLoading extends AttendanceState {}

class takeAttendanceSuccess extends AttendanceState {}

class takeAttendanceSuccessOffline extends AttendanceState {
  final int pendingCount;
  takeAttendanceSuccessOffline(this.pendingCount);
}

class takeAttendanceError extends AttendanceState {
  final String error;
  takeAttendanceError(this.error);
}

// ==================== Sync States ====================
class OfflineModeActive extends AttendanceState {
  final int pendingCount;
  OfflineModeActive(this.pendingCount);
}

class SyncInProgress extends AttendanceState {
  final int totalItems;
  SyncInProgress(this.totalItems);
}

class SyncComplete extends AttendanceState {
  final int syncedCount;
  final DateTime syncTime;
  SyncComplete(this.syncedCount, this.syncTime);
}

class SyncPartiallyComplete extends AttendanceState {
  final int syncedCount;
  final int failedCount;
  final DateTime syncTime;
  SyncPartiallyComplete(this.syncedCount, this.failedCount, this.syncTime);
}

class SyncError extends AttendanceState {
  final String error;
  final int failedCount;
  SyncError(this.error, this.failedCount);
}

// ==================== Visit States ====================
class VisitLoading extends AttendanceState {}

class CreateVisitSuccess extends AttendanceState {
  final String visitId;
  CreateVisitSuccess(this.visitId);
}

class AddServantSuccess extends AttendanceState {}

class VisitError extends AttendanceState {
  final String error;
  VisitError(this.error);
}