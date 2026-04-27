// lib/core/services/supabase_password_reset_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kDebugMode, kReleaseMode;

/// Service for calling Supabase Edge Function to reset Firebase passwords
/// 
/// This service calls a Supabase Edge Function that:
/// 1. Validates admin authentication via API key header
/// 2. Resets password in Firebase Authentication via REST API
/// 3. Optionally updates Firestore with reset flags
/// 4. Returns the temporary password (only in development mode)
/// 
/// ⚠️ Security: Never expose ADMIN_API_KEY in client code in production.
/// Use a backend proxy or secure storage for production apps.
class SupabasePasswordResetService {
  // 👇 Load from environment/secure storage - NEVER hardcode in production
  final String functionUrl;
  final String adminApiKey;
  final Duration timeout;

  SupabasePasswordResetService({
    String? functionUrl,
    String? adminApiKey,
    this.timeout = const Duration(seconds: 30),
  })  : functionUrl = functionUrl ?? _resolveFunctionUrl(),
        adminApiKey = adminApiKey ?? _resolveAdminApiKey();

  // String.fromEnvironment must be used with compile-time constant keys.
  static String _resolveFunctionUrl() {
    const fromDefine = String.fromEnvironment(
      'SUPABASE_FUNCTION_URL',
      defaultValue: '',
    );
    if (fromDefine.isNotEmpty) return fromDefine;

    final fromProcess = Platform.environment['SUPABASE_FUNCTION_URL'];
    if (fromProcess != null && fromProcess.isNotEmpty) return fromProcess;

    return 'https://pfytemzrsgcptoxqywjs.supabase.co/functions/v1/reset-password';
  }

  // String.fromEnvironment must be used with compile-time constant keys.
  static String _resolveAdminApiKey() {
    const fromDefine = String.fromEnvironment('ADMIN_API_KEY', defaultValue: 'd466a9813c9038a9b1ebf32a5af5d65994ebcb4176bbbdf506907816bf17476d');
    if (fromDefine.isNotEmpty) return fromDefine;

    final fromProcess = Platform.environment['ADMIN_API_KEY'];
    if (fromProcess != null && fromProcess.isNotEmpty) return fromProcess;

    return '';
  }

  /// Reset Firebase password via Supabase Edge Function
  /// 
  /// Edge Function expects:
  /// - email OR uid (at least one required)
  /// - autoGenerate: true/false (default: true)
  /// - newPassword: optional custom password
  /// - fullName: optional (for logging)
  /// 
  /// Returns: temporary password (generated or custom)
  /// 
  /// The edge function must return the generated password to show it to admin.
  Future<String> resetUserPassword({
    String? email,
    String? uid,
    String? fullName,
    bool autoGenerate = true,
    String? newPassword,
  }) async {
    // Validate: require at least email OR uid
    if (email == null && uid == null) {
      throw ArgumentError('Either email or uid must be provided');
    }

    // Validate admin API key is set
    if (adminApiKey.isEmpty) {
      throw Exception('ADMIN_API_KEY not configured. Set via --dart-define or secure storage.');
    }

    try {
      print('🔄 Calling Edge Function: $functionUrl');

      final response = await http.post(
        Uri.parse(functionUrl),
        headers: {
          'Content-Type': 'application/json',
          'apikey': adminApiKey,  // 🔐 Admin authentication header
          'User-Agent': 'ChurchApp/1.0', // Optional: for logging
        },
        body: jsonEncode({
          if (email != null) 'email': email,
          if (uid != null) 'uid': uid,
          if (fullName != null) 'fullName': fullName,
          'autoGenerate': autoGenerate,
          if (newPassword != null) 'newPassword': newPassword,
        }),
      ).timeout(timeout);

      print('📡 Edge Function response: ${response.statusCode}');

      // Handle HTTP status codes
      if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid ADMIN_API_KEY or missing authentication');
      } else if (response.statusCode == 404) {
        throw Exception('User not found in Firebase Authentication');
      } else if (response.statusCode >= 500) {
        throw Exception('Edge Function server error: ${response.statusCode}');
      } else if (response.statusCode != 200) {
        throw Exception('Unexpected response: ${response.statusCode} - ${response.body}');
      }

      // Parse JSON response
      final Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body) as Map<String, dynamic>;
        print('✅ Edge Function response data: $responseData');
      } catch (e) {
        throw Exception('Failed to parse response JSON: ${response.body}');
      }

      // Check for success flag
      if (responseData['success'] != true) {
        final errorMsg = responseData['error'] ?? 'Password reset failed';
        throw Exception('Edge Function error: $errorMsg');
      }

      final temporaryPassword = _extractReturnedPassword(responseData);
      if (temporaryPassword == null || temporaryPassword.isEmpty) {
        throw Exception(
          'Edge Function succeeded but did not return the generated password. '
          'Return `newPassword` (or `temporaryPassword`) in the response.',
        );
      }

      print('✅ Password reset successful (password returned)');
      return temporaryPassword;

    } on http.ClientException catch (e) {
      print('❌ Network error: $e');
      throw Exception('Network error: Check connection and function URL');
    } on TimeoutException catch (e) {
      print('❌ Timeout: $e');
      throw Exception('Request timed out after ${timeout.inSeconds} seconds');
    } catch (e) {
      print('❌ Unexpected error: $e');
      rethrow;
    }
  }

  String? _extractReturnedPassword(Map<String, dynamic> responseData) {
    final directValues = [
      responseData['newPassword'],
      responseData['temporaryPassword'],
      responseData['password'],
    ];

    for (final value in directValues) {
      if (value is String && value.isNotEmpty) return value;
    }

    final nested = responseData['data'];
    if (nested is Map) {
      final nestedValues = [
        nested['newPassword'],
        nested['temporaryPassword'],
        nested['password'],
      ];
      for (final value in nestedValues) {
        if (value is String && value.isNotEmpty) return value;
      }
    }

    return null;
  }

  /// Utility: Check if running in production mode
  bool get isProduction => kReleaseMode;

  /// Utility: Check if running in development mode
  bool get isDevelopment => kDebugMode;
}