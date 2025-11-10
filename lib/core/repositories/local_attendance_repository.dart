import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:church/core/models/attendance/attendance_model.dart';

class LocalAttendanceRepository {
  static const String _boxName = 'pending_attendance';
  static bool _initialized = false;

  /// Initialize Hive (call once in main.dart)
  static Future<void> init() async {
    if (!_initialized) {
      await Hive.initFlutter();
      await Hive.openBox(_boxName);
      _initialized = true;
    }
  }

  /// Get the Hive box
  Box _getBox() {
    if (!Hive.isBoxOpen(_boxName)) {
      throw Exception('Hive box not opened. Call LocalAttendanceRepository.init() first.');
    }
    return Hive.box(_boxName);
  }

  /// Save pending attendance to local storage
  /// Returns the generated key
  Future<String> savePendingAttendance(AttendanceModel attendance) async {
    try {
      final box = _getBox();
      final key = 'attendance_${DateTime.now().millisecondsSinceEpoch}';

      final data = {
        'key': key,
        'payload': jsonEncode(attendance.toJson()),
        'createdAt': DateTime.now().toIso8601String(),
        'userId': attendance.userId,
        'date': attendance.date,
        'retryCount': 0,
      };

      await box.put(key, data);
      return key;
    } catch (e) {
      throw Exception('Failed to save pending attendance: $e');
    }
  }

  /// Get all pending attendances
  List<Map<String, dynamic>> getPendingAttendances() {
    try {
      final box = _getBox();
      return box.values
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList()
        ..sort((a, b) {
          final dateA = DateTime.parse(a['createdAt'] as String);
          final dateB = DateTime.parse(b['createdAt'] as String);
          return dateA.compareTo(dateB); // Oldest first
        });
    } catch (e) {
      print('Error getting pending attendances: $e');
      return [];
    }
  }

  /// Get count of pending items
  int getPendingCount() {
    try {
      final box = _getBox();
      return box.length;
    } catch (e) {
      return 0;
    }
  }

  /// Delete a specific pending attendance
  Future<void> deletePending(String key) async {
    try {
      final box = _getBox();
      await box.delete(key);
    } catch (e) {
      throw Exception('Failed to delete pending attendance: $e');
    }
  }

  /// Get pending attendance by key
  Map<String, dynamic>? getPendingByKey(String key) {
    try {
      final box = _getBox();
      final data = box.get(key);
      if (data != null) {
        return Map<String, dynamic>.from(data as Map);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Increment retry count for a pending item
  Future<void> incrementRetryCount(String key) async {
    try {
      final box = _getBox();
      final data = box.get(key);
      if (data != null) {
        final map = Map<String, dynamic>.from(data as Map);
        map['retryCount'] = (map['retryCount'] as int? ?? 0) + 1;
        map['lastRetryAt'] = DateTime.now().toIso8601String();
        await box.put(key, map);
      }
    } catch (e) {
      print('Error incrementing retry count: $e');
    }
  }

  /// Get pending items that failed multiple times
  List<Map<String, dynamic>> getFailedItems({int minRetries = 3}) {
    try {
      final box = _getBox();
      return box.values
          .map((e) => Map<String, dynamic>.from(e as Map))
          .where((item) => (item['retryCount'] as int? ?? 0) >= minRetries)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Clear all pending data (dangerous operation!)
  Future<void> clearAllPending() async {
    try {
      final box = _getBox();
      await box.clear();
    } catch (e) {
      throw Exception('Failed to clear pending data: $e');
    }
  }

  /// Get statistics about pending data
  Map<String, dynamic> getStatistics() {
    try {
      final box = _getBox();
      final items = box.values.map((e) => Map<String, dynamic>.from(e as Map)).toList();

      if (items.isEmpty) {
        return {
          'totalCount': 0,
          'oldestItem': null,
          'newestItem': null,
          'failedCount': 0,
        };
      }

      final dates = items
          .map((e) => DateTime.parse(e['createdAt'] as String))
          .toList()
        ..sort();

      final failedCount = items.where((e) => (e['retryCount'] as int? ?? 0) >= 3).length;

      return {
        'totalCount': items.length,
        'oldestItem': dates.first.toIso8601String(),
        'newestItem': dates.last.toIso8601String(),
        'failedCount': failedCount,
      };
    } catch (e) {
      return {
        'totalCount': 0,
        'error': e.toString(),
      };
    }
  }

  /// Get pending items for a specific user
  List<Map<String, dynamic>> getPendingForUser(String userId) {
    try {
      final box = _getBox();
      return box.values
          .map((e) => Map<String, dynamic>.from(e as Map))
          .where((item) => item['userId'] == userId)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get pending items for a specific date
  List<Map<String, dynamic>> getPendingForDate(String date) {
    try {
      final box = _getBox();
      return box.values
          .map((e) => Map<String, dynamic>.from(e as Map))
          .where((item) => item['date'] == date)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Check if a specific attendance is already pending
  bool isPending(String userId, String date) {
    try {
      final box = _getBox();
      return box.values
          .map((e) => Map<String, dynamic>.from(e as Map))
          .any((item) => item['userId'] == userId && item['date'] == date);
    } catch (e) {
      return false;
    }
  }

  /// Delete old pending items (older than specified days)
  Future<int> deleteOldPending({int olderThanDays = 30}) async {
    try {
      final box = _getBox();
      final cutoffDate = DateTime.now().subtract(Duration(days: olderThanDays));
      int deletedCount = 0;

      final keysToDelete = <String>[];
      for (final item in box.values) {
        final map = Map<String, dynamic>.from(item as Map);
        final createdAt = DateTime.parse(map['createdAt'] as String);
        if (createdAt.isBefore(cutoffDate)) {
          keysToDelete.add(map['key'] as String);
        }
      }

      for (final key in keysToDelete) {
        await box.delete(key);
        deletedCount++;
      }

      return deletedCount;
    } catch (e) {
      print('Error deleting old pending items: $e');
      return 0;
    }
  }
}