import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';

class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  // Theme configuration keys
  static const String _primaryColorKey = 'theme_primary_color';
  static const String _secondaryColorKey = 'theme_secondary_color';
  static const String _scaffoldBackgroundColorKey = 'theme_scaffold_background_color';
  static const String _scaffoldBackgroundImageKey = 'theme_scaffold_background_image';
  static const String _appBarBackgroundColorKey = 'theme_appbar_background_color';
  static const String _isDarkModeKey = 'theme_is_dark_mode';
  static const String _fontFamilyKey = 'theme_font_family';
  static const String _enableCustomThemeKey = 'enable_custom_theme';

  // Default values for theme configuration
  final Map<String, dynamic> _defaults = {
    _primaryColorKey: '#D4FFEE', // teal100
    _secondaryColorKey: '#003844', // teal900
    _scaffoldBackgroundColorKey: '#003844', // teal900
    _scaffoldBackgroundImageKey: 'assets/images/bg.png', // Default local asset
    _appBarBackgroundColorKey: '#D4FFEE', // teal100
    _isDarkModeKey: false,
    _fontFamilyKey: 'Alexandria',
    _enableCustomThemeKey: false,
  };

  /// Initialize Remote Config with default values
  Future<void> initialize() async {
    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );

      await _remoteConfig.setDefaults(_defaults);
      await fetchAndActivate();
    } catch (e) {
      debugPrint('Failed to initialize Remote Config: $e');
    }
  }

  /// Fetch and activate remote config values
  Future<bool> fetchAndActivate() async {
    try {
      final bool updated = await _remoteConfig.fetchAndActivate();
      debugPrint('Remote Config updated: $updated');
      return updated;
    } catch (e) {
      debugPrint('Failed to fetch and activate Remote Config: $e');
      return false;
    }
  }

  /// Check if custom theme is enabled
  bool get isCustomThemeEnabled {
    return _remoteConfig.getBool(_enableCustomThemeKey);
  }

  /// Get primary color from Remote Config
  Color get primaryColor {
    final colorString = _remoteConfig.getString(_primaryColorKey);
    return _parseColor(colorString) ?? const Color(0xFFD4FFEE);
  }

  /// Get secondary color from Remote Config
  Color get secondaryColor {
    final colorString = _remoteConfig.getString(_secondaryColorKey);
    return _parseColor(colorString) ?? const Color(0xFF003844);
  }

  /// Get scaffold background color from Remote Config
  Color get scaffoldBackgroundColor {
    final colorString = _remoteConfig.getString(_scaffoldBackgroundColorKey);
    return _parseColor(colorString) ?? const Color(0xFF003844);
  }

  /// Get scaffold background image from Remote Config
  String get scaffoldBackgroundImage {
    final imageString = _remoteConfig.getString(_scaffoldBackgroundImageKey);
    return imageString.isNotEmpty ? imageString : 'assets/images/bg.png';
  }

  /// Get app bar background color from Remote Config
  Color get appBarBackgroundColor {
    final colorString = _remoteConfig.getString(_appBarBackgroundColorKey);
    return _parseColor(colorString) ?? const Color(0xFFD4FFEE);
  }

  /// Check if dark mode is enabled
  bool get isDarkMode {
    return _remoteConfig.getBool(_isDarkModeKey);
  }

  /// Get font family from Remote Config
  String get fontFamily {
    return _remoteConfig.getString(_fontFamilyKey);
  }

  /// Parse color string (hex format) to Color object
  Color? _parseColor(String colorString) {
    try {
      // Remove '#' if present
      String hexColor = colorString.replaceAll('#', '');

      // Add opacity if not present
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor';
      }

      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      debugPrint('Failed to parse color: $colorString - $e');
      return null;
    }
  }

  /// Get all theme configuration as a map
  Map<String, dynamic> getThemeConfig() {
    return {
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'scaffoldBackgroundColor': scaffoldBackgroundColor,
      'scaffoldBackgroundImage': scaffoldBackgroundImage,
      'appBarBackgroundColor': appBarBackgroundColor,
      'isDarkMode': isDarkMode,
      'fontFamily': fontFamily,
      'isCustomThemeEnabled': isCustomThemeEnabled,
    };
  }

  /// Listen to Remote Config changes
  Stream<RemoteConfigUpdate> get onConfigUpdated {
    return _remoteConfig.onConfigUpdated;
  }

  /// Activate fetched config
  Future<bool> activate() async {
    try {
      return await _remoteConfig.activate();
    } catch (e) {
      debugPrint('Failed to activate Remote Config: $e');
      return false;
    }
  }
}

