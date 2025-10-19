import 'dart:async';
import 'package:flutter/material.dart';
import '../core/services/connectivity_service.dart';
import 'no_internet_widget.dart';

class ConnectivityWrapper extends StatefulWidget {
  final Widget child;
  final Duration checkDelay;

  const ConnectivityWrapper({
    super.key,
    required this.child,
    this.checkDelay = const Duration(seconds: 3),
  });

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  final ConnectivityService _connectivityService = ConnectivityService();
  bool _showNoInternet = false;
  Timer? _checkTimer;
  StreamSubscription? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _initializeConnectivity();
  }

  Future<void> _initializeConnectivity() async {
    await _connectivityService.initialize();

    // Start delayed check
    _checkTimer = Timer(widget.checkDelay, () {
      if (mounted && !_connectivityService.isConnected) {
        setState(() {
          _showNoInternet = true;
        });
      }
    });

    // Listen to connectivity changes
    _connectivitySubscription = _connectivityService.connectivityStream.listen((isConnected) {
      if (mounted) {
        setState(() {
          _showNoInternet = !isConnected;
        });

        // If reconnected, show a brief success message
        if (isConnected && _showNoInternet == false) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text(
                    'تم الاتصال بالإنترنت',
                    style: TextStyle(
                      fontFamily: 'Alexandria',
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    });
  }

  Future<void> _handleRetry() async {
    // Show loading state briefly
    setState(() {
      _showNoInternet = false;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    // Check connection
    final isConnected = await _connectivityService.checkConnection();

    if (mounted) {
      setState(() {
        _showNoInternet = !isConnected;
      });

      if (!isConnected) {
        // Show error message if still not connected
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'لا يزال الاتصال غير متاح',
                    style: TextStyle(
                      fontFamily: 'Alexandria',
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showNoInternet) {
      return NoInternetWidget(
        onRetry: _handleRetry,
      );
    }

    return widget.child;
  }
}

