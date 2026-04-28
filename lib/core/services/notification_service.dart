// lib/core/services/notification_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import '../models/notification_model.dart';

/// Result from Edge Function notification creation
class NotificationResult {
  final bool success;
  final String? notificationId;
  final int? pushSent;        // Number of pushes successfully sent
  final String? pushError;    // Optional: comma-separated error messages
  final String? error;        // Optional: error message if success=false

  NotificationResult({
    required this.success,
    this.notificationId,
    this.pushSent,
    this.pushError,
    this.error,
  });

  factory NotificationResult.fromJson(Map<String, dynamic> json) => NotificationResult(
    success: json['success'] ?? false,
    notificationId: json['notificationId'] as String?,
    pushSent: json['pushSent'] as int?,
    pushError: json['pushError'] as String?,
    error: json['error'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'success': success,
    if (notificationId != null) 'notificationId': notificationId,
    if (pushSent != null) 'pushSent': pushSent,
    if (pushError != null) 'pushError': pushError,
    if (error != null) 'error': error,
  };

  @override
  String toString() => 'NotificationResult(success: $success, notificationId: $notificationId, pushSent: $pushSent, error: $error)';
}

/// Input for creating a notification via Edge Function
class NotificationInput {
  final String title;
  final String body;
  final String? imageUrl;
  final Map<String, dynamic>? data;
  final String? userId;       // null = global notification
  final String? type;
  final String? actionUrl;
  final bool sendPush;        // Whether to send FCM push (default: true)
  final List<String>? fcmTokens; // Optional: target specific tokens

  NotificationInput({
    required this.title,
    required this.body,
    this.imageUrl,
    this.data,
    this.userId,
    this.type,
    this.actionUrl,
    this.sendPush = true,
    this.fcmTokens,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'body': body,
    if (imageUrl != null) 'imageUrl': imageUrl,
    if (data != null) 'data': data,
    if (userId != null) 'userId': userId,
    if (type != null) 'type': type,
    if (actionUrl != null) 'actionUrl': actionUrl,
    'sendPush': sendPush,
    if (fcmTokens != null) 'fcmTokens': fcmTokens,
  };
}

/// Service for managing notifications via Firestore + Supabase Edge Functions
class NotificationService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // Edge Function configuration (loaded from --dart-define or secure storage)
  final String _edgeFunctionUrl;
  final String _adminApiKey;

  NotificationService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    String? edgeFunctionUrl,
    String? adminApiKey,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
  // Load from compile-time defines (production) or fallback
        _edgeFunctionUrl = edgeFunctionUrl ??
            const String.fromEnvironment(
              'SUPABASE_NOTIFICATION_URL',
              defaultValue: 'https://pfytemzrsgcptoxqywjs.supabase.co/functions/v1/send-notification',
            ),
        _adminApiKey = adminApiKey ??
            const String.fromEnvironment('ADMIN_API_KEY', defaultValue: '');

  // ============ Firestore Collection Reference ============
  CollectionReference<Map<String, dynamic>> get _notificationsCollection =>
      _firestore.collection('notifications').withConverter<Map<String, dynamic>>(
        fromFirestore: (snapshot, _) => snapshot.data()!,
        toFirestore: (data, _) => data,
      );

  // ============ Helper: Current User ID ============
  String? get _currentUserId => _auth.currentUser?.uid;

  // ============ 🔔 READ: Existing Firestore Methods (Preserved) ============

