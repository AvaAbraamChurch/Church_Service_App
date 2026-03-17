import 'package:church/core/repositories/visit_repository.dart';
import 'package:church/core/repositories/attendance_defaults_repository.dart';
import 'package:church/core/services/coupon_points_service.dart';
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
import 'package:church/core/utils/userType_enum.dart';
import 'package:church/core/utils/attendance_enum.dart';
import 'package:church/core/repositories/attendance_requests_repository.dart';
import 'package:church/core/models/attendance/attendance_request_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:church/core/constants/strings.dart';
import 'package:church/core/utils/gender_enum.dart';

class AttendanceCubit extends Cubit<AttendanceState> {
  final UsersRepository usersRepository;
  final AttendanceRepository attendanceRepository;
  final VisitRepository visitRepository;
  final AttendanceRequestsRepository attendanceRequestsRepository;
  final AttendanceDefaultsRepository attendanceDefaultsRepository;
  final CouponPointsService couponPointsService;
  final LocalAttendanceRepository _localRepo = LocalAttendanceRepository();

  StreamSubscription<dynamic>? _connectivitySub;
  Timer? _autoSyncTimer;

  // Cached state for UI consumers
  UserModel? currentUser;
  List<UserModel>? users;
  List<AttendanceModel>? attendanceHistory;

  // Track sync status
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  int _syncErrorCount = 0;

  AttendanceCubit({
    UsersRepository? usersRepository,
    AttendanceRepository? attendanceRepository,
    VisitRepository? visitRepository,
    AttendanceRequestsRepository? attendanceRequestsRepository,
    AttendanceDefaultsRepository? attendanceDefaultsRepository,
    CouponPointsService? couponPointsService,
  })  : usersRepository = usersRepository ?? UsersRepository(),
        attendanceRepository = attendanceRepository ?? AttendanceRepository(),
        visitRepository = visitRepository ?? VisitRepository(),
        attendanceRequestsRepository =
            attendanceRequestsRepository ?? AttendanceRequestsRepository(),
        attendanceDefaultsRepository =
            attendanceDefaultsRepository ?? AttendanceDefaultsRepository(),
        couponPointsService = couponPointsService ?? CouponPointsService(),
        super(AttendanceInitial()) {
    initOfflineSupport();
  }

  static AttendanceCubit get(context) => BlocProvider.of(context);

  // Getters for sync status
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  int get syncErrorCount => _syncErrorCount;

  @override
  Future<void> close() async {
    await disposeOfflineSupport();
    return super.close();
  }

  Future<void> disposeOfflineSupport() async {
    await _connectivitySub?.cancel();
    _autoSyncTimer?.cancel();
  }

  void initOfflineSupport() {
    // Listen for connectivity changes
    _connectivitySub = Connectivity().onConnectivityChanged.listen((dynamic status) async {
      List<ConnectivityResult> toList(dynamic v) {
        if (v is List<ConnectivityResult>) return v;
        if (v is ConnectivityResult) return <ConnectivityResult>[v];
        return const <ConnectivityResult>[];
      }

      final results = toList(status);
      final isOnline = results.isNotEmpty && !results.contains(ConnectivityResult.none);

      if (isOnline) {
        await syncPendingAttendances();
      } else {
        emit(OfflineModeActive(getPendingCount()));
      }
    });

    // Auto-sync every 5 minutes when online
    _autoSyncTimer = Timer.periodic(Duration(minutes: 5), (timer) async {
      final online = await _hasNetwork();
      if (online && getPendingCount() > 0 && !_isSyncing) {
        await syncPendingAttendances();
      }
    });

    // Try initial sync on startup
    Future.delayed(Duration(seconds: 2), () async {
      final online = await _hasNetwork();
      if (online && getPendingCount() > 0) {
        await syncPendingAttendances();
      }
    });
  }

