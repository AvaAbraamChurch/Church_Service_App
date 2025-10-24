import 'package:cloud_firestore/cloud_firestore.dart';

/// Coupon Points Service for managing user points
class CouponPointsService {
  final FirebaseFirestore _firestore;

  CouponPointsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Points calculation rules
  /// 1 point = $1.00 (points are the transaction currency)
  static const double POINTS_VALUE = 1.0; // Each point worth $1.00

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

  /// Get user's current points
  Future<int> getUserPoints(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return 0;

      final data = userDoc.data() as Map<String, dynamic>;
      return data['couponPoints'] as int? ?? 0;
    } catch (e) {
      throw Exception('Failed to get user points: $e');
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

  /// Add points to user (e.g., for completed orders)
  Future<void> addPoints(String userId, int points, {String? orderId}) async {
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
      throw Exception('Failed to add points: $e');
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
}

