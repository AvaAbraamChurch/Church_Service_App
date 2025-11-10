/// Authentication and Token Configuration Constants
class AuthConstants {
  // Custom session duration (how long user stays logged in your app)
  // Firebase tokens expire after 1 hour, but we can set custom session timeouts

  /// Session timeout duration - Change this value to your desired session length
  /// Default: 7 days
  static const Duration sessionTimeout = Duration(days: 30);

  /// Alternative session timeout options (uncomment the one you want):
  // static const Duration sessionTimeout = Duration(hours: 1);  // 1 hour
  // static const Duration sessionTimeout = Duration(hours: 12); // 12 hours
  // static const Duration sessionTimeout = Duration(days: 1);   // 1 day
  // static const Duration sessionTimeout = Duration(days: 30);  // 30 days

  /// Token refresh threshold - Refresh token when it's about to expire
  /// Recommended: 5 minutes before expiration
  static const Duration tokenRefreshThreshold = Duration(minutes: 5);

  /// Auto-refresh tokens when they're close to expiring
  static const bool autoRefreshTokens = true;

  /// Force re-authentication after session timeout
  static const bool forceReauthAfterTimeout = true;

  // Cache keys
  static const String cacheKeyUserId = 'uId';
  static const String cacheKeyIsLoggedIn = 'isLoggedIn';
  static const String cacheKeyEmail = 'email';
  static const String cacheKeyLastLoginTime = 'lastLoginTime';
  static const String cacheKeySessionExpiry = 'sessionExpiry';
  static const String cacheKeyUserType = 'userType';
  static const String cacheKeyUserClass = 'userClass';
  static const String cacheKeyGender = 'gender';
}

