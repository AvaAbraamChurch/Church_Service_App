import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for managing and fetching available userClasses
class UserClassesService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final String _collectionPath = 'users';

  /// Get a stream of all unique userClass values from the users collection
  /// Returns userClass names sorted alphabetically
  static Stream<List<String>> getAvailableUserClasses() {
    return _firestore
        .collection(_collectionPath)
        .snapshots()
        .map((snapshot) {
      final userClasses = <String>{};
      for (var doc in snapshot.docs) {
        final userClass = doc['userClass'] as String?;
        if (userClass != null && userClass.isNotEmpty) {
          userClasses.add(userClass);
        }
      }

      // Return sorted list
      final result = userClasses.toList();
      result.sort();
      return result;
    });
  }

  /// Get a future of all unique userClass values from the users collection
  /// Returns userClass names sorted alphabetically
  static Future<List<String>> getAvailableUserClassesFuture() {
    return _firestore.collection(_collectionPath).get().then((snapshot) {
      final userClasses = <String>{};
      for (var doc in snapshot.docs) {
        final userClass = doc['userClass'] as String?;
        if (userClass != null && userClass.isNotEmpty) {
          userClasses.add(userClass);
        }
      }

      // Return sorted list
      final result = userClasses.toList();
      result.sort();
      return result;
    });
  }

  /// Check if a userClass exists in the system
  static Future<bool> userClassExists(String userClass) async {
    final classes = await getAvailableUserClassesFuture();
    return classes.contains(userClass);
  }

  /// Get count of users in a specific userClass
  static Future<int> getUserCountByClass(String userClass) {
    return _firestore
        .collection(_collectionPath)
        .where('userClass', isEqualTo: userClass)
        .count()
        .get()
        .then((count) => count.count ?? 0);
  }

  /// Get all userClasses with their user counts
  static Future<Map<String, int>> getAllUserClassesWithCounts() async {
    final snapshot = await _firestore.collection(_collectionPath).get();
    final classCounts = <String, int>{};

    for (var doc in snapshot.docs) {
      final userClass = doc['userClass'] as String?;
      if (userClass != null && userClass.isNotEmpty) {
        classCounts[userClass] = (classCounts[userClass] ?? 0) + 1;
      }
    }

    return classCounts;
  }
}

