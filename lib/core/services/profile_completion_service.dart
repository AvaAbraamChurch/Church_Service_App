import 'package:shared_preferences/shared_preferences.dart';
import '../models/user/user_model.dart';

class ProfileCompletionService {
  static const String _hasCompletedProfileKey = 'has_completed_profile';
  static const String _hasChangedPasswordKey = 'has_changed_initial_password';

  /// Check if the user has completed their profile before
  static Future<bool> hasCompletedProfileBefore(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('${_hasCompletedProfileKey}_$userId') ?? false;
  }

  /// Mark that the user has completed their profile
  static Future<void> markProfileAsCompleted(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${_hasCompletedProfileKey}_$userId', true);
  }

  /// Check if the user has changed their initial password
  static Future<bool> hasChangedInitialPassword(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('${_hasChangedPasswordKey}_$userId') ?? false;
  }

  /// Mark that the user has changed their initial password
  static Future<void> markPasswordAsChanged(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${_hasChangedPasswordKey}_$userId', true);
  }

  /// Check if user profile data is incomplete
  static bool isProfileIncomplete(UserModel user) {
    // Check if any required field is empty or null
    if (user.fullName.trim().isEmpty) return true;
    if (user.username.trim().isEmpty) return true;
    if (user.address == null || user.address!.trim().isEmpty) return true;
    if (user.phoneNumber == null || user.phoneNumber!.trim().isEmpty) return true;
    if (user.userClass.trim().isEmpty) return true;

    return false;
  }

  /// Determine if user should be shown profile completion screen
  static Future<bool> shouldShowProfileCompletion(UserModel user) async {
    // Check if they've completed profile before
    final hasCompletedBefore = await hasCompletedProfileBefore(user.id);

    // Check if they've changed their initial password
    final hasChangedPassword = await hasChangedInitialPassword(user.id);

    // If they haven't completed before AND (profile is incomplete OR password not changed), show completion screen
    if (!hasCompletedBefore && (isProfileIncomplete(user) || !hasChangedPassword)) {
      return true;
    }

    return false;
  }

  /// Clear the completion status (for testing/debugging)
  static Future<void> clearCompletionStatus(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_hasCompletedProfileKey}_$userId');
    await prefs.remove('${_hasChangedPasswordKey}_$userId');
  }
}
