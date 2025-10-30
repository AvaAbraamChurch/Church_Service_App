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

// Use the navigator key from NotificationsService
// final GlobalKey<NavigatorState> navigatorKey = NotificationsService.navigatorKey;

// Create a FlutterLocalNotificationsPlugin instance to show local notifications
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
  print('showLocalNotification() called. notification=${notification?.toString()}, data=$data');

  final title = notification?.title ?? data['title'];
  // fallback to other common keys or default text
  final body = notification?.body ?? data['body'] ?? data['message'] ?? data['body_text'] ?? 'You have a new message';

  final androidDetails = AndroidNotificationDetails(
    channel.id,
    channel.name,
    channelDescription: channel.description,
    importance: Importance.max,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  );

  final platformDetails = NotificationDetails(android: androidDetails);

  // Use message.hashCode as a simple id (or parse a specific id from data)
  await flutterLocalNotificationsPlugin.show(
    message.hashCode,
    title,
    body,
    platformDetails,
    payload: data['click_action'] ?? data['payload'],
  );
}

// Top-level background message handler (must be a top-level function)
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

  // Debug: log the message and attempt to show a local notification
  try {
    print('Background handler received message: id=${message.messageId}, data=${message.data}, notification=${message.notification}');
    await showLocalNotification(message);
    print('Background handler displayed local notification for messageId=${message.messageId}');
  } catch (e, st) {
    print('Background handler failed to display notification: $e\n$st');
  }
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // If user is signed in, save the device FCM token to their user doc
  void registerTokenToFirestore(String uid, String? token) async {
    if (token == null || token.isEmpty) return;
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    try {
      await userRef.set({
        'fcmTokens': FieldValue.arrayUnion([token])
      }, SetOptions(merge: true));
      print('Saved FCM token for user $uid');
    } catch (e) {
      print('Failed saving FCM token: $e');
    }
  }

  // When token refreshes, update Firestore
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    print('FCM token refreshed: $newToken');
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) registerTokenToFirestore(uid, newToken);
  });

  // If user already signed in, register current token
  final currentUid = FirebaseAuth.instance.currentUser?.uid;
  if (currentUid != null) {
    final token = await FirebaseMessaging.instance.getToken();
    print('Current FCM token: $token');
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
  print('User granted permission: ${settings.authorizationStatus}');

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

  // Listen for messages when the app is in the foreground
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    print('onMessage (foreground) received: id=${message.messageId}, data=${message.data}, notification=${message.notification}');
     // If a notification payload is present (notification/title/body), show it
     try {
       await showLocalNotification(message);
     } catch (e) {
       // log and continue
       print('Error showing local notification: $e');
     }
   });

   // Handle when app is opened from a notification
   FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
     // Handle navigation / payload processing here
     print('Message clicked! payload: ${message.data}');
   });

  final remoteConfig = FirebaseRemoteConfig.instance;
  try {
    await remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 60),
      minimumFetchInterval: const Duration(hours: 1),
    ));
    await remoteConfig.fetchAndActivate();
  } catch (e) {
    // avoid crashing on plugin issues; log and continue
    print('`Remote Config fetch/activate failed`: $e');
  }



  // Initialize cache helper
  await CacheHelper.init();

  Bloc.observer = MyBlocObserver();

  runApp(const MyApp(
    startWidget: SplashScreen(),
  ));
}

class MyApp extends StatelessWidget {
  final Widget startWidget;

  const MyApp({super.key, required this.startWidget});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthCubit(),
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
              home: startWidget,
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
//       print('Cache cleared successfully');
//     }
//   } catch (e) {
//     print('Error clearing cache: $e');
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
//     print('Error calculating folder size: $e');
//   }
//   return size;
// }
