import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:church/core/models/attendance/visit_model.dart';
import 'package:church/core/repositories/visit_repository.dart';
import 'visit_states.dart';

class VisitCubit extends Cubit<VisitState> {
  final VisitRepository _repository;

  VisitCubit({VisitRepository? repository})
      : _repository = repository ?? VisitRepository(),
        super(VisitInitial());

  static VisitCubit of(context) => BlocProvider.of<VisitCubit>(context);

  /// Create or merge a visit: if a visit exists for the same child/day/type,
  /// servants are merged (arrayUnion). Returns the visit id.
  Future<String> createOrMergeVisit(VisitModel visit) async {
    try {
      emit(VisitLoading());
      final id = await _repository.addOrMergeVisit(visit);
      emit(CreateVisitSuccess(id));
      return id;
    } catch (e) {
      final msg = e.toString();
      emit(VisitError(msg));
      rethrow;
    }
  }

  /// Add a single servant to an existing visit by id
  Future<void> addServantToVisit({
    required String visitId,
    required String servantId,
    required String servantName,
  }) async {
    try {
      emit(VisitLoading());
      await _repository.addServantToVisit(
        visitId: visitId,
        servantId: servantId,
        servantName: servantName,
      );
      emit(AddServantSuccess());
    } catch (e) {
      emit(VisitError(e.toString()));
      rethrow;
    }
  }

  /// Stream visits for a child for UI views
  Stream<List<VisitModel>> getVisitsForChild(String childId) {
    emit(GetChildVisitsLoading());
    return _repository.getVisitsByChildIdStream(childId).map((visits) {
      emit(GetChildVisitsSuccess(visits));
      return visits;
    }).handleError((e) {
      emit(GetChildVisitsError(e.toString()));
    });
  }
}

