import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:church/core/repositories/local_points_repository.dart';

/// Service for syncing pending points transactions from local storage to Firestore
class PointsSyncService {
  final FirebaseFirestore _firestore;
  final LocalPointsRepository _localRepo;
  final Connectivity _connectivity;

  PointsSyncService({
    FirebaseFirestore? firestore,
    LocalPointsRepository? localRepo,
    Connectivity? connectivity,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _localRepo = localRepo ?? LocalPointsRepository(),
        _connectivity = connectivity ?? Connectivity();

  /// Check if device is online
  Future<bool> _isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return result.contains(ConnectivityResult.mobile) ||
        result.contains(ConnectivityResult.wifi) ||
        result.contains(ConnectivityResult.ethernet);
  }

  /// Sync all pending points transactions
  Future<Map<String, dynamic>> syncPendingTransactions() async {
    if (!await _isOnline()) {
      return {
        'success': false,
        'message': 'Device is offline',
        'synced': 0,
        'failed': 0,
      };
    }

    final pending = _localRepo.getPendingTransactions();
    if (pending.isEmpty) {
      return {
        'success': true,
        'message': 'No pending transactions',
        'synced': 0,
        'failed': 0,
      };
    }

    int synced = 0;
    int failed = 0;
    final List<String> errors = [];

    for (final transaction in pending) {
      try {
        await _syncSingleTransaction(transaction);
        await _localRepo.deletePending(transaction['key'] as String);
        synced++;
      } catch (e) {
        failed++;
        errors.add('${transaction['key']}: $e');
        await _localRepo.incrementRetryCount(transaction['key'] as String);
      }
    }

    return {
      'success': failed == 0,
      'message': failed == 0
          ? 'All transactions synced successfully'
          : 'Some transactions failed to sync',
      'synced': synced,
      'failed': failed,
      'errors': errors,
    };
  }

  /// Sync a single pending transaction
  Future<void> _syncSingleTransaction(Map<String, dynamic> transaction) async {
    final userId = transaction['userId'] as String;
    final points = transaction['points'] as int;
    final type = transaction['type'] as String;
    final reason = transaction['reason'] as String;
    final orderId = transaction['orderId'] as String?;
    final adjustedBy = transaction['adjustedBy'] as String?;

    await _firestore.runTransaction((firestoreTransaction) async {
      final userRef = _firestore.collection('users').doc(userId);
      final userDoc = await firestoreTransaction.get(userRef);

      if (!userDoc.exists) {
        throw Exception('User not found: $userId');
      }

      final currentPoints = (userDoc.data() as Map<String, dynamic>)['couponPoints'] as int? ?? 0;
      final newPoints = currentPoints + points;

      // Prevent negative points
      if (newPoints < 0) {
        throw Exception('Points would be negative for user $userId');
      }

      firestoreTransaction.update(userRef, {
        'couponPoints': newPoints,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log the transaction
      final transactionRef = _firestore.collection('pointsTransactions').doc();
      firestoreTransaction.set(transactionRef, {
        'userId': userId,
        'orderId': orderId,
        'points': points,
        'type': type,
        'reason': reason,
        'adjustedBy': adjustedBy,
        'previousBalance': currentPoints,
        'newBalance': newPoints,
        'createdAt': FieldValue.serverTimestamp(),
        'syncedAt': FieldValue.serverTimestamp(),
        'wasOffline': true,
      });
    });
  }

  /// Sync pending transactions for a specific user
  Future<Map<String, dynamic>> syncPendingForUser(String userId) async {
    if (!await _isOnline()) {
      return {
        'success': false,
        'message': 'Device is offline',
        'synced': 0,
        'failed': 0,
      };
    }

    final pending = _localRepo.getPendingForUser(userId);
    if (pending.isEmpty) {
      return {
        'success': true,
        'message': 'No pending transactions for this user',
        'synced': 0,
        'failed': 0,
      };
    }

    int synced = 0;
    int failed = 0;
    final List<String> errors = [];

    for (final transaction in pending) {
      try {
        await _syncSingleTransaction(transaction);
        await _localRepo.deletePending(transaction['key'] as String);
        synced++;
      } catch (e) {
        failed++;
        errors.add('${transaction['key']}: $e');
        await _localRepo.incrementRetryCount(transaction['key'] as String);
      }
    }

    return {
      'success': failed == 0,
      'message': failed == 0
          ? 'All transactions synced successfully'
          : 'Some transactions failed to sync',
      'synced': synced,
      'failed': failed,
      'errors': errors,
    };
  }

  /// Get sync status
  Future<Map<String, dynamic>> getSyncStatus() async {
    final isOnline = await _isOnline();
    final stats = _localRepo.getStatistics();
    final pendingCount = _localRepo.getPendingCount();

    return {
      'isOnline': isOnline,
      'pendingCount': pendingCount,
      'canSync': isOnline && pendingCount > 0,
      'statistics': stats,
    };
  }

  /// Auto-sync when connectivity is restored
  Stream<Map<String, dynamic>> watchAndSync() async* {
    await for (final connectivityResult in _connectivity.onConnectivityChanged) {
      final isOnline = connectivityResult.contains(ConnectivityResult.mobile) ||
          connectivityResult.contains(ConnectivityResult.wifi) ||
          connectivityResult.contains(ConnectivityResult.ethernet);

      if (isOnline) {
        // Wait a bit for connection to stabilize
        await Future.delayed(const Duration(seconds: 2));

        final result = await syncPendingTransactions();
        yield result;
      } else {
        yield {
          'success': false,
          'message': 'Device is offline',
          'synced': 0,
          'failed': 0,
        };
      }
    }
  }

  /// Retry failed transactions
  Future<Map<String, dynamic>> retryFailedTransactions() async {
    if (!await _isOnline()) {
      return {
        'success': false,
        'message': 'Device is offline',
        'synced': 0,
        'failed': 0,
      };
    }

    final failed = _localRepo.getFailedItems();
    if (failed.isEmpty) {
      return {
        'success': true,
        'message': 'No failed transactions to retry',
        'synced': 0,
        'failed': 0,
      };
    }

    int synced = 0;
    int stillFailed = 0;
    final List<String> errors = [];

    for (final transaction in failed) {
      try {
        await _syncSingleTransaction(transaction);
        await _localRepo.deletePending(transaction['key'] as String);
        synced++;
      } catch (e) {
        stillFailed++;
        errors.add('${transaction['key']}: $e');
        await _localRepo.incrementRetryCount(transaction['key'] as String);
      }
    }

    return {
      'success': stillFailed == 0,
      'message': stillFailed == 0
          ? 'All failed transactions synced successfully'
          : 'Some transactions still failed',
      'synced': synced,
      'failed': stillFailed,
      'errors': errors,
    };
  }

  /// Clear all pending transactions (dangerous!)
  Future<void> clearAllPending() async {
    await _localRepo.clearAllPending();
  }

  /// Delete old pending transactions
  Future<int> cleanupOldTransactions({int olderThanDays = 30}) async {
    return await _localRepo.deleteOldPending(olderThanDays: olderThanDays);
  }
}

