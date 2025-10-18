import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:church/core/repositories/users_reopsitory.dart';
import 'package:church/core/repositories/attendance_repository.dart';
import 'package:church/core/models/user/user_model.dart';
import 'package:church/core/models/attendance/attendance_model.dart';

import 'attendance_states.dart';

class AttendanceCubit extends Cubit<AttendanceState> {
  final UsersRepository usersRepository;
  final AttendanceRepository attendanceRepository;

  AttendanceCubit({
    UsersRepository? usersRepository,
    AttendanceRepository? attendanceRepository,
  }) : usersRepository = usersRepository ?? UsersRepository(),
       attendanceRepository = attendanceRepository ?? AttendanceRepository(),
       super(AttendanceInitial());

  static AttendanceCubit get(context) => BlocProvider.of(context);

  late final UserModel currentUser;

  List<UserModel>? users;
  List<AttendanceModel>? attendanceHistory;

  // Get current user
  Future<UserModel?> getCurrentUser(String userId) async {
    emit(getAllUsersLoading());
    try {
      currentUser = await usersRepository
          .getUserById(userId);
      emit(getAllUsersSuccess());
      return users!.isNotEmpty ? users!.first : null;
    } catch (e) {
      emit(getAllUsersError(e.toString()));
      print(e);
      rethrow;
    }
  }

  // Get users by type
  Future<List<UserModel>?> getUsersByType(
    String userClass,
    List<String> userTypes, String gender
  ) async {
    emit(getAllUsersLoading());
    try {
      users = await usersRepository
          .getUsersByMultipleTypes(userClass, userTypes, gender).first;
      emit(getAllUsersSuccess());
      debugPrint(users.toString());
      return users;
    } catch (e) {
      emit(getAllUsersError(e.toString()));
      print(e);
      rethrow;
    }
  }

  // Get users by type and gender
  Future<List<UserModel>?> getUsersByTypeAndGender(
      List<String> userTypes, String gender
      ) async {
    emit(getAllUsersLoading());
    try {
      users = await usersRepository
          .getUsersByMultipleTypesAndGender(userTypes, gender).first;
      emit(getAllUsersSuccess());
      debugPrint(users.toString());
      return users;
    } catch (e) {
      emit(getAllUsersError(e.toString()));
      print(e);
      rethrow;
    }
  }


  // Get users for priest
  Future<List<UserModel>?> getUsersByTypeForPriest(
      List<String> userTypes
      ) async {
    emit(getAllUsersLoading());
    try {
      users = await usersRepository
          .getUsersByMultipleTypesForPriest(userTypes).first;
      emit(getAllUsersSuccess());
      debugPrint(users.toString());
      return users;
    } catch (e) {
      emit(getAllUsersError(e.toString()));
      print(e);
      rethrow;
    }
  }


  // Get Attendance History for a specific user by user ID
  Future<List<AttendanceModel>> getUserAttendanceHistory(String userId) async {
    try {
      emit(getUserAttendanceHistoryLoading());

      attendanceHistory = await attendanceRepository
          .getAttendanceByUserIdFuture(userId);

      emit(getUserAttendanceHistorySuccess());

      return attendanceHistory!;
    } catch (e) {
      emit(getUserAttendanceHistoryError(e.toString()));
      rethrow;
    }
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
}
