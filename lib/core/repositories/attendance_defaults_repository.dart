import 'package:cloud_firestore/cloud_firestore.dart';

/// Repository for managing default attendance points values
class AttendanceDefaultsRepository {
  final DocumentReference _doc = FirebaseFirestore.instance
      .collection('settings')
      .doc('attendance_defaults');

  // Default fallback values
  static const Map<String, int> _fallback = {
    'holy_mass': 1,
    'sunday_school': 1,
    'hymns': 1,
    'bible': 1,
  };

  /// Get the current default attendance points
  Future<Map<String, int>> getDefaults() async {
    try {
      final snapshot = await _doc.get();
      final data = snapshot.data() as Map<String, dynamic>?;

      if (data == null) {
        // If document doesn't exist, return fallback values
        return Map<String, int>.from(_fallback);
      }

      // Parse each field safely
      return {
        'holy_mass': _parseIntField(data, 'holy_mass'),
        'sunday_school': _parseIntField(data, 'sunday_school'),
        'hymns': _parseIntField(data, 'hymns'),
        'bible': _parseIntField(data, 'bible'),
      };
    } catch (e) {
      print('Error getting attendance defaults: $e');
      return Map<String, int>.from(_fallback);
    }
  }

  /// Helper to safely parse int fields
  int _parseIntField(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? _fallback[key]!;
    return _fallback[key]!;
  }

  /// Set the default attendance points
  Future<void> setDefaults({
    required int holyMass,
    required int sundaySchool,
    required int hymns,
    required int bible,
  }) async {
    try {
      await _doc.set({
        'holy_mass': holyMass,
        'sunday_school': sundaySchool,
        'hymns': hymns,
        'bible': bible,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error setting attendance defaults: $e');
      rethrow;
    }
  }

  /// Stream to listen for changes to attendance defaults
  Stream<Map<String, int>> defaultsStream() {
    return _doc.snapshots().map((snapshot) {
      final data = snapshot.data() as Map<String, dynamic>?;

      if (data == null) {
        return Map<String, int>.from(_fallback);
      }

      return {
        'holy_mass': _parseIntField(data, 'holy_mass'),
        'sunday_school': _parseIntField(data, 'sunday_school'),
        'hymns': _parseIntField(data, 'hymns'),
        'bible': _parseIntField(data, 'bible'),
      };
    });
  }
}

