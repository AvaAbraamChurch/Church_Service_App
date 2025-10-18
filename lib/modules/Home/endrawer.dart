import 'package:church/core/blocs/auth/auth_cubit.dart';
import 'package:church/modules/Auth/login/login_screen.dart';
import 'package:church/shared/widgets.dart';
import 'package:flutter/material.dart';
import '../../core/styles/colors.dart';

Widget drawer(context) => Drawer(
  width: MediaQuery.of(context).size.width * 0.75, // Set drawer width to 75% of screen width
  shadowColor: Colors.grey,
  child: Stack(
    fit: StackFit.expand,
    children: [
      Positioned.fill(
        child: Image.asset(
          'assets/images/bg.png',
          fit: BoxFit.cover, // Ensures the image covers the entire screen
        ),
      ),
      ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(color: teal300),
            child: Text(
              'القائمة',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: Icon(Icons.home, color: Colors.white),
            title: Text('الرئيسية', style: TextStyle(color: Colors.white),),
            onTap: () {
              // Handle navigation to home
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.settings, color: Colors.white),
            title: Text('الإعدادات', style: TextStyle(color: Colors.white)),
            onTap: () {
              // Handle navigation to settings
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.white,),
            title: Text('تسجيل الخروج', style: TextStyle(color: Colors.white)),
            onTap: () {
              // Handle logout
              AuthCubit().logOut().then((value){
                navigateAndFinish(context, LoginScreen());
              });
            },
          ),
        ],
      )
    ],
  ),
);
