import 'package:church/core/blocs/admin_user/admin_user_cubit.dart';
import 'package:church/modules/Splash/splash_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'shared/bloc_observer.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/network/local/cache_helper.dart';
import 'core/providers/cart_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/blocs/auth/auth_cubit.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'core/repositories/local_attendance_repository.dart';
import 'core/repositories/local_points_repository.dart';
import 'core/services/points_sync_service.dart';
import 'package:workmanager/workmanager.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'core/utils/notification_service.dart';

// Create a FlutterLocalNotificationsPlugin instance to show local notifications in background isolate
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Define an Android notification channel (for Android 8.0+)
final AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // id
  'High Importance Notifications', // title
  description:
      'This channel is used for important notifications.', // description
  importance: Importance.high,
);

// Helper to show a local notification from a RemoteMessage
Future<void> showLocalNotification(RemoteMessage message) async {
  final notification = message.notification;
  final data = message.data;

  // Debug log: print incoming message payload
  debugPrint('showLocalNotification() called. notification=${notification?.toString()}, data=$data');

  final title = notification?.title ?? data['title'];
  // fallback to other common keys or default text
  final body = notification?.body ?? data['body'] ?? data['message'] ?? data['body_text'] ?? 'You have a new message';

  final payload = data['click_action'] ?? data['payload'];

  // Delegate to NotificationService to display a consistent local notification
  try {
    await NotificationService().showNotification(id: message.hashCode, title: title ?? '', body: body, payload: payload?.toString());
  } catch (e) {
    debugPrint('Failed to show notification via NotificationService: $e');
    // Fallback to direct platform call if needed
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

// Top-level background message handler (must be a top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Flutter & Firebase in background isolate
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize the local notifications plugin in the background isolate
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Create the channel on the background isolate as well
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // Save notification to Firestore
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId != null) {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': message.notification?.title ?? message.data['title'] ?? 'إشعار جديد',
        'body': message.notification?.body ?? message.data['body'] ?? '',
        'imageUrl': message.notification?.android?.imageUrl ?? message.data['imageUrl'],
        'data': message.data,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'userId': userId,
        'type': message.data['type'] ?? 'message',
        'actionUrl': message.data['actionUrl'],
      });
      debugPrint('Background: Notification saved to Firestore for user $userId');
    } catch (e) {
      debugPrint('Background: Failed to save notification to Firestore: $e');
    }
  }

  // Debug: log the message and attempt to show a local notification
  try {
    debugPrint('Background handler received message: id=${message.messageId}, data=${message.data}, notification=${message.notification}');
    await showLocalNotification(message);
    debugPrint('Background handler displayed local notification for messageId=${message.messageId}');
  } catch (e, st) {
    debugPrint('Background handler failed to display notification: $e\n$st');
  }
}