  Future<bool> _hasNetwork() async {
    try {
      final results = await Connectivity().checkConnectivity();
      return !results.contains(ConnectivityResult.none);
    } catch (e) {
      return false;
    }
  }

  Future<bool> checkNetwork() async {
    return await _hasNetwork();
  }

  /// Enhanced sync with better error handling and progress tracking
  Future<SyncResult> syncPendingAttendances() async {
    if (_isSyncing) {
      return SyncResult(
        success: false,
        message: 'Sync already in progress',
        syncedCount: 0,
        failedCount: 0,
      );
    }

    final pending = _localRepo.getPendingAttendances();
    if (pending.isEmpty) {
      return SyncResult(
        success: true,
        message: 'No pending items to sync',
        syncedCount: 0,
        failedCount: 0,
      );
    }

    _isSyncing = true;
    emit(SyncInProgress(pending.length));

    int successCount = 0;
    int failureCount = 0;
    final failedItems = <Map<String, dynamic>>[];

    for (final row in pending) {
      try {
        final payloadStr = row['payload'] as String;
        final decoded = jsonDecode(payloadStr) as Map<String, dynamic>;
        final attendance = AttendanceModel.fromJson(decoded);

        // Check if attendance already exists
        final existing = await attendanceRepository.getAttendanceByUserAndDate(
          attendance.userId,
          attendance.date,
        );

        if (existing != null) {
          await attendanceRepository.updateAttendance(
            existing.id,
            attendance.toMap(),
          );
        } else {
          await attendanceRepository.addAttendance(attendance);
        }

        // Successfully synced, remove from local storage
        await _localRepo.deletePending(row['key']);
        successCount++;

      } catch (e) {
        failureCount++;
        failedItems.add(row);
        // Don't remove from local storage - keep for retry
      }
    }

    _isSyncing = false;
    _lastSyncTime = DateTime.now();
    _syncErrorCount = failureCount;

    final result = SyncResult(
      success: failureCount == 0,
      message: failureCount == 0
          ? 'ØªÙ…Øª Ù…Ø²Ø§Ù…Ù†Ø© Ø¬Ù…ÙŠØ¹ Ø§Ù„Ø¨ÙŠØ§Ù†Ø§Øª ($successCount)'
          : 'ØªÙ…Øª Ù…Ø²Ø§Ù…Ù†Ø© $successCountØŒ ÙØ´Ù„ $failureCount',
      syncedCount: successCount,
      failedCount: failureCount,
    );

    if (result.success) {
      emit(SyncComplete(successCount, _lastSyncTime!));
    } else {
      emit(SyncPartiallyComplete(successCount, failureCount, _lastSyncTime!));
    }

    return result;
  }

  int getPendingCount() {
    return _localRepo.getPendingAttendances().length;
  }

  Future<SyncResult> manualSync() async {
    final online = await _hasNetwork();
    if (!online) {
      return SyncResult(
        success: false,
        message: 'Ù„Ø§ ÙŠÙˆØ¬Ø¯ Ø§ØªØµØ§Ù„ Ø¨Ø§Ù„Ø¥Ù†ØªØ±Ù†Øª',
        syncedCount: 0,
        failedCount: getPendingCount(),
      );
    }
    return await syncPendingAttendances();
  }

  /// Offline-aware attendance save with better error handling
  Future<String> takeAttendanceOfflineAware(AttendanceModel attendance) async {
    try {
      emit(takeAttendanceLoading());

      final online = await _hasNetwork();
      if (!online) {
        // Save locally with metadata
        final key = await _localRepo.savePendingAttendance(attendance);
        emit(takeAttendanceSuccessOffline(getPendingCount()));
        return 'local_$key';
      }

      // Try online save
      try {
        final existingAttendance = await attendanceRepository
            .getAttendanceByUserAndDate(attendance.userId, attendance.date);

        String docId;
        if (existingAttendance != null) {
          await attendanceRepository.updateAttendance(
            existingAttendance.id,
            attendance.toMap(),
          );
          docId = existingAttendance.id;
        } else {
          docId = await attendanceRepository.addAttendance(attendance);
        }

        emit(takeAttendanceSuccess());
        return docId;
      } catch (networkError) {
        // Network error during save - fallback to local
        final key = await _localRepo.savePendingAttendance(attendance);
        emit(takeAttendanceSuccessOffline(getPendingCount()));
        return 'local_$key';
      }
    } catch (e) {
      emit(takeAttendanceError(e.toString()));
      rethrow;
    }
  }

