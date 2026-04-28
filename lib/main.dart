import 'dart:async'; // 👈 For unawaited()
import 'dart:convert'; // 👈 For jsonEncode in health check
import 'package:church/core/blocs/admin_user/admin_user_cubit.dart';
import 'package:church/modules/Splash/splash_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http; // 👈 For health check
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'core/blocs/auth/auth_cubit.dart';
import 'core/network/local/cache_helper.dart';
import 'core/providers/cart_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/repositories/local_attendance_repository.dart';
import 'core/repositories/local_points_repository.dart';
import 'core/services/points_sync_service.dart';
import 'core/utils/notification_service.dart'; // ✅ Your updated service
import 'firebase_options.dart';
import 'shared/bloc_observer.dart';

// ============ NotificationService Singleton ============
NotificationService? _notificationServiceInstance;

NotificationService get notificationService {
  _notificationServiceInstance ??= NotificationService();
  return _notificationServiceInstance!;
}

// ============ Local Notifications Setup ============
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

final AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'This channel is used for important notifications.',
  importance: Importance.high,
);

// ============ Helper: Show Local Notification ============
Future<void> showLocalNotification(RemoteMessage message) async {
  final notification = message.notification;
  final data = message.data;

  final title = notification?.title ?? data['title'];
  final body = notification?.body ??
      data['body'] ??
      data['message'] ??
      data['body_text'] ??
      'You have a new message';
  final payload = data['click_action'] ?? data['payload'];

  try {
    // Use the service's method for consistent notification display
    await notificationService.showNotification(
      id: message.hashCode,
      title: title ?? '',
      body: body,
      payload: payload?.toString(),
    );
  } catch (e) {
    // Fallback to direct platform call
    final androidDetails = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    final platformDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      message.hashCode,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }
}

// ============ FCM Token Registration Helper ============
Future<void> registerTokenToFirestore(String uid, String? token) async {
  if (token == null || token.isEmpty) {
    // ignore: avoid_print
    print('⚠️ FCM token is null or empty — skipping registration');
    return;
  }

  // ignore: avoid_print
  print('📱 FCM device token for $uid: $token');

  try {
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

    // Store the latest token for this user
    await userRef.set({
      'fcmToken': token, // ✅ correct name
      'fcmTokens': FieldValue.arrayUnion([token]), // ✅ correct type (array)
      'fcmTokenLastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // ignore: avoid_print
    print('✅ FCM token registered for user $uid');
    debugPrint('✅ FCM token registered for user $uid');
  } catch (e) {
    // ignore: avoid_print
    print('❌ Failed to register FCM token: $e');
  }
}

// ============ Background Message Handler ============
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize local notifications in background isolate
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin
  >()
      ?.createNotificationChannel(channel);

  // ✅ Save notification to Firestore via service
  try {
    await notificationService.saveNotificationFromRemoteMessage(message);
  } catch (e) {
    // ignore: avoid_print
    print('❌ Failed to save notification via service: $e');
  }

  // Show local notification
  try {
    await showLocalNotification(message);
  } catch (e) {
    // ignore: avoid_print
    print('❌ Failed to show local notification: $e');
  }
}

// ============ Workmanager Background Task ============
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp();
      await LocalPointsRepository.init();

      if (task == 'syncPendingAttendance') {
        final pointsSync = PointsSyncService();
        await pointsSync.syncPendingTransactions();
      }
      return Future.value(true);
    } catch (e) {
      // ignore: avoid_print
      print('❌ Workmanager task error: $e');
      return Future.value(false);
    }
  });
}

// ============ 🔔 Edge Function Health Check (Non-Blocking) ============
Future<void> checkNotificationServiceHealth() async {
  try {
    final functionUrl = const String.fromEnvironment(
      'SUPABASE_NOTIFICATION_URL',
      defaultValue: 'https://pfytemzrsgcptoxqywjs.supabase.co/functions/v1/send-notification',
    );
    final adminApiKey = const String.fromEnvironment('ADMIN_API_KEY', defaultValue: '');

    if (adminApiKey.isEmpty) {
      // ignore: avoid_print
      print('⚠️ ADMIN_API_KEY not set — skipping Edge Function health check');
      return;
    }

    // Lightweight POST ping (more reliable than OPTIONS)
    final response = await http.post(
      Uri.parse(functionUrl),
      headers: {
        'Content-Type': 'application/json',
        'apikey': adminApiKey,
      },
      body: jsonEncode({'_healthCheck': true}),
    ).timeout(const Duration(seconds: 5));

    final reachable = [200, 400, 401].contains(response.statusCode);

    // ignore: avoid_print
    print('🔔 Edge Function health check: ${reachable ? '✅ OK' : '❌ FAILED'} (status: ${response.statusCode})');

    // Optional: Alert admin users if unreachable
    if (!reachable) {
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      if (currentUid != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUid).get();
        final isAdmin = userDoc.data()?['isAdmin'] == true || userDoc.data()?['userType'] == 'PR';

        if (isAdmin) {
          // ignore: avoid_print
          print('⚠️ Admin user detected: Notification service unreachable');
          // Optional: Set flag for UI warning
          // await CacheHelper.setNotificationServiceDown(true);
        }
      }
    }
  } on TimeoutException {
    // ignore: avoid_print
    print('⏱️ Edge Function health check timed out');
  } on http.ClientException catch (e) {
    // ignore: avoid_print
    print('🌐 Network error checking Edge Function: $e');
  } catch (e) {
    // ignore: avoid_print
    print('❓ Unexpected error in health check: $e');
  }
}

