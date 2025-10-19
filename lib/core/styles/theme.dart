import 'package:flutter/material.dart';
import 'colors.dart';

ThemeData theme = ThemeData(
  drawerTheme: DrawerThemeData(
    backgroundColor: teal900,
  ),
  pageTransitionsTheme: PageTransitionsTheme(
    builders: {
      TargetPlatform.android: ZoomPageTransitionsBuilder(),
      TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
    },
  ),
  colorSchemeSeed: teal100,
  scaffoldBackgroundColor: teal900,
  fontFamily: 'Alexandria',
  appBarTheme: AppBarTheme(
    titleSpacing: 20.0,
    backgroundColor: teal100,
    elevation: 0.0,
    titleTextStyle: TextStyle(
      color: Colors.black,
      fontSize: 20.0,
      fontWeight: FontWeight.bold,
      fontFamily: 'Alexandria',
    ),
    iconTheme: IconThemeData(
      color: Colors.black,
    ),
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    type: BottomNavigationBarType.fixed,
    selectedItemColor: teal100,
    unselectedItemColor: Colors.grey,
    backgroundColor: teal900,
    elevation: 20.0,
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: teal900,
    shape: CircleBorder(),
  ),
  textTheme: TextTheme(
    displayLarge: TextStyle(fontFamily: 'Alexandria'),
    displayMedium: TextStyle(fontFamily: 'Alexandria'),
    displaySmall: TextStyle(fontFamily: 'Alexandria'),
    headlineLarge: TextStyle(fontFamily: 'Alexandria'),
    headlineMedium: TextStyle(fontFamily: 'Alexandria'),
    headlineSmall: TextStyle(fontFamily: 'Alexandria'),
    titleLarge: TextStyle(fontFamily: 'Alexandria'),
    titleMedium: TextStyle(fontFamily: 'Alexandria'),
    titleSmall: TextStyle(fontFamily: 'Alexandria'),
    bodyLarge: TextStyle(fontFamily: 'Alexandria'),
    bodyMedium: TextStyle(
      fontFamily: 'Alexandria',
      fontSize: 14.0,
      // fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
    bodySmall: TextStyle(fontFamily: 'Alexandria'),
    labelLarge: TextStyle(fontFamily: 'Alexandria'),
    labelMedium: TextStyle(fontFamily: 'Alexandria'),
    labelSmall: TextStyle(fontFamily: 'Alexandria'),
  ),
  buttonTheme: ButtonThemeData(
    buttonColor: teal100,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10.0),
    ),
    textTheme: ButtonTextTheme.primary,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      minimumSize: Size(double.infinity, 50),
      backgroundColor: teal100,
      foregroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      textStyle: TextStyle(
        fontSize: 18.0,
        fontWeight: FontWeight.bold,
        fontFamily: 'Alexandria',
      ),
    ),
  ),
  tabBarTheme: TabBarThemeData(
    labelColor: Colors.white,
    unselectedLabelColor: Colors.white70,
    labelStyle: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      fontFamily: 'Alexandria',
    ),
    unselectedLabelStyle: TextStyle(
      fontSize: 14,
      fontFamily: 'Alexandria',
    ),
    indicator: UnderlineTabIndicator(
      borderSide: BorderSide(color: Colors.white, width: 2.0),
      insets: EdgeInsets.symmetric(horizontal: 16.0),
    ),
  ),

);