import 'package:church/modules/Splash/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/styles/theme.dart';
import 'shared/bloc_observer.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/network/local/cache_helper.dart';
import 'shared/connectivity_wrapper.dart';

// Use the navigator key from NotificationsService
// final GlobalKey<NavigatorState> navigatorKey = NotificationsService.navigatorKey;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
      theme: theme,
      home: startWidget,
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
