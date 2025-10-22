import 'package:church/core/models/Classes/classes_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Repository for managing class data in Firestore
class ClassesRepository {
  final FirebaseFirestore _firestore;

  ClassesRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get all classes as a stream
  Stream<List<Model>> getAllClasses() {
    return _firestore
        .collection('classes')
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Model.fromJson({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();
    });
  }

  /// Get a single class by ID
  Future<Model?> getClassById(String id) async {
    try {
      final doc = await _firestore.collection('classes').doc(id).get();
      if (doc.exists) {
        return Model.fromJson({
          'id': doc.id,
          ...doc.data()!,
        });
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching class: $e');
    }
  }

  /// Add a new class
  Future<String> addClass(String name) async {
    try {
      final docRef = await _firestore.collection('classes').add({
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Error adding class: $e');
    }
  }

  /// Update an existing class
  Future<void> updateClass(String id, String name) async {
    try {
      await _firestore.collection('classes').doc(id).update({
        'name': name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error updating class: $e');
    }
  }

  /// Delete a class
  Future<void> deleteClass(String id) async {
    try {
      await _firestore.collection('classes').doc(id).delete();
    } catch (e) {
      throw Exception('Error deleting class: $e');
    }
  }

  /// Check if class name already exists (for validation)
  Future<bool> classNameExists(String name, {String? excludeId}) async {
    try {
      final query = await _firestore
          .collection('classes')
          .where('name', isEqualTo: name)
          .get();

      if (excludeId != null) {
        return query.docs.any((doc) => doc.id != excludeId);
      }
      return query.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Error checking class name: $e');
    }
  }
}

