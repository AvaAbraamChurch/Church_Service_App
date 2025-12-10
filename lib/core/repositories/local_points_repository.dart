import 'package:hive_flutter/hive_flutter.dart';

/// Local repository for managing pending points transactions when offline
class LocalPointsRepository {
  static const String _boxName = 'pending_points';
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
      throw Exception('Hive box not opened. Call LocalPointsRepository.init() first.');
    }
    return Hive.box(_boxName);
  }

  /// Save pending points transaction to local storage
  /// Returns the generated key
  Future<String> savePendingTransaction({
    required String userId,
    required int points,
    required String type, // 'ADDITION', 'DEDUCTION', 'MANUAL_ADDITION', 'MANUAL_DEDUCTION'
    required String reason,
    String? orderId,
    String? adjustedBy,
  }) async {
    try {
      final box = _getBox();
      final key = 'points_${DateTime.now().millisecondsSinceEpoch}';

      final data = {
        'key': key,
        'userId': userId,
        'points': points,
        'type': type,
        'reason': reason,
        'orderId': orderId,
        'adjustedBy': adjustedBy,
        'createdAt': DateTime.now().toIso8601String(),
        'retryCount': 0,
      };

      await box.put(key, data);
      return key;
    } catch (e) {
      throw Exception('Failed to save pending points transaction: $e');
    }
  }

  /// Get all pending transactions
  List<Map<String, dynamic>> getPendingTransactions() {
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
      print('Error getting pending points transactions: $e');
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

  /// Delete a specific pending transaction
  Future<void> deletePending(String key) async {
    try {
      final box = _getBox();
      await box.delete(key);
    } catch (e) {
      throw Exception('Failed to delete pending points transaction: $e');
    }
  }

  /// Get pending transaction by key
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
      throw Exception('Failed to clear pending points data: $e');
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
          'totalPoints': 0,
          'additionCount': 0,
          'deductionCount': 0,
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
      final totalPoints = items.fold<int>(0, (sum, item) => sum + (item['points'] as int));
      final additionCount = items.where((e) => (e['points'] as int) > 0).length;
      final deductionCount = items.where((e) => (e['points'] as int) < 0).length;

      return {
        'totalCount': items.length,
        'totalPoints': totalPoints,
        'additionCount': additionCount,
        'deductionCount': deductionCount,
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

  /// Get pending transactions for a specific user
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

  /// Calculate local balance adjustment for a user
  /// (sum of all pending transactions for that user)
  int getLocalBalanceAdjustment(String userId) {
    try {
      final pending = getPendingForUser(userId);
      return pending.fold<int>(0, (sum, item) => sum + (item['points'] as int));
    } catch (e) {
      return 0;
    }
  }

  /// Check if a specific transaction is already pending
  bool isTransactionPending(String userId, String type, String reason) {
    try {
      final box = _getBox();
      return box.values
          .map((e) => Map<String, dynamic>.from(e as Map))
          .any((item) =>
              item['userId'] == userId &&
              item['type'] == type &&
              item['reason'] == reason);
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
      print('Error deleting old pending points items: $e');
      return 0;
    }
  }
}

