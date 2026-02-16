import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/hymn_model.dart';

/// Service for managing hymns data from Firestore
class HymnsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference get _hymnsCollection => _firestore.collection('hymns');

  /// Get all hymns as a stream, ordered by order field
  Stream<List<HymnModel>> getAllHymns() {
    return _hymnsCollection.orderBy('order').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => HymnModel.fromFirestore(doc)).toList();
    });
  }

  /// Get hymns by occasion
  Stream<List<HymnModel>> getHymnsByOccasion(String occasion) {
    return _hymnsCollection
        .where('occasion', isEqualTo: occasion)
        .orderBy('order')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => HymnModel.fromFirestore(doc))
              .toList();
        });
  }

  /// Get hymns filtered by user class
  Stream<List<HymnModel>> getHymnsByUserClass(String userClass) {
    return _hymnsCollection
        .where('userClasses', arrayContains: userClass)
        .orderBy('order')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => HymnModel.fromFirestore(doc))
              .toList();
        });
  }

  /// Get hymns filtered by user class and occasion
  Stream<List<HymnModel>> getHymnsByUserClassAndOccasion(
    String userClass,
    String occasion,
  ) {
    return _hymnsCollection
        .where('userClasses', arrayContains: userClass)
        .where('occasion', isEqualTo: occasion)
        .orderBy('order')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => HymnModel.fromFirestore(doc))
              .toList();
        });
  }

  /// Get a specific hymn by ID
  Future<HymnModel?> getHymnById(String hymnId) async {
    try {
      final doc = await _hymnsCollection.doc(hymnId).get();
      if (doc.exists) {
        return HymnModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting hymn: $e');
      return null;
    }
  }

  /// Add a new hymn (admin function)
  Future<String?> addHymn(HymnModel hymn) async {
    try {
      final docRef = await _hymnsCollection.add(hymn.toMap());
      return docRef.id;
    } catch (e) {
      print('Error adding hymn: $e');
      return null;
    }
  }

  /// Update an existing hymn (admin function)
  Future<bool> updateHymn(String hymnId, HymnModel hymn) async {
    try {
      await _hymnsCollection.doc(hymnId).update(hymn.toMap());
      return true;
    } catch (e) {
      print('Error updating hymn: $e');
      return false;
    }
  }

  /// Delete a hymn (admin function)
  Future<bool> deleteHymn(String hymnId) async {
    try {
      await _hymnsCollection.doc(hymnId).delete();
      return true;
    } catch (e) {
      print('Error deleting hymn: $e');
      return false;
    }
  }

  /// Search hymns by title (Arabic or English)
  Stream<List<HymnModel>> searchHymns(String query) {
    return _hymnsCollection.orderBy('arabicTitle').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => HymnModel.fromFirestore(doc))
          .where(
            (hymn) =>
                hymn.arabicTitle.toLowerCase().contains(query.toLowerCase()) ||
                hymn.title.toLowerCase().contains(query.toLowerCase()) ||
                hymn.copticTitle.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    });
  }
}