// ============ Main Entry Point ============
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 1. Register token when app starts (if user is signed in)
  final currentUid = FirebaseAuth.instance.currentUser?.uid;
  if (currentUid != null) {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await registerTokenToFirestore(currentUid, token);
    }
  }

  // ============ Mobile-Only Initialization ============
  if (!kIsWeb) {




    // 2. Register token when it refreshes (e.g., after app reinstall)
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await registerTokenToFirestore(uid, newToken);
      }
    });

    // 3. Re-register token when user signs in (handles token changes during session)
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user != null) {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          await registerTokenToFirestore(user.uid, token);
        }
      }
    });

    try {
      // Initialize local storage (Hive)
      await LocalAttendanceRepository.init();
      await LocalPointsRepository.init();
      // ignore: avoid_print
      print('✅ Local storage initialized');

      // Clean up old pending items (optional)
      final attendanceRepo = LocalAttendanceRepository();
      final attendanceDeleted = await attendanceRepo.deleteOldPending(olderThanDays: 30);
      if (attendanceDeleted > 0) {
        // ignore: avoid_print
        print('🗑️ Deleted $attendanceDeleted old pending attendance items');
      }

      final pointsRepo = LocalPointsRepository();
      final pointsDeleted = await pointsRepo.deleteOldPending(olderThanDays: 30);
      if (pointsDeleted > 0) {
        // ignore: avoid_print
        print('🗑️ Deleted $pointsDeleted old pending points items');
      }

      // Log stats
      // ignore: avoid_print
      print('📊 Attendance stats: ${attendanceRepo.getStatistics()}');
      // ignore: avoid_print
      print('📊 Points stats: ${pointsRepo.getStatistics()}');
    } catch (e, st) {
      // ignore: avoid_print
      print('❌ Initialization error: $e');
      // ignore: avoid_print
      print(st);
    }

    // ============ Workmanager Setup ============
    try {
      await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
      await Workmanager().registerPeriodicTask(
        'church_sync_pending_attendance',
        'syncPendingAttendance',
        frequency: const Duration(minutes: 15),
      );
    } catch (e, st) {
      // ignore: avoid_print
      print('⚠️ Workmanager initialization error: $e');
      // ignore: avoid_print
      print(st);
    }

    // Register current token if user signed in
    if (currentUid != null) {
      final token = await FirebaseMessaging.instance.getToken();
      await registerTokenToFirestore(currentUid, token);
    }

    // Listen for token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await registerTokenToFirestore(uid, newToken);
      }
    });

    // Request iOS permissions
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    // Show notifications in foreground on iOS
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // ============ Local Notifications Initialization ============
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap (optional: navigate to screen)
      },
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
    >()
        ?.createNotificationChannel(channel);

    // Register background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // ============ FCM Message Listeners ============

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      try {
        // Save to Firestore via service
        await notificationService.saveNotificationFromRemoteMessage(message);
        // Show local notification
        await showLocalNotification(message);
      } catch (e, st) {
        // ignore: avoid_print
        print('❌ onMessage handling error: $e');
        // ignore: avoid_print
        print(st);
      }
    });

    // App opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Optional: Navigate to specific screen based on message.data
      // saveNotificationToFirestore is already called in background handler
    });

    // ============ Remote Config Setup ============
    final remoteConfig = FirebaseRemoteConfig.instance;
    try {
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 5),
          minimumFetchInterval: const Duration(seconds: 5),
        ),
      );
      await remoteConfig.fetchAndActivate().timeout(
        const Duration(seconds: 5),
        onTimeout: () => false,
      );
    } catch (e, st) {
      // ignore: avoid_print
      print('⚠️ RemoteConfig error: $e');
      // ignore: avoid_print
      print(st);
    }
  }

  // ============ Initialize Cache ============
  await CacheHelper.init();

  // ============ Bloc Observer ============
  Bloc.observer = MyBlocObserver();

  // ============ 🔔 Run Health Check (Non-Blocking) ============
  unawaited(checkNotificationServiceHealth());

  // ============ Run App ============
  runApp(const MyApp(startWidget: SplashScreen()));
}

// ============ App Widget ============
class MyApp extends StatefulWidget {
  final Widget startWidget;
  const MyApp({super.key, required this.startWidget});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final PointsSyncService _syncService = PointsSyncService();
  bool _hasShownSyncNotification = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _setupConnectivityListener();
    }
  }

  void _setupConnectivityListener() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) async {
      final isOnline = results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.ethernet);

      if (isOnline) {
        await Future.delayed(const Duration(seconds: 2)); // Stabilize connection

        final pendingCount = LocalPointsRepository().getPendingCount();
        if (pendingCount > 0) {
          final result = await _syncService.syncPendingTransactions();

          if (mounted && result['synced']! > 0 && !_hasShownSyncNotification) {
            _hasShownSyncNotification = true;
            // Optional: Show toast/snackbar here
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => AuthCubit()),
        BlocProvider(create: (context) => AdminUserCubit()),
      ],
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CartProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return MaterialApp(
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [Locale('ar')],
              debugShowCheckedModeBanner: false,
              theme: themeProvider.currentTheme,
              home: widget.startWidget,
            );
          },
        ),
      ),
    );
  }
}