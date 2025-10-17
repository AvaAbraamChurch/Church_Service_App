import 'package:flutter/material.dart';
import '../../core/repositories/auth_repository.dart';
import '../../core/utils/session_checker.dart';

/// Example: Home Screen with Session Check
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final AuthRepository _authRepository = AuthRepository();
  late SessionChecker _sessionChecker;

  @override
  void initState() {
    super.initState();
    _sessionChecker = SessionChecker(_authRepository);
    WidgetsBinding.instance.addObserver(this);

    // Check session on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSession();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Called when app resumes from background
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Check session when user returns to app
      _checkSession();
    }
  }

  /// Check if session is valid
  Future<void> _checkSession() async {
    final isValid = await _sessionChecker.checkAndHandleSession(context);
    if (!isValid) {
      // Session expired, user will be redirected to login
      return;
    }

    // Optional: Show warning if session expiring within 24 hours
    _sessionChecker.checkAndWarnIfExpiringSoon(
      context,
      warningThreshold: const Duration(hours: 24),
    );
  }

  /// Manually extend session
  Future<void> _extendSession() async {
    await _authRepository.extendSession();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session extended successfully!')),
      );
    }
  }

  /// Get session info
  Widget _buildSessionInfo() {
    if (_authRepository.isSessionExpired()) {
      return const Card(
        color: Colors.red,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            '⏰ Session Expired',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    final remainingTime = _authRepository.getRemainingSessionTime();
    if (remainingTime == null) {
      return const SizedBox.shrink();
    }

    final days = remainingTime.inDays;
    final hours = remainingTime.inHours % 24;
    final minutes = remainingTime.inMinutes % 60;

    return Card(
      color: remainingTime.inHours < 24 ? Colors.orange : Colors.green,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '✅ Session Active',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Expires in: $days days, $hours hours, $minutes minutes',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _extendSession,
              child: const Text('Extend Session'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Check Session',
            onPressed: _checkSession,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSessionInfo(),
            const SizedBox(height: 20),
            const Text(
              'How to use isSessionExpired():',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('1. Check on app resume'),
            const Text('2. Check before critical operations'),
            const Text('3. Periodic checks in background'),
            const Text('4. Manual checks by user'),
          ],
        ),
      ),
    );
  }
}

/// Example: Middleware for protected routes
class SessionCheckMiddleware {
  static Future<bool> checkSessionBeforeNavigation(
    BuildContext context,
    AuthRepository authRepository,
  ) async {
    // Check if session expired
    if (authRepository.isSessionExpired()) {
      // Show dialog
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Session Expired'),
          content: const Text('Please login again to continue.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                  (route) => false,
                );
              },
              child: const Text('Login'),
            ),
          ],
        ),
      );
      return false;
    }

    return true;
  }
}

/// Example: Use in API calls
class ApiService {
  final AuthRepository _authRepository = AuthRepository();

  Future<void> makeApiCall() async {
    // Check session before making API call
    if (_authRepository.isSessionExpired()) {
      throw Exception('Session expired. Please login again.');
    }

    // Proceed with API call
    print('Making API call...');
    // Your API logic here
  }
}

