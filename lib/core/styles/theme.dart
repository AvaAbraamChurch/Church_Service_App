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
    bodyMedium: TextStyle(
      fontFamily: 'Alexandria',
      fontSize: 14.0,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
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
);