  /// Batch take attendance with offline support
  Future<BatchResult> batchTakeAttendance(List<AttendanceModel> attendanceList) async {
    try {
      emit(takeAttendanceLoading());

      final online = await _hasNetwork();
      if (!online) {
        // Save all items locally
        for (final attendance in attendanceList) {
          await _localRepo.savePendingAttendance(attendance);
        }
        emit(takeAttendanceSuccessOffline(getPendingCount()));
        return BatchResult(
          success: true,
          savedCount: attendanceList.length,
          isOffline: true,
        );
      }

      // Try batch upload with timeout
      try {
        await attendanceRepository.batchAddAttendance(attendanceList).timeout(
          Duration(seconds: 3),
          onTimeout: () {
            throw TimeoutException('Firebase operation timed out');
          },
        );
        emit(takeAttendanceSuccess());
        return BatchResult(
          success: true,
          savedCount: attendanceList.length,
          isOffline: false,
        );
      } catch (networkError) {
        // Fallback to local storage
        for (final attendance in attendanceList) {
          await _localRepo.savePendingAttendance(attendance);
        }
        emit(takeAttendanceSuccessOffline(getPendingCount()));
        return BatchResult(
          success: true,
          savedCount: attendanceList.length,
          isOffline: true,
        );
      }
    } catch (e) {
      emit(takeAttendanceError(e.toString()));
      return BatchResult(
        success: false,
        savedCount: 0,
        isOffline: false,
        error: e.toString(),
      );
    }
  }

  // Original method kept for backward compatibility
  Future<String> takeAttendance(AttendanceModel attendance) async {
    return await takeAttendanceOfflineAware(attendance);
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
      List<String> userTypes,
      String gender,
      ) {
    emit(getAllUsersLoading());
    return usersRepository
        .getUsersByMultipleTypes(userClass, userTypes, gender)
        .map((fetchedUsers) {
      users = fetchedUsers;
      emit(getAllUsersSuccess());
      return users;
    }).handleError((e) {
      emit(getAllUsersError(e.toString()));
    });
  }

  // Get users by type and gender
  Stream<List<UserModel>?> getUsersByTypeAndGender(
      List<String> userTypes,
      String gender,
      ) {
    emit(getAllUsersLoading());
    return usersRepository
        .getUsersByMultipleTypesAndGender(userTypes, gender)
        .map((fetchedUsers) {
      users = fetchedUsers;
      emit(getAllUsersSuccess());
      return users;
    }).handleError((e) {
      emit(getAllUsersError(e.toString()));
    });
  }

  // Get users for priest
  Stream<List<UserModel>?> getUsersByTypeForPriest(List<String> userTypes) {
    emit(getAllUsersLoading());
    return usersRepository
        .getUsersByMultipleTypesForPriest(userTypes)
        .map((fetchedUsers) {
      users = fetchedUsers;
      emit(getAllUsersSuccess());
      return users;
    }).handleError((e) {
      emit(getAllUsersError(e.toString()));
    });
  }

  // Get Attendance History for a specific user
  Stream<List<AttendanceModel>> getUserAttendanceHistory(String userId) {
    emit(getUserAttendanceHistoryLoading());
    return attendanceRepository
        .getAttendanceByUserIdStream(userId)
        .map((history) {
      attendanceHistory = history;
      emit(getUserAttendanceHistorySuccess());
      return history;
    }).handleError((e) {
      emit(getUserAttendanceHistoryError(e.toString()));
    });
  }

