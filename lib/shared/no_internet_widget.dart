import 'package:flutter/material.dart';
import '../core/styles/colors.dart';

class NoInternetWidget extends StatefulWidget {
  final VoidCallback? onRetry;

  const NoInternetWidget({
    super.key,
    this.onRetry,
  });

  @override
  State<NoInternetWidget> createState() => _NoInternetWidgetState();
}

class _NoInternetWidgetState extends State<NoInternetWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            teal900.withValues(alpha: 0.95),
            teal700.withValues(alpha: 0.95),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated Icon Container
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
                        boxShadow: [
                          BoxShadow(
                            color: teal300.withValues(alpha: 0.3),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Pulsing background circles
                          _buildPulsingCircle(delay: 0, size: 180),
                          _buildPulsingCircle(delay: 500, size: 160),
                          _buildPulsingCircle(delay: 1000, size: 140),

                          // WiFi off icon
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.wifi_off_rounded,
                              size: 60,
                              color: red500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Title
                    Text(
                      'لا يوجد اتصال بالإنترنت',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Alexandria',
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Description
                    Text(
                      'يرجى التحقق من اتصالك بالإنترنت\nوالمحاولة مرة أخرى',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontFamily: 'Alexandria',
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Retry Button
                    if (widget.onRetry != null)
                      ElevatedButton.icon(
                        onPressed: widget.onRetry,
                        icon: const Icon(
                          Icons.refresh_rounded,
                          size: 24,
                        ),
                        label: const Text(
                          'إعادة المحاولة',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Alexandria',
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: teal300,
                          foregroundColor: teal900,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 48,
                            vertical: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 8,
                          shadowColor: teal300.withValues(alpha: 0.5),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Tips Container
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'نصائح للاتصال:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: teal100,
                              fontFamily: 'Alexandria',
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildTipItem(
                            icon: Icons.wifi_rounded,
                            text: 'تحقق من اتصال WiFi',
                          ),
                          const SizedBox(height: 12),
                          _buildTipItem(
                            icon: Icons.signal_cellular_alt_rounded,
                            text: 'تحقق من بيانات الجوال',
                          ),
                          const SizedBox(height: 12),
                          _buildTipItem(
                            icon: Icons.flight_takeoff_rounded,
                            text: 'تأكد من إيقاف وضع الطيران',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPulsingCircle({required int delay, required double size}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 2000),
      builder: (context, value, child) {
        return Container(
          width: size * value,
          height: size * value,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: teal300.withValues(alpha: (1 - value) * 0.5),
              width: 2,
            ),
          ),
        );
      },
      onEnd: () {
        // Restart animation
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  Widget _buildTipItem({required IconData icon, required String text}) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: teal300.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: teal100,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.9),
              fontFamily: 'Alexandria',
            ),
          ),
        ),
      ],
    );
  }
}
