import 'package:church/core/styles/colors.dart';
import 'package:church/core/styles/themeScaffold.dart';
import 'package:church/layout/home_layout.dart';
import 'package:church/modules/Auth/login/login_screen.dart';
import 'package:church/core/repositories/auth_repository.dart';
import 'package:church/core/utils/userType_enum.dart';
import 'package:church/core/utils/gender_enum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final AuthRepository _authRepository = AuthRepository();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    // Navigate after splash screen delay
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    // Show splash screen for 3 seconds
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // Check authentication status
    final isLoggedIn = _authRepository.isLoggedInFromCache();
    final userId = _authRepository.getSavedUserId();

    if (isLoggedIn && userId.isNotEmpty) {
      // Validate token
      final isTokenValid = await _authRepository.validateToken();

      if (isTokenValid) {
        // Get user data and navigate to home
        final currentUser = await _authRepository.getCurrentUserData();

        if (!mounted) return;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomeLayout(
              userId: userId,
              userType: currentUser.userType.label,
              userClass: currentUser.userClass,
              gender: currentUser.gender.label,
            ),
          ),
        );
      } else {
        // Token invalid, clear data and go to login
        await _authRepository.clearUserData();

        if (!mounted) return;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => LoginScreen(),
          ),
        );
      }
    } else {
      // Not logged in, go to login
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => LoginScreen(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemedScaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.1,),
            // App Logo/Title
            Expanded(
              child: const Text(
                'Ⲛⲉⲛϣⲏⲣⲓ ⲙ̀ⲡⲟⲩⲣⲟ',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.1),

            // Circular Loading Animation with SVG Images
            SizedBox(
              width: 240,
              height: 240,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Rotating SVG icons in circular pattern
                      ..._buildRotatingIcons(),
                      // Center glowing circle
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: teal300,
                          boxShadow: [
                            BoxShadow(
                              color: teal500.withValues(alpha: 0.5),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            SizedBox(height: MediaQuery.of(context).size.height * 0.1),

            // Loading Text
            Text(
              'جاري التحميل...',
              style: TextStyle(
                fontSize: 16,
                color: teal100,
                letterSpacing: 1,
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.1),
            // Footer SVG

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: SvgPicture.asset('assets/svg/footer.svg'),
              ),
            )

          ],
        ),
      ),
    );
  }

  List<Widget> _buildRotatingIcons() {
    final List<String> svgAssets = [
      'assets/svg/4mamsa.svg',
      'assets/svg/book.svg',
      'assets/svg/church.svg',
      'assets/svg/sunday school.svg',
    ];

    final List<Widget> widgets = [];
    final radius = 90.0;
    final center = 120.0;

    for (int i = 0; i < svgAssets.length; i++) {
      final angle = (2 * pi * i / svgAssets.length) + (_controller.value * 2 * pi);
      final x = center + radius * cos(angle);
      final y = center + radius * sin(angle);

      // Calculate opacity and size based on position for 3D effect
      final normalizedAngle = (angle % (2 * pi));
      final opacity = 0.4 + 0.6 * ((cos(normalizedAngle) + 1) / 2);
      final scale = 0.7 + 0.3 * ((cos(normalizedAngle) + 1) / 2);

      widgets.add(
        Positioned(
          left: x - 30,
          top: y - 30,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 100),
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: teal100.withValues(alpha: 0.9),
                  border: Border.all(
                    color: teal300.withValues(alpha: opacity),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: teal500.withValues(alpha: opacity * 0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: SvgPicture.asset(
                  svgAssets[i],
                  colorFilter: ColorFilter.mode(
                    teal900.withValues(alpha: opacity),
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return widgets;
  }
}