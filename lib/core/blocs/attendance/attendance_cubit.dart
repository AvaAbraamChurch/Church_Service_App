import 'package:church/core/repositories/visit_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:church/core/repositories/users_reopsitory.dart';
import 'package:church/core/repositories/attendance_repository.dart';
import 'package:church/core/models/user/user_model.dart';
import 'package:church/core/models/attendance/attendance_model.dart';

import '../../models/attendance/visit_model.dart';
import 'attendance_states.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'dart:convert';
import '../../repositories/local_attendance_repository.dart';

class AttendanceCubit extends Cubit<AttendanceState> {
  final UsersRepository usersRepository;
  final AttendanceRepository attendanceRepository;
  final VisitRepository visitRepository;

  // Local repo to queue attendance when offline
  final LocalAttendanceRepository _localRepo = LocalAttendanceRepository();
  // Use a dynamic subscription type to avoid platform-dependent stream type mismatches
  StreamSubscription<dynamic>? _connectivitySub;

  // Cached state for UI consumers
  UserModel? currentUser;
  List<UserModel>? users;
  List<AttendanceModel>? attendanceHistory;

  AttendanceCubit({
    UsersRepository? usersRepository,
    AttendanceRepository? attendanceRepository,
    VisitRepository? visitRepository,
  }) : usersRepository = usersRepository ?? UsersRepository(),
       attendanceRepository = attendanceRepository ?? AttendanceRepository(),
       visitRepository = visitRepository ?? VisitRepository(),
       super(AttendanceInitial()) {
    // start listening for connectivity changes
    initOfflineSupport();
  }

  static AttendanceCubit get(context) => BlocProvider.of(context);

  // Call from dispose if you manually close the cubit
  Future<void> disposeOfflineSupport() async {
    await _connectivitySub?.cancel();
  }

  void initOfflineSupport() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((status) async {
      if (status != ConnectivityResult.none) {
        await syncPendingAttendances();
      }
    });
  }

  Future<bool> _hasNetwork() async {
    final c = await Connectivity().checkConnectivity();
    return c != ConnectivityResult.none;
  }

  /// Public method to check network status (for UI)
  Future<bool> checkNetwork() async {
    return await _hasNetwork();
  }

  /// Offline-aware attendance save. If offline, save to Hive and return a local key
  Future<String> takeAttendanceOfflineAware(AttendanceModel attendance) async {
    try {
      final online = await _hasNetwork();
      if (!online) {
        final key = await _localRepo.savePendingAttendance(attendance);
        // emit success as local save
        emit(takeAttendanceSuccess());
        return 'local_$key';
      }

      // Online: use existing takeAttendance method
      return await takeAttendance(attendance);
    } catch (e) {
      emit(takeAttendanceError(e.toString()));
      rethrow;
    }
  }

  /// Attempt to sync pending items from Hive to Firestore
  Future<void> syncPendingAttendances() async {
    final pending = _localRepo.getPendingAttendances();
    if (pending.isEmpty) return;

    emit(takeAttendanceLoading());
    for (final row in pending) {
      try {
        final payloadStr = row['payload'] as String;
        final decoded = jsonDecode(payloadStr) as Map<String, dynamic>;
        final attendance = AttendanceModel.fromJson(decoded);

        final existing = await attendanceRepository.getAttendanceByUserAndDate(attendance.userId, attendance.date);
        if (existing != null) {
          await attendanceRepository.updateAttendance(existing.id, attendance.toMap());
        } else {
          await attendanceRepository.addAttendance(attendance);
        }

        await _localRepo.deletePending(row['key']);
      } catch (e) {
        // skip and try next; don't remove from local store
        continue;
      }
    }
    emit(takeAttendanceSuccess());
  }

  /// Get count of pending (offline) attendance items
  int getPendingCount() {
    return _localRepo.getPendingAttendances().length;
  }

  /// Manually trigger sync (for UI button)
  Future<void> manualSync() async {
    await syncPendingAttendances();
  }

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
    // First check connectivity. If offline, queue locally and return a local id.
    try {
      emit(takeAttendanceLoading());

      final online = await _hasNetwork();
      if (!online) {
        final key = await _localRepo.savePendingAttendance(attendance);
        emit(takeAttendanceSuccess());
        return 'local_$key';
      }

      // We're online: attempt normal server upsert (check by user+date)
      try {
        final existingAttendance = await attendanceRepository
            .getAttendanceByUserAndDate(attendance.userId, attendance.date);

        if (existingAttendance != null) {
          await attendanceRepository.updateAttendance(
            existingAttendance.id,
            attendance.toMap(),
          );
          emit(takeAttendanceSuccess());
          return existingAttendance.id;
        } else {
          final docId = await attendanceRepository.addAttendance(attendance);
          emit(takeAttendanceSuccess());
          return docId;
        }
      } catch (networkError) {
        // If any network/upload error occurs, save locally for later sync
        try {
          final key = await _localRepo.savePendingAttendance(attendance);
          emit(takeAttendanceSuccess());
          return 'local_$key';
        } catch (saveError) {
          emit(takeAttendanceError(saveError.toString()));
          rethrow;
        }
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

      final online = await _hasNetwork();
      if (!online) {
        // Save all items locally
        for (final attendance in attendanceList) {
          await _localRepo.savePendingAttendance(attendance);
        }
        emit(takeAttendanceSuccess());
        return;
      }

      // We're online: attempt normal batch upload
      try {
        await attendanceRepository.batchAddAttendance(attendanceList);
        emit(takeAttendanceSuccess());
      } catch (networkError) {
        // If batch upload fails, save all items locally for later sync
        for (final attendance in attendanceList) {
          await _localRepo.savePendingAttendance(attendance);
        }
        emit(takeAttendanceSuccess());
      }
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
