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
}
