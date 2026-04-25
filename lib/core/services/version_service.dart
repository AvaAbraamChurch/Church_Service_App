import 'dart:io';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class VersionService {
  static final VersionService _instance = VersionService._internal();

  factory VersionService() {
    return _instance;
  }

  VersionService._internal();

  // Update this to your Android application id (from android/app/build.gradle)
  // Example for this project: com.avaabraamchurch.nenshiri_emporo.app
  final String _googlePlayUrl =
      'https://play.google.com/store/apps/details?id=com.avaabraamchurch.nenshiri_emporo.app';
  final String _minVersionKey = 'min_required_version';

  /// Compare two version strings
  /// Returns: positive if version1 > version2, negative if version1 < version2, 0 if equal
  int _compareVersions(String version1, String version2) {
    final parts1 = version1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final parts2 = version2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    // Pad with zeros to make equal length
    while (parts1.length < parts2.length) {
      parts1.add(0);
    }
    while (parts2.length < parts1.length) {
      parts2.add(0);
    }

    for (int i = 0; i < parts1.length; i++) {
      if (parts1[i] > parts2[i]) return 1;
      if (parts1[i] < parts2[i]) return -1;
    }
    return 0;
  }

  /// Check if app needs update and show alert if needed
  /// Returns true if update alert was shown, false otherwise
  Future<bool> checkAndPromptUpdate(BuildContext context) async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;

      // Get minimum required version from Remote Config
      final minVersion = remoteConfig.getString(_minVersionKey);

      if (minVersion.isEmpty) {
        // No version requirement set in Remote Config
        return false;
      }

      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version; // e.g., "0.0.2"

      // Compare versions
      if (_compareVersions(currentVersion, minVersion) < 0) {
        // Current version is less than minimum required version
        if (context.mounted) {
          await _showUpdateDialog(context);
        }
        return true;
      }

      return false;
    } catch (e) {
      // Silently fail if version check has issues
      // ignore: avoid_print
      print('Version check error: $e');
      return false;
    }
  }

  /// Show update required dialog
  Future<void> _showUpdateDialog(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false, // User must tap a button
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.system_update,
                  color: Color(0xFFE53935),
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'تحديث مهم',
                  style: TextStyle(
                    fontFamily: 'Alexandria',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFE53935).withValues(alpha: 0.1),
                      const Color(0xFFE53935).withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFFE53935),
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'هناك نسخة جديدة من التطبيق متاحة',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Alexandria',
                        color: Color(0xFF333333),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'يجب تحديث التطبيق للحصول على أفضل أداء والميزات الجديدة',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontFamily: 'Alexandria',
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => _exitApp(),
              child: const Text(
                'إغلاق التطبيق',
                style: TextStyle(
                  fontFamily: 'Alexandria',
                  fontSize: 14,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _openGooglePlay();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'تحديث الآن',
                style: TextStyle(
                  fontFamily: 'Alexandria',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Open Google Play Store for the app
  Future<void> _openGooglePlay() async {
    try {
      if (await canLaunchUrl(Uri.parse(_googlePlayUrl))) {
        await launchUrl(
          Uri.parse(_googlePlayUrl),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error opening Google Play: $e');
    }
  }

  /// Exit the app
  void _exitApp() {
    exit(0);
  }
}




