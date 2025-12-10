import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:church/core/repositories/local_points_repository.dart';

/// Coupon Points Service for managing user points (with offline support)
class CouponPointsService {
  final FirebaseFirestore _firestore;
  final LocalPointsRepository _localRepo;
  final Connectivity _connectivity;

  CouponPointsService({
    FirebaseFirestore? firestore,
    LocalPointsRepository? localRepo,
    Connectivity? connectivity,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _localRepo = localRepo ?? LocalPointsRepository(),
        _connectivity = connectivity ?? Connectivity();

  /// Points calculation rules
  /// 1 point = $1.00 (points are the transaction currency)
  static const double POINTS_VALUE = 1.0; // Each point worth $1.00

  /// Check if device is online
  Future<bool> _isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return result.contains(ConnectivityResult.mobile) ||
        result.contains(ConnectivityResult.wifi) ||
        result.contains(ConnectivityResult.ethernet);
  }

  /// Calculate points earned from order total
  /// Points earned equal the order total (1 point per $1)
  int calculatePointsEarned(double orderTotal) {
    return orderTotal.floor();
  }

  /// Calculate discount from points
  /// Direct conversion: points = dollars (1 point = $1)
  double calculatePointsDiscount(int points) {
    return points.toDouble();
  }

  /// Get user's current points (including pending local adjustments)
  Future<int> getUserPoints(String userId, {bool includePending = true}) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return 0;

      final data = userDoc.data() as Map<String, dynamic>;
      int onlinePoints = data['couponPoints'] as int? ?? 0;

      // Add pending local adjustments if requested
      if (includePending) {
        final localAdjustment = _localRepo.getLocalBalanceAdjustment(userId);
        return onlinePoints + localAdjustment;
      }

      return onlinePoints;
    } catch (e) {
      // If offline, try to get from cache with local adjustments
      try {
        final localAdjustment = _localRepo.getLocalBalanceAdjustment(userId);
        return localAdjustment; // Best effort
      } catch (_) {
        throw Exception('Failed to get user points: $e');
      }
    }
  }

  /// Check if user has enough points
  Future<bool> hasEnoughPoints(String userId, int requiredPoints) async {
    final currentPoints = await getUserPoints(userId);
    return currentPoints >= requiredPoints;
  }

  /// Deduct points from user
  Future<void> deductPoints(String userId, int points, {String? orderId}) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final userRef = _firestore.collection('users').doc(userId);
        final userDoc = await transaction.get(userRef);

        if (!userDoc.exists) {
          throw Exception('User not found');
        }

        final currentPoints = (userDoc.data() as Map<String, dynamic>)['couponPoints'] as int? ?? 0;

        if (currentPoints < points) {
          throw Exception('Insufficient points');
        }

        final newPoints = currentPoints - points;
        transaction.update(userRef, {
          'couponPoints': newPoints,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Log the transaction
        if (orderId != null) {
          final transactionRef = _firestore.collection('pointsTransactions').doc();
          transaction.set(transactionRef, {
            'userId': userId,
            'orderId': orderId,
            'points': -points,
            'type': 'DEDUCTION',
            'reason': 'Order purchase',
            'previousBalance': currentPoints,
            'newBalance': newPoints,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      throw Exception('Failed to deduct points: $e');
    }
  }

  /// Add points to user (e.g., for completed orders) - with offline support
  Future<void> addPoints(String userId, int points, {String? orderId}) async {
    final isOnline = await _isOnline();

    if (!isOnline) {
      // Save to local storage for later sync
      await _localRepo.savePendingTransaction(
        userId: userId,
        points: points,
        type: 'ADDITION',
        reason: orderId != null ? 'Order cashback' : 'Points addition',
        orderId: orderId,
      );
      return;
    }

    try {
      await _firestore.runTransaction((transaction) async {
        final userRef = _firestore.collection('users').doc(userId);
        final userDoc = await transaction.get(userRef);

        if (!userDoc.exists) {
          throw Exception('User not found');
        }

        final currentPoints = (userDoc.data() as Map<String, dynamic>)['couponPoints'] as int? ?? 0;
        final newPoints = currentPoints + points;

        transaction.update(userRef, {
          'couponPoints': newPoints,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Log the transaction
        if (orderId != null) {
          final transactionRef = _firestore.collection('pointsTransactions').doc();
          transaction.set(transactionRef, {
            'userId': userId,
            'orderId': orderId,
            'points': points,
            'type': 'ADDITION',
            'reason': 'Order cashback',
            'previousBalance': currentPoints,
            'newBalance': newPoints,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      // If online but failed, save locally
      await _localRepo.savePendingTransaction(
        userId: userId,
        points: points,
        type: 'ADDITION',
        reason: orderId != null ? 'Order cashback' : 'Points addition',
        orderId: orderId,
      );
    }
  }

  /// Get points transaction history
  Stream<List<Map<String, dynamic>>> watchUserTransactions(String userId) {
    return _firestore
        .collection('pointsTransactions')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList());
  }

  /// Calculate maximum discount available from points
  /// For children, points can cover the entire order (no limit)
  double getMaximumDiscount(int availablePoints, double orderTotal) {
    final maxPointsDiscount = calculatePointsDiscount(availablePoints);
    // Children can use points to pay for entire order
    return maxPointsDiscount > orderTotal ? orderTotal : maxPointsDiscount;
  }

  /// Calculate points needed for a specific discount amount
  int getPointsForDiscount(double discountAmount) {
    return discountAmount.ceil();
  }

  /// Check if user has enough points to cover order total
  bool canCoverOrderWithPoints(int availablePoints, double orderTotal) {
    return availablePoints >= orderTotal.ceil();
  }

  /// Set points for a user (can be positive or negative adjustment)
  /// Used by servants/super servants to manually adjust points - with offline support
  Future<void> setPoints(
    String userId,
    int pointsToAdjust,
    String reason,
    String adjustedBy,
  ) async {
    final isOnline = await _isOnline();

    if (!isOnline) {
      // Save to local storage for later sync
      await _localRepo.savePendingTransaction(
        userId: userId,
        points: pointsToAdjust,
        type: pointsToAdjust >= 0 ? 'MANUAL_ADDITION' : 'MANUAL_DEDUCTION',
        reason: reason,
        adjustedBy: adjustedBy,
      );
      return;
    }

    try {
      await _firestore.runTransaction((transaction) async {
        final userRef = _firestore.collection('users').doc(userId);
        final userDoc = await transaction.get(userRef);

        if (!userDoc.exists) {
          throw Exception('User not found');
        }

        final currentPoints = (userDoc.data() as Map<String, dynamic>)['couponPoints'] as int? ?? 0;
        final newPoints = currentPoints + pointsToAdjust;

        // Prevent negative points
        if (newPoints < 0) {
          throw Exception('Points cannot be negative');
        }

        transaction.update(userRef, {
          'couponPoints': newPoints,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Log the transaction
        final transactionRef = _firestore.collection('pointsTransactions').doc();
        transaction.set(transactionRef, {
          'userId': userId,
          'points': pointsToAdjust,
          'type': pointsToAdjust >= 0 ? 'MANUAL_ADDITION' : 'MANUAL_DEDUCTION',
          'reason': reason,
          'adjustedBy': adjustedBy,
          'previousBalance': currentPoints,
          'newBalance': newPoints,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      // If online but failed, save locally
      await _localRepo.savePendingTransaction(
        userId: userId,
        points: pointsToAdjust,
        type: pointsToAdjust >= 0 ? 'MANUAL_ADDITION' : 'MANUAL_DEDUCTION',
        reason: reason,
        adjustedBy: adjustedBy,
      );
      throw Exception('Failed to set points online, saved locally: $e');
    }
  }

  /// Bulk set points for multiple users
  /// Used by servants/super servants to reward attendance with points
  Future<Map<String, dynamic>> bulkSetPoints(
    List<String> userIds,
    int pointsToAdjust,
    String reason,
    String adjustedBy,
  ) async {
    int successCount = 0;
    int failCount = 0;
    List<String> failedUserIds = [];

    for (final userId in userIds) {
      try {
        await setPoints(userId, pointsToAdjust, reason, adjustedBy);
        successCount++;
      } catch (e) {
        failCount++;
        failedUserIds.add(userId);
      }
    }

    return {
      'successCount': successCount,
      'failCount': failCount,
      'failedUserIds': failedUserIds,
      'totalProcessed': userIds.length,
    };
  }

  /// Get user's points transaction history (paginated)
  Future<List<Map<String, dynamic>>> getUserTransactionHistory(
    String userId, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('pointsTransactions')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      throw Exception('Failed to get transaction history: $e');
    }
  }
}

