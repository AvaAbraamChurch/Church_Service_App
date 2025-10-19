import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool _isConnected = true;
  bool get isConnected => _isConnected;

  // Stream controller to broadcast connectivity changes
  final _connectivityController = StreamController<bool>.broadcast();
  Stream<bool> get connectivityStream => _connectivityController.stream;

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    // Check initial connectivity
    await _checkConnectivity();

    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        _updateConnectionStatus(results);
      },
    );
  }

  /// Check current connectivity status
  Future<void> _checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      _isConnected = false;
      _connectivityController.add(false);
    }
  }

  /// Update connection status based on connectivity results
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    // Check if any result indicates connectivity
    final hasConnection = results.any((result) =>
      result == ConnectivityResult.mobile ||
      result == ConnectivityResult.wifi ||
      result == ConnectivityResult.ethernet
    );

    if (_isConnected != hasConnection) {
      _isConnected = hasConnection;
      _connectivityController.add(hasConnection);
      debugPrint('Connectivity changed: ${hasConnection ? "Connected" : "Disconnected"}');
    }
  }

  /// Manually check connectivity
  Future<bool> checkConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.any((result) =>
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet
      );
    } catch (e) {
      debugPrint('Error checking connection: $e');
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityController.close();
  }
}

