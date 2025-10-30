import 'package:flutter/material.dart';
import 'package:church/core/utils/remote%20config/remote_config.dart';
import 'package:church/core/styles/theme.dart' as app_theme;

class ThemeProvider extends ChangeNotifier {
  final RemoteConfigService _remoteConfigService = RemoteConfigService();
  ThemeData _currentTheme = app_theme.theme;
  bool _isInitialized = false;
  bool _isCustomThemeEnabled = false;

  ThemeProvider() {
    _initializeTheme();
    _listenToRemoteConfigUpdates();
  }

  ThemeData get currentTheme => _currentTheme;
  bool get isInitialized => _isInitialized;
  bool get isCustomThemeEnabled => _isCustomThemeEnabled;

  /// Initialize theme from Remote Config
  Future<void> _initializeTheme() async {
    try {
      await _remoteConfigService.initialize();
      _isCustomThemeEnabled = _remoteConfigService.isCustomThemeEnabled;

      if (_isCustomThemeEnabled) {
        _currentTheme = _buildThemeFromRemoteConfig();
      } else {
        _currentTheme = app_theme.theme;
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to initialize theme: $e');
      _currentTheme = app_theme.theme;
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Listen to Remote Config updates and refresh theme
  void _listenToRemoteConfigUpdates() {
    _remoteConfigService.onConfigUpdated.listen((event) async {
      debugPrint('Remote Config updated, refreshing theme...');
      await _remoteConfigService.activate();
      await refreshTheme();
    });
  }

  /// Refresh theme from Remote Config
  Future<void> refreshTheme() async {
    try {
      final updated = await _remoteConfigService.fetchAndActivate();
      if (updated) {
        _isCustomThemeEnabled = _remoteConfigService.isCustomThemeEnabled;

        if (_isCustomThemeEnabled) {
          _currentTheme = _buildThemeFromRemoteConfig();
        } else {
          _currentTheme = app_theme.theme;
        }

        notifyListeners();
        debugPrint('Theme refreshed from Remote Config');
      }
    } catch (e) {
      debugPrint('Failed to refresh theme: $e');
    }
  }

  /// Build theme from Remote Config values
  ThemeData _buildThemeFromRemoteConfig() {
    final primaryColor = _remoteConfigService.primaryColor;
    final secondaryColor = _remoteConfigService.secondaryColor;
    final scaffoldBgColor = _remoteConfigService.scaffoldBackgroundColor;
    final appBarBgColor = _remoteConfigService.appBarBackgroundColor;
    final fontFamily = _remoteConfigService.fontFamily;
    final isDarkMode = _remoteConfigService.isDarkMode;

    return ThemeData(
      brightness: isDarkMode ? Brightness.dark : Brightness.light,
      drawerTheme: DrawerThemeData(
        backgroundColor: secondaryColor,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
        },
      ),
      colorSchemeSeed: primaryColor,
      scaffoldBackgroundColor: scaffoldBgColor,
      fontFamily: fontFamily,
      appBarTheme: AppBarTheme(
        titleSpacing: 20.0,
        backgroundColor: appBarBgColor,
        elevation: 0.0,
        titleTextStyle: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
          fontSize: 20.0,
          fontWeight: FontWeight.bold,
          fontFamily: fontFamily,
        ),
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        backgroundColor: secondaryColor,
        elevation: 20.0,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: secondaryColor,
        shape: const CircleBorder(),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(fontFamily: fontFamily),
        displayMedium: TextStyle(fontFamily: fontFamily),
        displaySmall: TextStyle(fontFamily: fontFamily),
        headlineLarge: TextStyle(fontFamily: fontFamily),
        headlineMedium: TextStyle(fontFamily: fontFamily),
        headlineSmall: TextStyle(fontFamily: fontFamily),
        titleLarge: TextStyle(fontFamily: fontFamily),
        titleMedium: TextStyle(fontFamily: fontFamily),
        titleSmall: TextStyle(fontFamily: fontFamily),
        bodyLarge: TextStyle(fontFamily: fontFamily),
        bodyMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 14.0,
          color: isDarkMode ? Colors.white : Colors.white,
        ),
        bodySmall: TextStyle(fontFamily: fontFamily),
        labelLarge: TextStyle(fontFamily: fontFamily),
        labelMedium: TextStyle(fontFamily: fontFamily),
        labelSmall: TextStyle(fontFamily: fontFamily),
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        textTheme: ButtonTextTheme.primary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          backgroundColor: primaryColor,
          foregroundColor: isDarkMode ? Colors.white : Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          textStyle: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            fontFamily: fontFamily,
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: isDarkMode ? Colors.white : Colors.white,
        unselectedLabelColor: isDarkMode ? Colors.white70 : Colors.white70,
        labelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          fontFamily: fontFamily,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 14,
          fontFamily: fontFamily,
        ),
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: Colors.white, width: 2.0),
          insets: EdgeInsets.symmetric(horizontal: 16.0),
        ),
      ),
    );
  }

  /// Get theme configuration as a map
  Map<String, dynamic> getThemeConfig() {
    return _remoteConfigService.getThemeConfig();
  }

  /// Toggle between custom and default theme manually
  void toggleCustomTheme(bool enabled) {
    _isCustomThemeEnabled = enabled;
    if (enabled) {
      _currentTheme = _buildThemeFromRemoteConfig();
    } else {
      _currentTheme = app_theme.theme;
    }
    notifyListeners();
  }
}

