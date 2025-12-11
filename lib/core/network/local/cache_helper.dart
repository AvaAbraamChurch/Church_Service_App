import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CacheHelper {
  static SharedPreferences? sharedPreferences;

  static Future<void> init() async {
    sharedPreferences = await SharedPreferences.getInstance();
  }

  static Future<bool> saveData({
    required String key,
    required dynamic value,
  }) async {
    if (value is String) {
      return await sharedPreferences!.setString(key, value);
    } else if (value is int) {
      return await sharedPreferences!.setInt(key, value);
    } else if (value is bool) {
      return await sharedPreferences!.setBool(key, value);
    } else if (value is double) {
      return await sharedPreferences!.setDouble(key, value);
    } else if (value is List || value is Map) {
      // Convert List or Map to JSON string
      return await sharedPreferences!.setString(key, jsonEncode(value));
    } else {
      return false;
    }
  }

  static dynamic getData({required String key}) {
    final value = sharedPreferences!.get(key);

    // Try to decode JSON if it's a string that looks like JSON
    if (value is String && (value.startsWith('[') || value.startsWith('{'))) {
      try {
        return jsonDecode(value);
      } catch (e) {
        // If decode fails, just return the string
        return value;
      }
    }

    return value;
  }

  static Future<bool> removeData({required String key}) async {
    return await sharedPreferences!.remove(key);
  }

  static Future<bool> clearAllData() async {
    return await sharedPreferences!.clear();
  }
}
