import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/store/order_model.dart';

/// Repository for managing orders with Firestore integration.
class OrderRepository {
  final FirebaseFirestore _firestore;
  final String _collectionPath;

  OrderRepository({
    FirebaseFirestore? firestore,
    String collectionPath = 'orders',
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _collectionPath = collectionPath;

  CollectionReference get _ordersCollection =>
      _firestore.collection(_collectionPath);

  // ==================== STREAM METHODS ====================

  /// Stream all orders in real-time
  Stream<List<OrderModel>> watchAllOrders() {
    return _ordersCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderModel.fromFirestore(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .toList());
  }

  /// Stream orders by status
  Stream<List<OrderModel>> watchOrdersByStatus(OrderStatus status) {
    return _ordersCollection
        .where('status', isEqualTo: status.code)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderModel.fromFirestore(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .toList());
  }

  /// Stream orders by user
  Stream<List<OrderModel>> watchOrdersByUser(String userId) {
    return _ordersCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderModel.fromFirestore(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .toList());
  }

  /// Stream pending orders
  Stream<List<OrderModel>> watchPendingOrders() {
    return watchOrdersByStatus(OrderStatus.pending);
  }

  /// Stream a single order
  Stream<OrderModel?> watchOrder(String orderId) {
    return _ordersCollection.doc(orderId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return OrderModel.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    });
  }

  // ==================== FUTURE METHODS ====================

  /// Get all orders
  Future<List<OrderModel>> getAllOrders() async {
    try {
      final snapshot = await _ordersCollection
          .get();

      return snapshot.docs
          .map((doc) => OrderModel.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch orders: $e');
    }
  }

  /// Get order by ID
  Future<OrderModel?> getOrderById(String orderId) async {
    try {
      final doc = await _ordersCollection.doc(orderId).get();
      if (!doc.exists) return null;

      return OrderModel.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    } catch (e) {
      throw Exception('Failed to fetch order: $e');
    }
  }

  /// Get orders by status
  Future<List<OrderModel>> getOrdersByStatus(OrderStatus status) async {
    try {
      final snapshot = await _ordersCollection
          .where('status', isEqualTo: status.code)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => OrderModel.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch orders by status: $e');
    }
  }

  /// Get orders by user
  Future<List<OrderModel>> getOrdersByUser(String userId) async {
    try {
      final snapshot = await _ordersCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => OrderModel.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch orders by user: $e');
    }
  }

  // ==================== CREATE / UPDATE / DELETE ====================

  /// Create a new order
  Future<String> createOrder(OrderModel order) async {
    try {
      final orderData = order.toFirestore(includeId: false);
      orderData['createdAt'] = FieldValue.serverTimestamp();
      orderData['updatedAt'] = FieldValue.serverTimestamp();

      final docRef = await _ordersCollection.add(orderData);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  /// Update order
  Future<void> updateOrder(OrderModel order) async {
    try {
      final orderData = order.toFirestore(includeId: false);
      orderData['updatedAt'] = FieldValue.serverTimestamp();

      await _ordersCollection.doc(order.id).update(orderData);
    } catch (e) {
      throw Exception('Failed to update order: $e');
    }
  }

  /// Update order status
  Future<void> updateOrderStatus(String orderId, OrderStatus status, {String? notes}) async {
    try {
      // Get order data to check if points need to be returned
      final orderDoc = await _ordersCollection.doc(orderId).get();
      if (!orderDoc.exists) {
        throw Exception('Order not found');
      }

      final orderData = orderDoc.data() as Map<String, dynamic>;
      final metadata = orderData['metadata'] as Map<String, dynamic>?;
      final paidWithPoints = metadata?['paidWithPoints'] as bool? ?? false;
      final pointsDeducted = metadata?['pointsDeducted'] as int? ?? 0;
      final userId = orderData['userId'] as String?;

      final updateData = {
        'status': status.code,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (notes != null) {
        updateData['notes'] = notes;
      }

      if (status == OrderStatus.completed) {
        updateData['completedAt'] = FieldValue.serverTimestamp();
      }

      // If order is being cancelled or refunded, return points to user
      if ((status == OrderStatus.cancelled || status == OrderStatus.refunded) &&
          paidWithPoints &&
          pointsDeducted > 0 &&
          userId != null) {

        // Use a transaction to ensure atomicity
        await _firestore.runTransaction((transaction) async {
          // Update order status
          transaction.update(_ordersCollection.doc(orderId), updateData);

          // Return points to user
          final userRef = _firestore.collection('users').doc(userId);
          final userDoc = await transaction.get(userRef);

          if (userDoc.exists) {
            final currentPoints = (userDoc.data() as Map<String, dynamic>)['couponPoints'] as int? ?? 0;
            final newPoints = currentPoints + pointsDeducted;

            transaction.update(userRef, {
              'couponPoints': newPoints,
              'updatedAt': FieldValue.serverTimestamp(),
            });

            // Log the refund transaction
            final transactionRef = _firestore.collection('pointsTransactions').doc();
            transaction.set(transactionRef, {
              'userId': userId,
              'orderId': orderId,
              'points': pointsDeducted,
              'type': 'REFUND',
              'reason': 'Order ${status == OrderStatus.cancelled ? "cancelled" : "refunded"}',
              'previousBalance': currentPoints,
              'newBalance': newPoints,
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
        });
      } else {
        // No points refund needed, just update the order
        await _ordersCollection.doc(orderId).update(updateData);
      }
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  /// Delete order
  Future<void> deleteOrder(String orderId) async {
    try {
      await _ordersCollection.doc(orderId).delete();
    } catch (e) {
      throw Exception('Failed to delete order: $e');
    }
  }

  // ==================== STATISTICS ====================

  /// Get total order count
  Future<int> getTotalOrderCount() async {
    try {
      final snapshot = await _ordersCollection.get();
      return snapshot.size;
    } catch (e) {
      throw Exception('Failed to get order count: $e');
    }
  }

  /// Get order count by status
  Future<int> getOrderCountByStatus(OrderStatus status) async {
    try {
      final snapshot = await _ordersCollection
          .where('status', isEqualTo: status.code)
          .get();
      return snapshot.size;
    } catch (e) {
      throw Exception('Failed to get order count by status: $e');
    }
  }

  /// Get total revenue
  Future<double> getTotalRevenue() async {
    try {
      final snapshot = await _ordersCollection
          .where('status', isEqualTo: OrderStatus.completed.code)
          .get();

      double total = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        total += (data['total'] as num).toDouble();
      }
      return total;
    } catch (e) {
      throw Exception('Failed to get total revenue: $e');
    }
  }

  /// Get orders within date range
  Future<List<OrderModel>> getOrdersByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _ordersCollection
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => OrderModel.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch orders by date range: $e');
    }
  }

  /// Get revenue for date range
  Future<double> getRevenueByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final orders = await getOrdersByDateRange(startDate, endDate);
      return orders
          .where((order) => order.status == OrderStatus.completed)
          .fold<double>(0.0, (sum, order) => sum + order.total);
    } catch (e) {
      throw Exception('Failed to get revenue by date range: $e');
    }
  }
}

