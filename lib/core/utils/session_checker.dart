import 'package:church/core/constants/strings.dart';
import 'package:church/shared/widgets.dart';
import 'package:flutter/material.dart';
import '../../modules/Auth/login/login_screen.dart';
import '../repositories/auth_repository.dart';
import '../styles/colors.dart';

/// Session Checker Utility
/// Use this to check session expiration throughout your app
class SessionChecker {
  final AuthRepository _authRepository;

  SessionChecker(this._authRepository);

  /// Check if session is expired and handle accordingly
  /// Returns true if session is valid, false if expired
  Future<bool> checkAndHandleSession(BuildContext context) async {
    // Check if session has expired
    if (_authRepository.isSessionExpired()) {
      print('⏰ Session has expired');

      // Sign out user
      await _authRepository.signOut();

      // Show dialog to user
      if (context.mounted) {
        _showSessionExpiredDialog(context);
      }

      return false;
    }

    // Session is still valid
    final remainingTime = _authRepository.getRemainingSessionTime();
    if (remainingTime != null) {
      print('✅ Session valid. Remaining time: ${remainingTime.inHours}h ${remainingTime.inMinutes % 60}m');
    }

    return true;
  }

  /// Show session expired dialog
  void _showSessionExpiredDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Session Expired'),
        content: const Text(
          sessionExpiredPleaseLoginAgain,
        style: TextStyle(color: teal900),),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              navigateAndFinish(context, LoginScreen());
            },
            child: const Text(login),
          ),
        ],
      ),
    );
  }

  /// Check session and show warning if expiring soon
  void checkAndWarnIfExpiringSoon(BuildContext context, {Duration warningThreshold = const Duration(hours: 24)}) {
    if (_authRepository.isSessionExpired()) {
      return; // Already expired
    }

    final remainingTime = _authRepository.getRemainingSessionTime();
    if (remainingTime != null && remainingTime < warningThreshold) {
      _showExpiringWarningDialog(context, remainingTime);
    }
  }

  /// Show warning that session is expiring soon
  void _showExpiringWarningDialog(BuildContext context, Duration remainingTime) {
    final hours = remainingTime.inHours;
    final minutes = remainingTime.inMinutes % 60;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Session Expiring Soon'),
        content: Text(
          'Your session will expire in $hours hours and $minutes minutes. Would you like to extend it?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _authRepository.extendSession();
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Session extended successfully')),
                );
              }
            },
            child: const Text('Extend'),
          ),
        ],
      ),
    );
  }
}

