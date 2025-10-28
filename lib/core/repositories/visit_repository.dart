import 'package:church/core/models/attendance/visit_model.dart';
import 'package:church/core/utils/visit_enum.dart';
import 'package:church/core/utils/userType_enum.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VisitRepository {
  final FirebaseFirestore _firestore;
  static const String _collectionName = 'visits';

  VisitRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(_collectionName);

  /// Initialize the visits collection (optional)
  Future<void> initializeCollection() async {
    try {
      final snapshot = await _col.limit(1).get();
      if (snapshot.docs.isEmpty) {
        final initDoc = _col.doc('_init');
        await initDoc.set({
          'initialized': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
        await initDoc.delete();
      }
    } catch (e) {
      throw Exception('Error initializing visits collection: $e');
    }
  }

  /// Add a new visit document
  Future<String> addVisit(VisitModel visit) async {
    try {
      final docRef = await _col.add(visit.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Error adding visit: $e');
    }
  }

  /// Set a visit with a specific ID
  Future<void> setVisit(String id, VisitModel visit) async {
    try {
      await _col.doc(id).set(visit.toMap());
    } catch (e) {
      throw Exception('Error setting visit: $e');
    }
  }

  /// Update a visit document
  Future<void> updateVisit(String id, Map<String, dynamic> data) async {
    try {
      await _col.doc(id).update(data);
    } catch (e) {
      throw Exception('Error updating visit: $e');
    }
  }

  /// Delete a visit document
  Future<void> deleteVisit(String id) async {
    try {
      await _col.doc(id).delete();
    } catch (e) {
      throw Exception('Error deleting visit: $e');
    }
  }

  /// Get visits by childId (stream) ordered by date desc
  Stream<List<VisitModel>> getVisitsByChildIdStream(String childId) {
    return _col
        .where('childId', isEqualTo: childId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => VisitModel.fromMap(d.data(), id: d.id))
            .toList());
  }

  /// Get visits by childId (future)
  Future<List<VisitModel>> getVisitsByChildIdFuture(String childId) async {
    try {
      final snap = await _col
          .where('childId', isEqualTo: childId)
          .get();
      return snap.docs
          .map((d) => VisitModel.fromMap(d.data(), id: d.id))
          .toList();
    } catch (e) {
      throw Exception('Error fetching visits by childId: $e');
    }
  }

  /// Get one visit for a child on a specific day with a given type (if exists)
  Future<VisitModel?> getVisitForChildByDateAndType({
    required String childId,
    required DateTime date,
    required VisitType visitType,
  }) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

      final snap = await _col
          .where('childId', isEqualTo: childId)
          .where('visitType', isEqualTo: visitType.toJson())
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return null;
      final d = snap.docs.first;
      return VisitModel.fromMap(d.data(), id: d.id);
    } catch (e) {
      throw Exception('Error fetching visit for child/date/type: $e');
    }
  }

  /// Create or merge a visit: if a visit exists for same child/day/type,
  /// append servant(s) using arrayUnion; else create a new visit
  Future<String> addOrMergeVisit(VisitModel visit) async {
    try {
      final existing = await getVisitForChildByDateAndType(
        childId: visit.childId,
        date: visit.date,
        visitType: visit.visitType,
      );

      if (existing != null) {
        await _col.doc(existing.id).update({
          'servantsId': FieldValue.arrayUnion(visit.servantsId),
          'servantsNames': FieldValue.arrayUnion(visit.servantsNames),
          if (visit.notes != null && visit.notes!.isNotEmpty) 'notes': visit.notes,
          // Optionally update childName/userType if changed
          'childName': visit.childName,
          'userType': userTypeToJson(visit.userType),
        });
        return existing.id;
      } else {
        final id = await addVisit(visit);
        return id;
      }
    } catch (e) {
      throw Exception('Error creating or merging visit: $e');
    }
  }

  /// Add a single servant to an existing visit (by visitId)
  Future<void> addServantToVisit({
    required String visitId,
    required String servantId,
    required String servantName,
  }) async {
    try {
      await _col.doc(visitId).update({
        'servantsId': FieldValue.arrayUnion([servantId]),
        'servantsNames': FieldValue.arrayUnion([servantName]),
      });
    } catch (e) {
      throw Exception('Error adding servant to visit: $e');
    }
  }

  /// Batch add visits
  Future<void> batchAddVisits(List<VisitModel> visits) async {
    try {
      final batch = _firestore.batch();
      for (final v in visits) {
        final ref = _col.doc();
        batch.set(ref, v.toMap());
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Error batch adding visits: $e');
    }
  }
}