  // ==================== Visit Functions ====================

  Future<String> createOrMergeVisit(VisitModel visit) async {
    try {
      emit(VisitLoading());

      final online = await _hasNetwork();
      if (!online) {
        // TODO: Implement local visit storage
        emit(VisitError('Ù„Ø§ ÙŠÙˆØ¬Ø¯ Ø§ØªØµØ§Ù„ Ø¨Ø§Ù„Ø¥Ù†ØªØ±Ù†Øª. Ø§Ù„Ø²ÙŠØ§Ø±Ø§Øª ØªØ­ØªØ§Ø¬ Ø§ØªØµØ§Ù„.'));
        throw Exception('No network connection for visits');
      }

      final id = await visitRepository.addOrMergeVisit(visit);
      emit(CreateVisitSuccess(id));
      return id;
    } catch (e) {
      final msg = e.toString();
      emit(VisitError(msg));
      rethrow;
    }
  }

  Future<void> addServantToVisit({
    required String visitId,
    required String servantId,
    required String servantName,
  }) async {
    try {
      emit(VisitLoading());

      final online = await _hasNetwork();
      if (!online) {
        emit(VisitError('Ù„Ø§ ÙŠÙˆØ¬Ø¯ Ø§ØªØµØ§Ù„ Ø¨Ø§Ù„Ø¥Ù†ØªØ±Ù†Øª'));
        throw Exception('No network connection');
      }

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

  Stream<List<VisitModel>> getVisitsForChild(String childId) {
    return visitRepository.getVisitsByChildIdStream(childId);
  }

  // ==================== Utility Methods ====================

  /// Get sync status for UI
  Map<String, dynamic> getSyncStatus() {
    return {
      'isSyncing': _isSyncing,
      'pendingCount': getPendingCount(),
      'lastSyncTime': _lastSyncTime?.toIso8601String(),
      'syncErrorCount': _syncErrorCount,
      'isOnline': _hasNetwork(),
    };
  }

  /// Clear all pending data (use with caution!)
  Future<void> clearPendingData() async {
    try {
      await _localRepo.clearAllPending();
      emit(SyncComplete(0, DateTime.now()));
    } catch (e) {
    }
  }

  Stream<List<AttendanceRequestModel>> streamAttendanceRequestsForChild(String childId) {
    return attendanceRequestsRepository.streamForChild(childId);
  }

  Stream<List<AttendanceRequestModel>> streamPendingAttendanceRequestsForPriest() {
    return attendanceRequestsRepository.streamPendingForPriest();
  }

  Stream<List<AttendanceRequestModel>> streamPendingAttendanceRequestsForSuperServant() {
    final genderJson = currentUser == null ? '' : genderToJson(currentUser!.gender);
    return attendanceRequestsRepository.streamPendingForSuperServant(gender: genderJson);
  }

  Stream<List<AttendanceRequestModel>> streamPendingAttendanceRequestsForServant() {
    final genderJson = currentUser == null ? '' : genderToJson(currentUser!.gender);
    final userClass = currentUser?.userClass ?? '';
    return attendanceRequestsRepository.streamPendingForServant(
      gender: genderJson,
      userClass: userClass,
    );
  }

  /// Submit attendance request for the currently logged-in child.
  /// This creates a document in `attendance_requests` with status=pending.
  Future<void> submitAttendanceRequest({
    required String attendanceKey,
    required DateTime date,
  }) async {
    try {
      if (currentUser == null) {
        throw Exception('Current user not loaded');
      }
      if (currentUser!.userType != UserType.child) {
        throw Exception('Only children can submit attendance requests');
      }

      final day = DateTime(date.year, date.month, date.day);

      final request = AttendanceRequestModel(
        id: '',
        childId: currentUser!.id,
        childName: currentUser!.fullName,
        childClass: currentUser!.userClass,
        childGender: genderToJson(currentUser!.gender),
        attendanceKey: attendanceKey,
        requestedDate: day,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await attendanceRequestsRepository.createRequest(request);
    } catch (e) {
      emit(takeAttendanceError(e.toString()));
      rethrow;
    }
  }

  Future<void> acceptAttendanceRequest(AttendanceRequestModel request) async {
    try {
      if (currentUser == null) {
        throw Exception('Current user not loaded');
      }

      final now = DateTime.now();
      final day = DateTime(
        request.requestedDate.year,
        request.requestedDate.month,
        request.requestedDate.day,
      );

      final attendance = AttendanceModel(
        id: '',
        userId: request.childId,
        userName: request.childName,
        userType: UserType.child,
        date: day,
        attendanceType: _attendanceTypeLabelFromKey(request.attendanceKey),
        status: AttendanceStatus.present,
        checkInTime: now,
        createdAt: now,
        recordedBy: currentUser!.id,
      );

      // Upsert attendance (existing per-day doc may already exist).
      final existing = await attendanceRepository.getAttendanceByUserAndDate(
        attendance.userId,
        attendance.date,
      );
      String linkedId;
      if (existing != null) {
        await attendanceRepository.updateAttendance(existing.id, attendance.toMap());
        linkedId = existing.id;
      } else {
        linkedId = await attendanceRepository.addAttendance(attendance);
      }

      // âœ… Automatically award points for the accepted attendance.
      // Uses per-type defaults from settings/attendance_defaults.
      int? awardedPoints;
      String? awardReason;
       try {
         final defaults = await attendanceDefaultsRepository.getDefaults();
         final points = defaults[request.attendanceKey] ?? 1;
         final typeLabel = _attendanceTypeLabelFromKey(request.attendanceKey);
         awardReason = 'Ø­Ø¶ÙˆØ± $typeLabel';

         if (points > 0) {
           awardedPoints = points;
           await couponPointsService.setPoints(
             request.childId,
             points,
             awardReason,
             currentUser!.id,
           );
         }
       } catch (e) {
         // Points are a side effect; donâ€™t fail acceptance if points fail.
       }

       await attendanceRequestsRepository.updateRequest(request.id, {
         'status': 'accepted',
         'updatedAt': FieldValue.serverTimestamp(),
         'reviewedById': currentUser!.id,
         'reviewedByName': currentUser!.fullName,
         'linkedAttendanceId': linkedId,
         if (awardedPoints != null) 'awardedPoints': awardedPoints,
         if (awardReason != null) 'awardReason': awardReason,
       });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> declineAttendanceRequest(
    AttendanceRequestModel request, {
    String? reason,
  }) async {
    try {
      if (currentUser == null) {
        throw Exception('Current user not loaded');
      }

      await attendanceRequestsRepository.updateRequest(request.id, {
        'status': 'declined',
        'updatedAt': FieldValue.serverTimestamp(),
        'reviewedById': currentUser!.id,
        'reviewedByName': currentUser!.fullName,
        if (reason != null) 'decisionReason': reason,
      });
    } catch (e) {
      rethrow;
    }
  }

  String _attendanceTypeLabelFromKey(String key) {
    switch (key) {
      case 'holy_mass':
        return holyMass;
      case 'sunday_school':
        return sunday;
      case 'hymns':
        return hymns;
      case 'bible':
        return bibleClass;
      default:
        return key;
    }
  }

}

// Helper classes
class SyncResult {
  final bool success;
  final String message;
  final int syncedCount;
  final int failedCount;

  SyncResult({
    required this.success,
    required this.message,
    required this.syncedCount,
    required this.failedCount,
  });
}

class BatchResult {
  final bool success;
  final int savedCount;
  final bool isOffline;
  final String? error;

  BatchResult({
    required this.success,
    required this.savedCount,
    required this.isOffline,
    this.error,
  });
}

