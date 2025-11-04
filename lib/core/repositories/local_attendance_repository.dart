import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:church/core/models/attendance/attendance_model.dart';

/// Simple local queue using Hive to store pending attendance records.
/// Each entry stores a JSON-encoded AttendanceModel and a createdAt timestamp.
class LocalAttendanceRepository {
  static const String boxName = 'pending_attendance';

  /// Call once during app startup (main)
  static Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox(boxName);
    }
  }

  Box<dynamic> _box() => Hive.box(boxName);

  Future<int> savePendingAttendance(AttendanceModel attendance) async {
    final map = {
      'payload': jsonEncode(attendance.toJson()),
      'createdAt': DateTime.now().toIso8601String(),
    };
    final key = await _box().add(map);
    return key as int;
  }

  List<Map<String, dynamic>> getPendingAttendances() {
    final box = _box();
    final list = <Map<String, dynamic>>[];
    for (final key in box.keys) {
      final value = box.get(key);
      if (value is Map) {
        list.add({
          'key': key,
          'payload': value['payload'],
          'createdAt': value['createdAt'],
        });
      }
    }
    return list;
  }

  Future<void> deletePending(dynamic key) async {
    await _box().delete(key);
  }

  Future<void> clearAll() async {
    await _box().clear();
  }
}
