import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection reference
  CollectionReference get _notificationsCollection =>
      _firestore.collection('notifications');

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  // Stream of notifications for current user
  Stream<List<NotificationModel>> getUserNotifications() {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    // We need to combine two queries: user-specific and global notifications
    // Since Firestore doesn't support OR queries directly, we'll use a workaround
    return _notificationsCollection
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      // Filter to include only notifications for this user or global notifications
      return snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .where((notification) =>
              notification.userId == _currentUserId ||
              notification.userId == null)
          .toList();
    });
  }

  // Get all notifications (for admin or general view)
  Stream<List<NotificationModel>> getAllNotifications() {
    return _notificationsCollection
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
    });
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read for current user
  Future<void> markAllAsRead() async {
    if (_currentUserId == null) return;

    try {
      final snapshot = await _notificationsCollection
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        final notification = NotificationModel.fromFirestore(doc);
        // Only mark as read if it's for this user or global
        if (notification.userId == _currentUserId || notification.userId == null) {
          batch.update(doc.reference, {'isRead': true});
        }
      }
      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).delete();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  // Create a notification (for admin or system use)
  Future<void> createNotification({
    required String title,
    required String body,
    String? imageUrl,
    Map<String, dynamic>? data,
    String? userId, // null for global notifications
    String? type,
    String? actionUrl,
  }) async {
    try {
      await _notificationsCollection.add({
        'title': title,
        'body': body,
        'imageUrl': imageUrl,
        'data': data,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'userId': userId,
        'type': type,
        'actionUrl': actionUrl,
      });
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  // Get unread count
  Stream<int> getUnreadCount() {
    if (_currentUserId == null) {
      return Stream.value(0);
    }

    return _notificationsCollection
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      // Filter to count only notifications for this user or global notifications
      return snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .where((notification) =>
              notification.userId == _currentUserId ||
              notification.userId == null)
          .length;
    });
  }

  // Clear all notifications for current user
  Future<void> clearAllNotifications() async {
    if (_currentUserId == null) return;

    try {
      final snapshot = await _notificationsCollection
          .where('userId', isEqualTo: _currentUserId)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('Error clearing notifications: $e');
    }
  }
}

