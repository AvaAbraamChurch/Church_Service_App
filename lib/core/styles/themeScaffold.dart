import 'package:flutter/material.dart';

// You will need to replace 'assets/images/background.png' with your image path.
const String _kDefaultBackgroundImage = 'assets/images/bg.png';

class ThemedScaffold extends StatelessWidget {
  final Widget? body;
  final Widget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Widget? drawer;
  final String backgroundImagePath;

  const ThemedScaffold({
    super.key,
    this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.drawer,
    this.backgroundImagePath = _kDefaultBackgroundImage, // Default image
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Background Image
        Positioned.fill(
          child: Image.asset(
            backgroundImagePath,
            fit: BoxFit.cover, // Ensures the image covers the entire screen
          ),
        ),

        // 2. The Actual Scaffold
        Scaffold(
          // Set the background color to transparent so the image is visible
          backgroundColor: Colors.transparent,

          // Use the rest of the properties from the parent widget
          appBar: appBar as PreferredSizeWidget?,
          body: body,
          bottomNavigationBar: bottomNavigationBar,
          floatingActionButton: floatingActionButton,
          drawer: drawer,
          // You can also apply the themed colors here if needed
          // or rely on the theme you defined for AppBar, Nav Bar, etc.
        ),
      ],
    );
  }
}