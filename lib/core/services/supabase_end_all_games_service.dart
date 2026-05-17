import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;

class SupabaseEndAllGamesService {
  final String functionUrl;
  final String adminApiKey;
  final Duration timeout;

  SupabaseEndAllGamesService({
    String? functionUrl,
    String? adminApiKey,
    this.timeout = const Duration(seconds: 30),
  })  : functionUrl = functionUrl ?? _resolveFunctionUrl(),
        adminApiKey = adminApiKey ?? _resolveAdminApiKey();

  static String _resolveFunctionUrl() {
    const fromDefine = String.fromEnvironment(
      'SUPABASE_END_ALL_GAMES_URL',
      defaultValue: '',
    );
    if (fromDefine.isNotEmpty) return fromDefine;

    final fromProcess = Platform.environment['SUPABASE_END_ALL_GAMES_URL'];
    if (fromProcess != null && fromProcess.isNotEmpty) return fromProcess;

    return 'https://pfytemzrsgcptoxqywjs.supabase.co/functions/v1/end-all-games';
  }

  static String _resolveAdminApiKey() {
    const fromDefine = String.fromEnvironment('ADMIN_API_KEY', defaultValue: '');
    if (fromDefine.isNotEmpty) return fromDefine;

    final fromProcess = Platform.environment['ADMIN_API_KEY'];
    if (fromProcess != null && fromProcess.isNotEmpty) return fromProcess;

    return '';
  }

  Future<EndAllGamesResult> endAllGames() async {
    if (adminApiKey.isEmpty) {
      throw Exception('ADMIN_API_KEY not configured. Set via --dart-define or secure storage.');
    }

    final response = await http
        .post(
          Uri.parse(functionUrl),
          headers: {
            'Content-Type': 'application/json',
            'apikey': adminApiKey,
            'User-Agent': 'ChurchApp/1.0',
          },
        )
        .timeout(timeout);

    if (response.statusCode == 401) {
      throw Exception('Unauthorized: Invalid ADMIN_API_KEY or missing authentication');
    } else if (response.statusCode >= 500) {
      throw Exception('Edge Function server error: ${response.statusCode}');
    } else if (response.statusCode != 200) {
      throw Exception('Unexpected response: ${response.statusCode} - ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid response format');
    }

    if (decoded['success'] != true) {
      final errorMsg = decoded['error']?.toString() ?? 'End-all-games failed';
      throw Exception(errorMsg);
    }

    return EndAllGamesResult.fromJson(decoded);
  }
}

class EndAllGamesResult {
  final int gamesUpdated;
  final int playingChildrenDeleted;

  EndAllGamesResult({
    required this.gamesUpdated,
    required this.playingChildrenDeleted,
  });

  factory EndAllGamesResult.fromJson(Map<String, dynamic> json) {
    return EndAllGamesResult(
      gamesUpdated: (json['gamesUpdated'] as num?)?.toInt() ?? 0,
      playingChildrenDeleted: (json['playingChildrenDeleted'] as num?)?.toInt() ?? 0,
    );
  }
}

