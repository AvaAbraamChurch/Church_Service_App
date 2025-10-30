import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

class RemoteConfigUpdateService {
  static final RemoteConfigUpdateService _instance = RemoteConfigUpdateService._internal();
  factory RemoteConfigUpdateService() => _instance;
  RemoteConfigUpdateService._internal();

  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Update Remote Config values via Cloud Function
  /// Returns a map with success status and message
  Future<Map<String, dynamic>> updateRemoteConfig(Map<String, dynamic> updates) async {
    try {
      debugPrint('Calling updateRemoteConfig Cloud Function with updates: $updates');

      final HttpsCallable callable = _functions.httpsCallable('updateRemoteConfig');
      final HttpsCallableResult result = await callable.call({
        'updates': updates,
      });

      debugPrint('Cloud Function response: ${result.data}');

      return {
        'success': result.data['success'] ?? false,
        'message': result.data['message'] ?? 'Unknown response',
        'version': result.data['version'],
      };
    } catch (e) {
      debugPrint('Error calling updateRemoteConfig: $e');

      String errorMessage = 'فشل تحديث الإعدادات';

      if (e is FirebaseFunctionsException) {
        switch (e.code) {
          case 'unauthenticated':
            errorMessage = 'يجب تسجيل الدخول أولاً';
            break;
          case 'permission-denied':
            errorMessage = 'ليس لديك صلاحية لتحديث الإعدادات';
            break;
          case 'invalid-argument':
            errorMessage = 'بيانات غير صالحة: ${e.message}';
            break;
          default:
            errorMessage = 'خطأ: ${e.message ?? e.code}';
        }
      } else {
        errorMessage = 'خطأ في الاتصال: $e';
      }

      return {
        'success': false,
        'message': errorMessage,
      };
    }
  }

  /// Get current Remote Config values via Cloud Function
  Future<Map<String, dynamic>> getRemoteConfig() async {
    try {
      debugPrint('Calling getRemoteConfig Cloud Function');

      final HttpsCallable callable = _functions.httpsCallable('getRemoteConfig');
      final HttpsCallableResult result = await callable.call();

      debugPrint('Cloud Function response: ${result.data}');

      return {
        'success': result.data['success'] ?? false,
        'config': result.data['config'] ?? {},
        'version': result.data['version'],
      };
    } catch (e) {
      debugPrint('Error calling getRemoteConfig: $e');

      String errorMessage = 'فشل جلب الإعدادات';

      if (e is FirebaseFunctionsException) {
        switch (e.code) {
          case 'unauthenticated':
            errorMessage = 'يجب تسجيل الدخول أولاً';
            break;
          case 'permission-denied':
            errorMessage = 'ليس لديك صلاحية لعرض الإعدادات';
            break;
          default:
            errorMessage = 'خطأ: ${e.message ?? e.code}';
        }
      } else {
        errorMessage = 'خطأ في الاتصال: $e';
      }

      return {
        'success': false,
        'message': errorMessage,
      };
    }
  }

  /// Helper method to convert color to hex string
  String colorToHex(Color color) {
    final r = ((color.r * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0');
    final g = ((color.g * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0');
    final b = ((color.b * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0');
    return '#$r$g$b'.toUpperCase();
  }

  /// Helper method to parse hex string to color
  Color? parseColor(String colorString) {
    try {
      String hexColor = colorString.replaceAll('#', '');
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor';
      }
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      debugPrint('Failed to parse color: $colorString - $e');
      return null;
    }
  }
}

