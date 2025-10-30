import 'package:flutter/material.dart';
import '../utils/remote config/remote_config.dart';

// Default background image (used as fallback)
const String _kDefaultBackgroundImage = 'assets/images/bg.png';

class ThemedScaffold extends StatelessWidget {
  final Widget? body;
  final Widget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonAnimator? floatingActionButtonAnimator;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? drawer;
  final String? backgroundImagePath; // Made nullable to allow remote config default

  const ThemedScaffold({
    super.key,
    this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonAnimator,
    this.floatingActionButtonLocation,
    this.drawer,
    this.backgroundImagePath, // Optional: uses remote config if not provided
  });

  @override
  Widget build(BuildContext context) {
    // Get background image from Remote Config if not explicitly provided
    final remoteConfig = RemoteConfigService();
    final String effectiveBackgroundImage = backgroundImagePath ??
        remoteConfig.scaffoldBackgroundImage;

    return Stack(
      children: [
        // 1. Background Image
        Positioned.fill(
          child: Image.asset(
            effectiveBackgroundImage,
            fit: BoxFit.cover, // Ensures the image covers the entire screen
            errorBuilder: (context, error, stackTrace) {
              // Fallback to default background if image fails to load
              return Image.asset(
                _kDefaultBackgroundImage,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // If even the default fails, show a colored background
                  return Container(
                    color: remoteConfig.scaffoldBackgroundColor,
                  );
                },
              );
            },
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
          floatingActionButtonAnimator: floatingActionButtonAnimator,
          floatingActionButtonLocation: floatingActionButtonLocation,
          drawer: drawer,
        ),
      ],
    );
  }
}