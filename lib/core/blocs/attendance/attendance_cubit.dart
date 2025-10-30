import 'package:church/core/repositories/visit_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:church/core/repositories/users_reopsitory.dart';
import 'package:church/core/repositories/attendance_repository.dart';
import 'package:church/core/models/user/user_model.dart';
import 'package:church/core/models/attendance/attendance_model.dart';

import '../../models/attendance/visit_model.dart';
import 'attendance_states.dart';

class AttendanceCubit extends Cubit<AttendanceState> {
  final UsersRepository usersRepository;
  final AttendanceRepository attendanceRepository;
  final VisitRepository visitRepository;

  AttendanceCubit({
    UsersRepository? usersRepository,
    AttendanceRepository? attendanceRepository,
    VisitRepository? visitRepository,
  }) : usersRepository = usersRepository ?? UsersRepository(),
       attendanceRepository = attendanceRepository ?? AttendanceRepository(),
       visitRepository = visitRepository ?? VisitRepository(),
       super(AttendanceInitial());

  static AttendanceCubit get(context) => BlocProvider.of(context);

  UserModel? currentUser;

  List<UserModel>? users;
  List<AttendanceModel>? attendanceHistory;

  // Get current user as a stream
  Stream<UserModel?> getCurrentUser(String userId) {
    emit(getAllUsersLoading());
    return usersRepository.getUserByIdStream(userId).map((user) {
      if (user != null) {
        currentUser = user;
        emit(getAllUsersSuccess());
      }
      return user;
    }).handleError((e) {
      emit(getAllUsersError(e.toString()));
    });
  }

  // Get users by type
  Stream<List<UserModel>?> getUsersByType(
    String userClass,
    List<String> userTypes, String gender
  ) {
    emit(getAllUsersLoading());
    return usersRepository
        .getUsersByMultipleTypes(userClass, userTypes, gender)
        .map((fetchedUsers) {
          users = fetchedUsers;
          debugPrint(users.toString());
          emit(getAllUsersSuccess());
          return users;
        })
        .handleError((e) {
          emit(getAllUsersError(e.toString()));
          debugPrint(e.toString());
        });
  }

  // Get users by type and gender
  Stream<List<UserModel>?> getUsersByTypeAndGender(
      List<String> userTypes, String gender
      ) {
    emit(getAllUsersLoading());
    return usersRepository
        .getUsersByMultipleTypesAndGender(userTypes, gender)
        .map((fetchedUsers) {
          users = fetchedUsers;
          debugPrint(users.toString());
          emit(getAllUsersSuccess());
          return users;
        })
        .handleError((e) {
          emit(getAllUsersError(e.toString()));
          debugPrint(e.toString());
        });
  }


  // Get users for priest
  Stream<List<UserModel>?> getUsersByTypeForPriest(
      List<String> userTypes
      ) {
    emit(getAllUsersLoading());
    return usersRepository
        .getUsersByMultipleTypesForPriest(userTypes)
        .map((fetchedUsers) {
          users = fetchedUsers;
          debugPrint(users.toString());
          emit(getAllUsersSuccess());
          return users;
        })
        .handleError((e) {
          emit(getAllUsersError(e.toString()));
          debugPrint(e.toString());
        });
  }


  // Get Attendance History for a specific user by user ID
  Stream<List<AttendanceModel>> getUserAttendanceHistory(String userId) {
    emit(getUserAttendanceHistoryLoading());
    return attendanceRepository
        .getAttendanceByUserIdStream(userId)
        .map((history) {
          attendanceHistory = history;
          emit(getUserAttendanceHistorySuccess());
          return history;
        })
        .handleError((e) {
          emit(getUserAttendanceHistoryError(e.toString()));
        });
  }

  // Take attendance for a user
  Future<String> takeAttendance(AttendanceModel attendance) async {
    try {
      emit(takeAttendanceLoading());

      // Check if attendance already exists for this user on this date
      final existingAttendance = await attendanceRepository
          .getAttendanceByUserAndDate(attendance.userId, attendance.date);

      if (existingAttendance != null) {
        // Update existing attendance
        await attendanceRepository.updateAttendance(
          existingAttendance.id,
          attendance.toMap(),
        );
        emit(takeAttendanceSuccess());
        return existingAttendance.id;
      } else {
        // Add new attendance record
        final docId = await attendanceRepository.addAttendance(attendance);
        emit(takeAttendanceSuccess());
        return docId;
      }
    } catch (e) {
      emit(takeAttendanceError(e.toString()));
      rethrow;
    }
  }

  // Batch take attendance for multiple users
  Future<void> batchTakeAttendance(List<AttendanceModel> attendanceList) async {
    try {
      emit(takeAttendanceLoading());

      await attendanceRepository.batchAddAttendance(attendanceList);

      emit(takeAttendanceSuccess());
    } catch (e) {
      emit(takeAttendanceError(e.toString()));
      rethrow;
    }
  }


  ///=====================================================Visit Functions=====================================================

  /// Create or merge a visit: if a visit exists for the same child/day/type,
  /// servants are merged (arrayUnion). Returns the visit id.
  Future<String> createOrMergeVisit(VisitModel visit) async {
    try {
      emit(VisitLoading());
      final id = await visitRepository.addOrMergeVisit(visit);
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
      await visitRepository.addServantToVisit(
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
  /// Note: No state emissions here since StreamBuilder handles loading/success/error states
  Stream<List<VisitModel>> getVisitsForChild(String childId) {
    return visitRepository.getVisitsByChildIdStream(childId);
  }






}
