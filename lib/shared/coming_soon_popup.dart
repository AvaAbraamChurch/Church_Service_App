import 'package:flutter/material.dart';
import '../core/styles/colors.dart';

/// A modern and attractive "Coming Soon" popup dialog
///
/// Usage:
/// ```dart
/// showComingSoonPopup(
///   context,
///   title: 'القداس الإلهي',
///   message: 'هذه الميزة ستكون متاحة قريباً',
/// );
/// ```
class ComingSoonPopup extends StatelessWidget {
  final String? title;
  final String? message;
  final IconData? icon;
  final String? svgAsset;

  const ComingSoonPopup({
    super.key,
    this.title,
    this.message,
    this.icon,
    this.svgAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              teal500,
              teal300,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: teal500.withValues(alpha: 0.4),
              blurRadius: 30,
              spreadRadius: 5,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated icon container
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Pulsing background effect
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.8, end: 1.0),
                      duration: const Duration(seconds: 1),
                      curve: Curves.easeInOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: teal100.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      },
                      onEnd: () {
                        // This creates a continuous pulsing effect
                      },
                    ),
                    Icon(
                      icon ?? Icons.schedule,
                      size: 50,
                      color: teal700,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // "Coming Soon" Title with gradient shimmer effect
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [
                  Colors.white,
                  Color(0xFFFFF8E7),
                  Colors.white,
                ],
                stops: [0.0, 0.5, 1.0],
              ).createShader(bounds),
              child: const Text(
                'قريباً',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Alexandria',
                  letterSpacing: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 8),

            // Subtitle "Coming Soon" in English
            Text(
              'Coming Soon',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.9),
                letterSpacing: 2,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            // Optional custom title
            if (title != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  title!,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Alexandria',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Message
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                message ?? 'نحن نعمل على إطلاق هذه الميزة\nالمثيرة قريباً. ترقبوا!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.95),
                  fontFamily: 'Alexandria',
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 24),

            // Decorative dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: teal700,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 8,
                  shadowColor: Colors.black.withValues(alpha: 0.3),
                ),
                child: const Text(
                  'حسناً',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Alexandria',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper function to show the Coming Soon popup
///
/// Example:
/// ```dart
/// showComingSoonPopup(
///   context,
///   title: 'القداس الإلهي',
///   message: 'سيتم إطلاق هذه الميزة في التحديث القادم',
/// );
/// ```
void showComingSoonPopup(
  BuildContext context, {
  String? title,
  String? message,
  IconData? icon,
  String? svgAsset,
}) {
  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (context) => ComingSoonPopup(
      title: title,
      message: message,
      icon: icon,
      svgAsset: svgAsset,
    ),
  );
}

