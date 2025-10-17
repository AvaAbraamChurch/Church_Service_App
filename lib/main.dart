import 'package:church/core/models/user/user_model.dart';
import 'package:church/core/utils/gender_enum.dart';
import 'package:church/core/utils/userType_enum.dart';
import 'package:church/layout/home_layout.dart';
import 'package:church/modules/Auth/login/login_screen.dart';
import 'package:church/shared/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/styles/theme.dart';
import 'shared/bloc_observer.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/network/local/cache_helper.dart';
import 'core/repositories/auth_repository.dart';

// Use the navigator key from NotificationsService
// final GlobalKey<NavigatorState> navigatorKey = NotificationsService.navigatorKey;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize cache helper
  await CacheHelper.init();

  // Check the firebase token validation
  final authRepository = AuthRepository();
  bool isTokenValid = false;
  String uId = '';

  // Check if user has cached login data
  bool isLoggedIn = authRepository.isLoggedInFromCache();
  uId = authRepository.getSavedUserId();


  // If user appears to be logged in, validate the Firebase token
  if (isLoggedIn && uId.isNotEmpty) {
    isTokenValid = await authRepository.validateToken();

    if (isTokenValid) {
      print('✅ Firebase token is valid. User ID: $uId');
    } else {
      print('❌ Firebase token validation failed. Redirecting to login.');
      // Clear invalid cached data
      await authRepository.clearUserData();
      uId = '';
      isLoggedIn = false;
    }
  }

  Bloc.observer = MyBlocObserver();

  Widget widget;

  // Decide which screen to show based on token validation
  if (isTokenValid && uId.isNotEmpty) {
    final UserModel currentUser = await authRepository.getCurrentUserData();
    widget = HomeLayout(userId: uId, userType: currentUser.userType.label, userClass: currentUser.userClass, gender: currentUser.gender.label,);
    print('Navigating to main layout for authenticated user');
  } else {
    widget = LoginScreen();
    print('Navigating to login screen');
  }

  runApp(MyApp(
    startWidget: widget,
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
