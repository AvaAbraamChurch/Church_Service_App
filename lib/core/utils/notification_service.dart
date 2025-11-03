import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Top-level background message handler required by firebase_messaging
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Note: This runs in its own isolate. Keep initialization minimal.
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  try {
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    final notification = message.notification;
    if (notification != null) {
      final android = message.notification?.android;

      final androidDetails = AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'This channel is used for important notifications.',
        importance: Importance.high,
        priority: Priority.high,
        icon: android?.smallIcon ?? '@mipmap/ic_launcher',
      );

      final platformDetails = NotificationDetails(android: androidDetails);
      await flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        platformDetails,
        payload: message.data['payload']?.toString(),
      );
    }
  } catch (_) {
    // Background handler should not crash; swallow errors.
  }
}

class NotificationService {
  static List<String> scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

  // Singleton
  NotificationService._();
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  AndroidNotificationChannel? _channel;

  /// Initialize Flutter local notifications and basic messaging helpers.
  /// Note: Do not register `onBackgroundMessage` or message listeners here if you already handle them in `main.dart`.
  Future<void> init() async {
    // Request permissions (iOS/macOS)
    if (Platform.isIOS || Platform.isMacOS) {
      await _messaging.requestPermission(alert: true, badge: true, sound: true);
    }

    // Create an Android notification channel (required for Android 8+)
    _channel = const AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    // Initialize local notifications
    final androidInit = const AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosInit = const DarwinInitializationSettings();

    final settings = InitializationSettings(android: androidInit, iOS: iosInit);
    await flutterLocalNotificationsPlugin.initialize(settings, onDidReceiveNotificationResponse: (response) {
      // You can handle notification tap here. The app can use NotificationService.onNotificationClick handler if exposed.
    });

    // Create channel on Android (idempotent)
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel!);

    // NOTE: Message listeners (onBackgroundMessage/onMessage/onMessageOpenedApp) are intentionally left out
    // so that `main.dart` can register them and perform app-specific actions like saving notifications to Firestore
    // and navigation when a notification is opened.
  }

  Future<void> _showRemoteMessageAsLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final android = message.notification?.android;

    final androidDetails = AndroidNotificationDetails(
      _channel?.id ?? 'high_importance_channel',
      _channel?.name ?? 'High Importance Notifications',
      channelDescription: _channel?.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: android?.smallIcon ?? '@mipmap/ic_launcher',
    );

    final details = NotificationDetails(android: androidDetails, iOS: const DarwinNotificationDetails());

    await flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data['payload']?.toString(),
    );
  }

  /// Returns the FCM token for this device (used by your server to send messages).
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  /// Show a local notification immediately (useful for local reminders)
  Future<void> showNotification({required int id, required String title, required String body, String? payload}) async {
    final androidDetails = AndroidNotificationDetails(
      _channel?.id ?? 'high_importance_channel',
      _channel?.name ?? 'High Importance Notifications',
      channelDescription: _channel?.description,
      importance: Importance.high,
      priority: Priority.high,
    );

    final details = NotificationDetails(android: androidDetails, iOS: const DarwinNotificationDetails());

    await flutterLocalNotificationsPlugin.show(id, title, body, details, payload: payload);
  }

  Future<String> getAccessToken() async {
    // Access tokens for sending downstream FCM messages should be obtained from a trusted server.
    // Do not store service account credentials or generate server access tokens in the client app.
    throw UnsupportedError('getAccessToken is not supported on the client. Obtain access tokens on a secure server.');
  }
}