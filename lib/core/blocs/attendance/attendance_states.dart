import '../../models/attendance/visit_model.dart';

abstract class AttendanceState {}

class AttendanceInitial extends AttendanceState {}

class AttendanceLoading extends AttendanceState {}

class AttendanceSuccess extends AttendanceState {}

class AttendanceError extends AttendanceState {
  final String error;

  AttendanceError(this.error);
}

class getAttendanceLoading extends AttendanceState {}

class getAttendanceSuccess extends AttendanceState {}

class getAttendanceError extends AttendanceState {
  final String error;

  getAttendanceError(this.error);
}

class getAttendanceByDateLoading extends AttendanceState {}

class getAttendanceByDateSuccess extends AttendanceState {}

class getAttendanceByDateError extends AttendanceState {
  final String error;

  getAttendanceByDateError(this.error);
}

class getAttendanceByMonthLoading extends AttendanceState {}

class getAttendanceByMonthSuccess extends AttendanceState {}

class getAttendanceByMonthError extends AttendanceState {
  final String error;

  getAttendanceByMonthError(this.error);
}

class getChildrenLoading extends AttendanceState {}

class getChildrenSuccess extends AttendanceState {}

class getChildrenError extends AttendanceState {
  final String error;

  getChildrenError(this.error);
}

class getServantsLoading extends AttendanceState {}

class getServantsSuccess extends AttendanceState {}

class getServantsError extends AttendanceState {
  final String error;

  getServantsError(this.error);
}

class getSuperServantsLoading extends AttendanceState {}

class getSuperServantsSuccess extends AttendanceState {}

class getSuperServantsError extends AttendanceState {
  final String error;

  getSuperServantsError(this.error);
}

class getAllUsersLoading extends AttendanceState {}

class getAllUsersSuccess extends AttendanceState {}

class getAllUsersError extends AttendanceState {
  final String error;

  getAllUsersError(this.error);
}

// Get user attendance history states
class getUserAttendanceHistoryLoading extends AttendanceState {}

class getUserAttendanceHistorySuccess extends AttendanceState {}

class getUserAttendanceHistoryError extends AttendanceState {
  final String error;

  getUserAttendanceHistoryError(this.error);
}

// Take attendance states
class takeAttendanceLoading extends AttendanceState {}

class takeAttendanceSuccess extends AttendanceState {}

class takeAttendanceError extends AttendanceState {
  final String error;

  takeAttendanceError(this.error);
}

class VisitLoading extends AttendanceState {}

class VisitError extends AttendanceState {
  final String message;
  VisitError(this.message);
}

// Creation / merge
class CreateVisitSuccess extends AttendanceState {
  final String visitId;
  CreateVisitSuccess(this.visitId);
}

// Add servant to visit
class AddServantSuccess extends AttendanceState {}

// Fetch visits for child
class GetChildVisitsLoading extends AttendanceState {}

class GetChildVisitsSuccess extends AttendanceState {
  final List<VisitModel> visits;
  GetChildVisitsSuccess(this.visits);
}

class GetChildVisitsError extends AttendanceState {
  final String message;
  GetChildVisitsError(this.message);
}