// Background task callback for Workmanager. This runs on a background isolate.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Ensure Flutter binding exists in background isolate
      WidgetsFlutterBinding.ensureInitialized();

      // Initialize Firebase
      await Firebase.initializeApp();

      // Initialize Hive and Repositories
      await LocalPointsRepository.init();

      // Sync pending points in background
      if (task == 'syncPendingAttendance') {
        final pointsSync = PointsSyncService();
        final result = await pointsSync.syncPendingTransactions();

        debugPrint('✅ Background points sync completed: ${result['synced']} synced, ${result['failed']} failed');
      }

      return Future.value(true);
    } catch (e) {
      debugPrint('❌ Background sync failed: $e');
      return Future.value(false);
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );


  try {
    // Initialize Local Storage (Hive)
    await LocalAttendanceRepository.init();
    await LocalPointsRepository.init();
    print('✅ Local storage initialized');

    // Optional: Clean up old pending items (older than 30 days)
    final attendanceRepo = LocalAttendanceRepository();
    final attendanceDeletedCount = await attendanceRepo.deleteOldPending(olderThanDays: 30);
    if (attendanceDeletedCount > 0) {
      print('🗑️ Deleted $attendanceDeletedCount old pending attendance items');
    }

    final pointsRepo = LocalPointsRepository();
    final pointsDeletedCount = await pointsRepo.deleteOldPending(olderThanDays: 30);
    if (pointsDeletedCount > 0) {
      print('🗑️ Deleted $pointsDeletedCount old pending points items');
    }

    // Show statistics
    final attendanceStats = attendanceRepo.getStatistics();
    final pointsStats = pointsRepo.getStatistics();
    print('📊 Attendance storage stats: $attendanceStats');
    print('📊 Points storage stats: $pointsStats');

  } catch (e) {
    print('❌ Initialization error: $e');
  }



  // Initialize Workmanager to run periodic background sync (optional - graceful failure)
  try {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );

    // Register a periodic task to sync pending attendance every 15 minutes (Android minimum)
    await Workmanager().registerPeriodicTask(
      'church_sync_pending_attendance',
      'syncPendingAttendance',
      frequency: const Duration(minutes: 15),
    );
    debugPrint('Workmanager initialized successfully for background sync');
  } catch (e) {
    // Workmanager failed - app will still work with foreground sync via connectivity listener
    debugPrint('Workmanager initialization failed (background sync disabled): $e');
    debugPrint('Offline attendance will still work - sync will happen when app is open');
  }

  // If user is signed in, save the device FCM token to their user doc
  void registerTokenToFirestore(String uid, String? token) async {
    if (token == null || token.isEmpty) return;
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    try {
      await userRef.set({
        'fcmTokens': FieldValue.arrayUnion([token])
      }, SetOptions(merge: true));
      debugPrint('Saved FCM token for user $uid');
    } catch (e) {
      debugPrint('Failed saving FCM token: $e');
    }
  }

  // When token refreshes, update Firestore
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    debugPrint('FCM token refreshed: $newToken');
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) registerTokenToFirestore(uid, newToken);
  });

  // If user already signed in, register current token
  final currentUid = FirebaseAuth.instance.currentUser?.uid;
  if (currentUid != null) {
    final token = await FirebaseMessaging.instance.getToken();
    debugPrint('Current FCM token: $token');
    registerTokenToFirestore(currentUid, token);
  }

  // Request notification permissions (iOS) and show what the user allowed.
  // On Android 13+ the app still needs the POST_NOTIFICATIONS runtime permission
  // which you may need to request separately if targeting SDK 33+. This call
  // is important for iOS to allow foreground notifications.
  final settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );
  debugPrint('User granted permission: ${settings.authorizationStatus}');

  // On iOS, show notifications when app is in foreground
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // Initialize the flutter_local_notifications plugin and create channel
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
    // Handle notification tap when app is in foreground/background
    // You can navigate using a navigatorKey or handle payload here
    // final payload = response.payload;
  });

  // Create Android notification channel for heads-up notifications
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // Register background handler once, before runApp
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Helper to save notifications to Firestore
  Future<void> saveNotificationToFirestore(RemoteMessage message) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': message.notification?.title ?? message.data['title'] ?? 'إشعار جديد',
        'body': message.notification?.body ?? message.data['body'] ?? '',
        'imageUrl': message.notification?.android?.imageUrl ?? message.data['imageUrl'],
        'data': message.data,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'userId': userId,
        'type': message.data['type'] ?? 'message',
        'actionUrl': message.data['actionUrl'],
      });
      debugPrint('Notification saved to Firestore for user $userId');
    } catch (e) {
      debugPrint('Failed to save notification to Firestore: $e');
    }
  }

  // Listen for messages when the app is in the foreground
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    debugPrint('onMessage (foreground) received: id=${message.messageId}, data=${message.data}, notification=${message.notification}');
     // If a notification payload is present (notification/title/body), show it
     try {
       await showLocalNotification(message);
       await saveNotificationToFirestore(message);
     } catch (e) {
       // log and continue
       debugPrint('Error showing local notification: $e');
     }
   });

   // Handle when app is opened from a notification
   FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
     // Handle navigation / payload processing here
     debugPrint('Message clicked! payload: ${message.data}');
     saveNotificationToFirestore(message);
   });

  final remoteConfig = FirebaseRemoteConfig.instance;
  try {
    await remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: const Duration(seconds: 5),
    ));

    // Add timeout protection to prevent hanging
    await remoteConfig.fetchAndActivate().timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        debugPrint('Remote Config fetch timed out - using defaults');
        return false;
      },
    );
    debugPrint('Remote Config fetched and activated.');
  } catch (e) {
    // avoid crashing on plugin issues; log and continue
    debugPrint('Remote Config fetch/activate failed: $e');
  }



  // Initialize cache helper
  await CacheHelper.init();

  Bloc.observer = MyBlocObserver();

  runApp(const MyApp(
    startWidget: SplashScreen(),
  ));
}

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
    _setupConnectivityListener();
  }

  void _setupConnectivityListener() {
    // Listen to connectivity changes and auto-sync when online
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) async {
      final isOnline = results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.ethernet);

      if (isOnline) {
        // Wait a bit for connection to stabilize
        await Future.delayed(const Duration(seconds: 2));

        // Check if there are pending items to sync
        final pendingCount = LocalPointsRepository().getPendingCount();
        if (pendingCount > 0) {
          debugPrint('🔄 Connection restored. Syncing $pendingCount pending points...');

          final result = await _syncService.syncPendingTransactions();

          debugPrint('✅ Auto-sync completed: ${result['synced']} synced, ${result['failed']} failed');

          // Show notification only once per app session if sync was successful
          if (mounted && result['synced'] > 0 && !_hasShownSyncNotification) {
            _hasShownSyncNotification = true;
            // Note: ScaffoldMessenger needs a scaffold context, so we'll just log for now
            // You can show a toast or notification here if needed
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthCubit(),
        ),

        BlocProvider(
          create: (context) => AdminUserCubit(),
        ),

      ],
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CartProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return MaterialApp(
              // navigatorKey: navigatorKey, // This now uses the NotificationsService navigator key
              localizationsDelegates: [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: [
                Locale('ar'),
              ],
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
//
// Future<void> clearOldCache() async {
//   try {
//     final dir = await getTemporaryDirectory();
//     final size = await _getFolderSize(dir);
//
//     if (size > 10 * 1024 * 1024) { // 10MB threshold
//       final files = dir.listSync();
//       for (final file in files) {
//         if (file is File) {
//           await file.delete();
//         } else if (file is Directory) {
//           await file.delete(recursive: true);
//         }
//       }
//       debugPrint('Cache cleared successfully');
//     }
//   } catch (e) {
//     debugPrint('Error clearing cache: $e');
//   }
// }
//
// // Helper function to calculate folder size
// Future<int> _getFolderSize(Directory dir) async {
//   var size = 0;
//   try {
//     final files = dir.listSync(recursive: true);
//     for (final file in files) {
//       if (file is File) {
//         size += await file.length();
//       }
//     }
//   } catch (e) {
//     debugPrint('Error calculating folder size: $e');
//   }
//   return size;
// }
