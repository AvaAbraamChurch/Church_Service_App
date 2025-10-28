import 'package:church/core/models/attendance/visit_model.dart';

abstract class VisitState {}

class VisitInitial extends VisitState {}

class VisitLoading extends VisitState {}

class VisitError extends VisitState {
  final String message;
  VisitError(this.message);
}

// Creation / merge
class CreateVisitSuccess extends VisitState {
  final String visitId;
  CreateVisitSuccess(this.visitId);
}

// Add servant to visit
class AddServantSuccess extends VisitState {}

// Fetch visits for child
class GetChildVisitsLoading extends VisitState {}

class GetChildVisitsSuccess extends VisitState {
  final List<VisitModel> visits;
  GetChildVisitsSuccess(this.visits);
}

class GetChildVisitsError extends VisitState {
  final String message;
  GetChildVisitsError(this.message);
}