  /// Stream of notifications for current user (user-specific + global)
  Stream<List<NotificationModel>> getUserNotifications() {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _notificationsCollection
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .where((notification) =>
      notification.userId == _currentUserId ||
          notification.userId == null)
          .toList();
    });
  }

  /// Stream of all notifications (for admin view)
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

  /// Mark a single notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      print('❌ Error marking notification as read: $e');
      rethrow;
    }
  }

  /// Mark all notifications as read for current user
  Future<void> markAllAsRead() async {
    if (_currentUserId == null) return;

    try {
      final snapshot = await _notificationsCollection
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        final notification = NotificationModel.fromFirestore(doc);
        if (notification.userId == _currentUserId || notification.userId == null) {
          batch.update(doc.reference, {'isRead': true});
        }
      }
      await batch.commit();
    } catch (e) {
      print('❌ Error marking all notifications as read: $e');
      rethrow;
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).delete();
    } catch (e) {
      print('❌ Error deleting notification: $e');
      rethrow;
    }
  }

  /// Get unread count for current user
  Stream<int> getUnreadCount() {
    if (_currentUserId == null) {
      return Stream.value(0);
    }

    return _notificationsCollection
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .where((notification) =>
      notification.userId == _currentUserId ||
          notification.userId == null)
          .length;
    });
  }

  /// Clear all notifications for current user
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
      print('❌ Error clearing notifications: $e');
      rethrow;
    }
  }

  /// Save a Firebase RemoteMessage to Firestore notifications collection
  /// Used by background FCM handler in main.dart
  Future<void> saveNotificationFromRemoteMessage(RemoteMessage message) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _notificationsCollection.add({
        'title': message.notification?.title ?? message.data['title'] ?? 'إشعار جديد',
        'body': message.notification?.body ?? message.data['body'] ?? '',
        'imageUrl': message.notification?.android?.imageUrl ?? message.data['imageUrl'],
        'data': message.data,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'userId': message.data['userId'] ?? userId, // Use provided userId or current user
        'type': message.data['type'] ?? 'message',
        'actionUrl': message.data['actionUrl'],
        'source': 'fcm', // Mark as received via FCM
      });
    } catch (e) {
      print('❌ Error saving FCM notification to Firestore: $e');
      rethrow;
    }
  }


  // ============ ✨ WRITE: Edge Function Integration (New) ============

  /// Create notification via Supabase Edge Function
  /// 
  /// Saves to Firestore AND optionally sends FCM push notification.
  /// 
  /// Usage:
  /// ```dart
  /// final result = await notificationService.createNotificationViaEdge(
  ///   title: 'Church Update',
  ///   body: 'New service schedule posted!',
  ///   userId: 'firebase-user-uid', // null for global
  ///   type: 'announcement',
  ///   actionUrl: '/screens/announcements',
  ///   sendPush: true,
  ///   data: {'screen': 'announcements', 'id': '123'},
  /// );
  /// 
  /// if (result.success) {
  ///   print('✅ Notification created: ${result.notificationId}');
  ///   print('📱 Push sent to ${result.pushSent} devices');
  /// }
  /// ```
  Future<NotificationResult> createNotificationViaEdge({
    required String title,
    required String body,
    String? imageUrl,
    Map<String, dynamic>? data,
    String? userId, // null = global notification
    String? type,
    String? actionUrl,
    bool sendPush = true,
    List<String>? fcmTokens, // Optional: target specific tokens directly
  }) async {
    // Validate required fields
    if (title.trim().isEmpty || body.trim().isEmpty) {
      throw ArgumentError('Title and body are required');
    }

    // Validate admin API key is configured
    if (_adminApiKey.isEmpty) {
      throw Exception(
        'ADMIN_API_KEY not configured. '
            'Set via --dart-define=ADMIN_API_KEY=your-key',
      );
    }

    try {
      print('🔔 Sending notification via Edge Function: "$title"');

      final input = NotificationInput(
        title: title,
        body: body,
        imageUrl: imageUrl,
        data: data,
        userId: userId,
        type: type,
        actionUrl: actionUrl,
        sendPush: sendPush,
        fcmTokens: fcmTokens,
      );

      final response = await http.post(
        Uri.parse(_edgeFunctionUrl),
        headers: {
          'Content-Type': 'application/json',
          'apikey': _adminApiKey, // 🔐 Admin authentication
          'User-Agent': 'ChurchApp/1.0',
        },
        body: jsonEncode(input.toJson()),
      ).timeout(const Duration(seconds: 30));

      print('📡 Edge Function response: ${response.statusCode}');

      // Handle HTTP errors
      if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid ADMIN_API_KEY');
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body)['error'] ?? 'Bad request';
        throw Exception('Invalid request: $error');
      } else if (response.statusCode >= 500) {
        throw Exception('Edge Function server error: ${response.statusCode}');
      } else if (response.statusCode != 200) {
        // Check if response is HTML error page (common with misconfigured APIs)
        if (response.body.trim().startsWith('<')) {
          throw Exception('Edge Function returned HTML error (check URL/credentials)');
        }
        throw Exception('Unexpected response: ${response.statusCode}');
      }

      // Parse JSON response
      final Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        throw Exception('Failed to parse Edge Function response: ${response.body}');
      }

      // Check for success flag
      if (responseData['success'] != true) {
        final errorMsg = responseData['error'] ?? 'Notification creation failed';
        throw Exception('Edge Function error: $errorMsg');
      }

      final result = NotificationResult.fromJson(responseData);
      print('✅ Notification created: ${result.notificationId}, push sent: ${result.pushSent}');

      return result;

    } on http.ClientException catch (e) {
      print('❌ Network error: $e');
      throw Exception('Network error: Check connection and function URL');
    } on TimeoutException catch (e) {
      print('❌ Timeout: $e');
      throw Exception('Request timed out after 30 seconds');
    } catch (e) {
      print('❌ Unexpected error in createNotificationViaEdge: $e');
      rethrow;
    }
  }

  /// Convenience: Create global notification (all users)
  Future<NotificationResult> createGlobalNotification({
    required String title,
    required String body,
    String? imageUrl,
    Map<String, dynamic>? data,
    String? type,
    String? actionUrl,
    bool sendPush = true,
  }) {
    return createNotificationViaEdge(
      title: title,
      body: body,
      imageUrl: imageUrl,
      data: data,
      userId: null, // Global
      type: type,
      actionUrl: actionUrl,
      sendPush: sendPush,
    );
  }

  /// Convenience: Create user-specific notification
  Future<NotificationResult> createUserNotification({
    required String userId,
    required String title,
    required String body,
    String? imageUrl,
    Map<String, dynamic>? data,
    String? type,
    String? actionUrl,
    bool sendPush = true,
  }) {
    return createNotificationViaEdge(
      title: title,
      body: body,
      imageUrl: imageUrl,
      data: data,
      userId: userId,
      type: type,
      actionUrl: actionUrl,
      sendPush: sendPush,
    );
  }

  // ============ 🔍 Debug Helpers ============

  /// Check if Edge Function is reachable (for admin diagnostics)
  Future<bool> isEdgeFunctionAvailable() async {
    try {
      // 🔧 Use POST ping for reliable health check (OPTIONS not always supported)
      final response = await http.post(
        Uri.parse(_edgeFunctionUrl),
        headers: {
          'Content-Type': 'application/json',
          'apikey': _adminApiKey,
        },
        body: jsonEncode({'_healthCheck': true}),
      ).timeout(const Duration(seconds: 10));

      // Reachable if: success (200), valid request missing fields (400), or auth working (401)
      // Unreachable if: not found (404), server error (500+), or network failure
      final reachableCodes = [200, 400, 401];
      return reachableCodes.contains(response.statusCode);

    } on TimeoutException {
      print('⏱️ Edge Function health check timed out');
      return false;
    } on http.ClientException catch (e) {
      print('🌐 Network error checking Edge Function: $e');
      return false;
    } catch (e) {
      print('❓ Unexpected error in health check: $e');
      return false;
    }
  }

  /// Log configuration status (debug only)
  void logConfig({bool verbose = false}) {
    if (verbose) {
      print('🔔 NotificationService Config:');
      print('   Edge Function URL: $_edgeFunctionUrl');
      print('   ADMIN_API_KEY set: ${_adminApiKey.isNotEmpty}');
      print('   Current user: ${_currentUserId ?? "none"}');
    }
  }
}