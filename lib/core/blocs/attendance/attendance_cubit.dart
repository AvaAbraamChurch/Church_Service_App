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
  })  : usersRepository = usersRepository ?? UsersRepository(),
        attendanceRepository = attendanceRepository ?? AttendanceRepository(),
        visitRepository = visitRepository ?? VisitRepository(),
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
    _connectivitySub = Connectivity().onConnectivityChanged.listen((status) async {
      if (status != ConnectivityResult.none) {
        debugPrint('📡 Network restored, syncing pending data...');
        await syncPendingAttendances();
      } else {
        debugPrint('📴 Network lost, entering offline mode');
        emit(OfflineModeActive(getPendingCount()));
      }
    });

    // Auto-sync every 5 minutes when online
    _autoSyncTimer = Timer.periodic(Duration(minutes: 5), (timer) async {
      final online = await _hasNetwork();
      if (online && getPendingCount() > 0 && !_isSyncing) {
        debugPrint('⏰ Auto-sync triggered');
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
      final result = await Connectivity().checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      return false;
    }
  }

  Future<bool> checkNetwork() async {
    return await _hasNetwork();
  }

  /// Enhanced sync with better error handling and progress tracking
  Future<SyncResult> syncPendingAttendances() async {
    if (_isSyncing) {
      debugPrint('⏳ Sync already in progress, skipping...');
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

        debugPrint('✅ Synced attendance for user ${attendance.userId}');
      } catch (e) {
        failureCount++;
        failedItems.add(row);
        debugPrint('❌ Failed to sync attendance: $e');
        // Don't remove from local storage - keep for retry
      }
    }

    _isSyncing = false;
    _lastSyncTime = DateTime.now();
    _syncErrorCount = failureCount;

    final result = SyncResult(
      success: failureCount == 0,
      message: failureCount == 0
          ? 'تمت مزامنة جميع البيانات ($successCount)'
          : 'تمت مزامنة $successCount، فشل $failureCount',
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
        message: 'لا يوجد اتصال بالإنترنت',
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
        debugPrint('💾 Saved attendance offline: $key');
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
        debugPrint('☁️ Saved attendance online: $docId');
        return docId;
      } catch (networkError) {
        // Network error during save - fallback to local
        debugPrint('⚠️ Network error, saving locally: $networkError');
        final key = await _localRepo.savePendingAttendance(attendance);
        emit(takeAttendanceSuccessOffline(getPendingCount()));
        return 'local_$key';
      }
    } catch (e) {
      debugPrint('❌ Error taking attendance: $e');
      emit(takeAttendanceError(e.toString()));
      rethrow;
    }
  }

  /// Batch take attendance with offline support
  Future<BatchResult> batchTakeAttendance(List<AttendanceModel> attendanceList) async {
    try {
      debugPrint('🔵 [START] batchTakeAttendance with ${attendanceList.length} items');
      emit(takeAttendanceLoading());

      debugPrint('🔍 Checking network connection...');
      final online = await _hasNetwork();
      debugPrint('📡 Network status: ${online ? "ONLINE" : "OFFLINE"}');

      if (!online) {
        // Save all items locally
        debugPrint('💾 Saving ${attendanceList.length} items offline');
        for (final attendance in attendanceList) {
          await _localRepo.savePendingAttendance(attendance);
          debugPrint('💾 Saved attendance offline for user: ${attendance.userId}');
        }
        debugPrint('✅ Emitting takeAttendanceSuccessOffline with ${getPendingCount()} pending');
        emit(takeAttendanceSuccessOffline(getPendingCount()));
        debugPrint('🔵 [END] Offline save complete');
        return BatchResult(
          success: true,
          savedCount: attendanceList.length,
          isOffline: true,
        );
      }

      // Try batch upload with timeout
      try {
        debugPrint('☁️ Attempting to save to Firebase...');
        await attendanceRepository.batchAddAttendance(attendanceList).timeout(
          Duration(seconds: 3),
          onTimeout: () {
            debugPrint('⏱️ Firebase save timed out after 3 seconds');
            throw TimeoutException('Firebase operation timed out');
          },
        );
        debugPrint('✅ Firebase save successful');
        debugPrint('✅ Emitting takeAttendanceSuccess');
        emit(takeAttendanceSuccess());
        debugPrint('🔵 [END] Online save complete');
        return BatchResult(
          success: true,
          savedCount: attendanceList.length,
          isOffline: false,
        );
      } catch (networkError) {
        // Fallback to local storage
        debugPrint('⚠️ Network error during save: $networkError');
        debugPrint('💾 Falling back to local storage...');
        for (final attendance in attendanceList) {
          await _localRepo.savePendingAttendance(attendance);
        }
        debugPrint('✅ Emitting takeAttendanceSuccessOffline with ${getPendingCount()} pending');
        emit(takeAttendanceSuccessOffline(getPendingCount()));
        debugPrint('🔵 [END] Fallback save complete');
        return BatchResult(
          success: true,
          savedCount: attendanceList.length,
          isOffline: true,
        );
      }
    } catch (e) {
      debugPrint('❌ [ERROR] batchTakeAttendance failed: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
      emit(takeAttendanceError(e.toString()));
      debugPrint('🔵 [END] Error occurred');
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
      debugPrint('📋 Loaded ${users?.length ?? 0} users');
      emit(getAllUsersSuccess());
      return users;
    }).handleError((e) {
      emit(getAllUsersError(e.toString()));
      debugPrint('❌ Error loading users: $e');
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
      debugPrint('📋 Loaded ${users?.length ?? 0} users by gender');
      emit(getAllUsersSuccess());
      return users;
    }).handleError((e) {
      emit(getAllUsersError(e.toString()));
      debugPrint('❌ Error loading users by gender: $e');
    });
  }

  // Get users for priest
  Stream<List<UserModel>?> getUsersByTypeForPriest(List<String> userTypes) {
    emit(getAllUsersLoading());
    return usersRepository
        .getUsersByMultipleTypesForPriest(userTypes)
        .map((fetchedUsers) {
      users = fetchedUsers;
      debugPrint('📋 Loaded ${users?.length ?? 0} users for priest');
      emit(getAllUsersSuccess());
      return users;
    }).handleError((e) {
      emit(getAllUsersError(e.toString()));
      debugPrint('❌ Error loading users for priest: $e');
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
        emit(VisitError('لا يوجد اتصال بالإنترنت. الزيارات تحتاج اتصال.'));
        throw Exception('No network connection for visits');
      }

      final id = await visitRepository.addOrMergeVisit(visit);
      emit(CreateVisitSuccess(id));
      debugPrint('✅ Visit created/merged: $id');
      return id;
    } catch (e) {
      final msg = e.toString();
      emit(VisitError(msg));
      debugPrint('❌ Error creating visit: $msg');
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
        emit(VisitError('لا يوجد اتصال بالإنترنت'));
        throw Exception('No network connection');
      }

      await visitRepository.addServantToVisit(
        visitId: visitId,
        servantId: servantId,
        servantName: servantName,
      );
      emit(AddServantSuccess());
      debugPrint('✅ Servant added to visit: $servantId');
    } catch (e) {
      emit(VisitError(e.toString()));
      debugPrint('❌ Error adding servant to visit: $e');
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
      debugPrint('🗑️ Cleared all pending data');
    } catch (e) {
      debugPrint('❌ Error clearing pending data: $e');
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