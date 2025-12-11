import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/competitions/competition_model.dart';

/// Repository for managing competitions with Firestore integration.
class CompetitionsRepository {
  final FirebaseFirestore _firestore;
  final String _collectionPath;

  CompetitionsRepository({
    FirebaseFirestore? firestore,
    String collectionPath = 'competitions',
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _collectionPath = collectionPath;

  CollectionReference get _competitionsCollection =>
      _firestore.collection(_collectionPath);

  // ==================== STREAM METHODS ====================

  /// Stream all competitions in real-time
  Stream<List<CompetitionModel>> watchAllCompetitions() {
    return _competitionsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CompetitionModel.fromJson(
                  {...doc.data() as Map<String, dynamic>, 'id': doc.id},
                ))
            .toList());
  }

  /// Stream active competitions only
  Stream<List<CompetitionModel>> watchActiveCompetitions() {
    return _competitionsCollection
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CompetitionModel.fromJson(
                  {...doc.data() as Map<String, dynamic>, 'id': doc.id},
                ))
            .toList());
  }

  /// Stream competitions by target audience
  Stream<List<CompetitionModel>> watchCompetitionsByAudience(String audience) {
    return _competitionsCollection
        .where('targetAudience', isEqualTo: audience)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CompetitionModel.fromJson(
                  {...doc.data() as Map<String, dynamic>, 'id': doc.id},
                ))
            .toList());
  }

  /// Stream competitions by creator
  Stream<List<CompetitionModel>> watchCompetitionsByCreator(String userId) {
    return _competitionsCollection
        .where('createdBy', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CompetitionModel.fromJson(
                  {...doc.data() as Map<String, dynamic>, 'id': doc.id},
                ))
            .toList());
  }

  /// Stream a single competition
  Stream<CompetitionModel?> watchCompetition(String competitionId) {
    return _competitionsCollection.doc(competitionId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return CompetitionModel.fromJson(
        {...doc.data() as Map<String, dynamic>, 'id': doc.id},
      );
    });
  }

  /// Stream competitions within date range
  Stream<List<CompetitionModel>> watchCompetitionsByDateRange({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    Query query = _competitionsCollection;

    if (startDate != null) {
      query = query.where('startDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    if (endDate != null) {
      query = query.where('endDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    return query.orderBy('createdAt', descending: true).snapshots().map((snapshot) =>
        snapshot.docs
            .map((doc) => CompetitionModel.fromJson(
                  {...doc.data() as Map<String, dynamic>, 'id': doc.id},
                ))
            .toList());
  }

  // ==================== FUTURE METHODS ====================

  /// Get all competitions
  Future<List<CompetitionModel>> getAllCompetitions() async {
    try {
      final snapshot = await _competitionsCollection
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => CompetitionModel.fromJson(
                {...doc.data() as Map<String, dynamic>, 'id': doc.id},
              ))
          .toList();
    } catch (e) {
      throw Exception('Error fetching competitions: $e');
    }
  }

  /// Get active competitions
  Future<List<CompetitionModel>> getActiveCompetitions() async {
    try {
      final snapshot = await _competitionsCollection
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => CompetitionModel.fromJson(
                {...doc.data() as Map<String, dynamic>, 'id': doc.id},
              ))
          .toList();
    } catch (e) {
      throw Exception('Error fetching active competitions: $e');
    }
  }

  /// Get a single competition by ID
  Future<CompetitionModel?> getCompetitionById(String competitionId) async {
    try {
      final doc = await _competitionsCollection.doc(competitionId).get();

      if (!doc.exists) return null;

      return CompetitionModel.fromJson(
        {...doc.data() as Map<String, dynamic>, 'id': doc.id},
      );
    } catch (e) {
      throw Exception('Error fetching competition: $e');
    }
  }

  /// Get competitions by target audience
  Future<List<CompetitionModel>> getCompetitionsByAudience(String audience) async {
    try {
      final snapshot = await _competitionsCollection
          .where('targetAudience', isEqualTo: audience)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => CompetitionModel.fromJson(
                {...doc.data() as Map<String, dynamic>, 'id': doc.id},
              ))
          .toList();
    } catch (e) {
      throw Exception('Error fetching competitions by audience: $e');
    }
  }

  // ==================== CREATE/UPDATE/DELETE METHODS ====================

  /// Add a new competition
  Future<String> addCompetition(CompetitionModel competition) async {
    try {
      final docRef = await _competitionsCollection.add(competition.toJson());
      return docRef.id;
    } catch (e) {
      throw Exception('Error adding competition: $e');
    }
  }

  /// Add competition with custom ID
  Future<void> setCompetition(String id, CompetitionModel competition) async {
    try {
      await _competitionsCollection.doc(id).set(competition.toJson());
    } catch (e) {
      throw Exception('Error setting competition: $e');
    }
  }

  /// Update an existing competition
  Future<void> updateCompetition(String competitionId, Map<String, dynamic> data) async {
    try {
      await _competitionsCollection.doc(competitionId).update(data);
    } catch (e) {
      throw Exception('Error updating competition: $e');
    }
  }

  /// Update competition status (active/inactive)
  Future<void> updateCompetitionStatus(String competitionId, bool isActive) async {
    try {
      await _competitionsCollection.doc(competitionId).update({
        'isActive': isActive,
      });
    } catch (e) {
      throw Exception('Error updating competition status: $e');
    }
  }

  /// Delete a competition
  Future<void> deleteCompetition(String competitionId) async {
    try {
      await _competitionsCollection.doc(competitionId).delete();
    } catch (e) {
      throw Exception('Error deleting competition: $e');
    }
  }

  // ==================== QUERY METHODS ====================

  /// Check if competition name already exists
  Future<bool> competitionNameExists(String name, {String? excludeId}) async {
    try {
      Query query = _competitionsCollection.where('competitionName', isEqualTo: name);

      final snapshot = await query.get();

      if (excludeId != null) {
        return snapshot.docs.any((doc) => doc.id != excludeId);
      }

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Error checking competition name: $e');
    }
  }

  /// Get competitions count
  Future<int> getCompetitionsCount() async {
    try {
      final snapshot = await _competitionsCollection.get();
      return snapshot.docs.length;
    } catch (e) {
      throw Exception('Error getting competitions count: $e');
    }
  }

  /// Get active competitions count
  Future<int> getActiveCompetitionsCount() async {
    try {
      final snapshot = await _competitionsCollection
          .where('isActive', isEqualTo: true)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      throw Exception('Error getting active competitions count: $e');
    }
  }

  /// Search competitions by name
  Future<List<CompetitionModel>> searchCompetitionsByName(String searchQuery) async {
    try {
      final snapshot = await _competitionsCollection
          .orderBy('competitionName')
          .startAt([searchQuery])
          .endAt(['$searchQuery\uf8ff'])
          .get();

      return snapshot.docs
          .map((doc) => CompetitionModel.fromJson(
                {...doc.data() as Map<String, dynamic>, 'id': doc.id},
              ))
          .toList();
    } catch (e) {
      throw Exception('Error searching competitions: $e');
    }
  }

  /// Get ongoing competitions (within date range)
  Future<List<CompetitionModel>> getOngoingCompetitions() async {
    try {
      final now = DateTime.now();
      final snapshot = await _competitionsCollection
          .where('isActive', isEqualTo: true)
          .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .where('endDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .orderBy('startDate')
          .orderBy('endDate')
          .get();

      return snapshot.docs
          .map((doc) => CompetitionModel.fromJson(
                {...doc.data() as Map<String, dynamic>, 'id': doc.id},
              ))
          .toList();
    } catch (e) {
      throw Exception('Error fetching ongoing competitions: $e');
    }
  }

  /// Get upcoming competitions
  Future<List<CompetitionModel>> getUpcomingCompetitions() async {
    try {
      final now = DateTime.now();
      final snapshot = await _competitionsCollection
          .where('isActive', isEqualTo: true)
          .where('startDate', isGreaterThan: Timestamp.fromDate(now))
          .orderBy('startDate')
          .get();

      return snapshot.docs
          .map((doc) => CompetitionModel.fromJson(
                {...doc.data() as Map<String, dynamic>, 'id': doc.id},
              ))
          .toList();
    } catch (e) {
      throw Exception('Error fetching upcoming competitions: $e');
    }
  }

  /// Get past competitions
  Future<List<CompetitionModel>> getPastCompetitions() async {
    try {
      final now = DateTime.now();
      final snapshot = await _competitionsCollection
          .where('endDate', isLessThan: Timestamp.fromDate(now))
          .orderBy('endDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => CompetitionModel.fromJson(
                {...doc.data() as Map<String, dynamic>, 'id': doc.id},
              ))
          .toList();
    } catch (e) {
      throw Exception('Error fetching past competitions: $e');
    }
  }

  // ==================== BATCH OPERATIONS ====================

  /// Batch update multiple competitions
  Future<void> batchUpdateCompetitions(Map<String, Map<String, dynamic>> updates) async {
    try {
      final batch = _firestore.batch();

      updates.forEach((competitionId, data) {
        final docRef = _competitionsCollection.doc(competitionId);
        batch.update(docRef, data);
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Error batch updating competitions: $e');
    }
  }

  /// Batch delete competitions
  Future<void> batchDeleteCompetitions(List<String> competitionIds) async {
    try {
      final batch = _firestore.batch();

      for (final id in competitionIds) {
        final docRef = _competitionsCollection.doc(id);
        batch.delete(docRef);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Error batch deleting competitions: $e');
    }
  }

  /// Initialize the competitions collection
  Future<void> initializeCollection() async {
    try {
      final snapshot = await _competitionsCollection.limit(1).get();

      if (snapshot.docs.isEmpty) {
        // Create a dummy document to initialize the collection
        await _competitionsCollection.doc('_init').set({
          'initialized': true,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Delete the dummy document
        await _competitionsCollection.doc('_init').delete();
      }
    } catch (e) {
      throw Exception('Error initializing competitions collection: $e');
    }
  }

  // ==================== COMPETITION RESULTS METHODS ====================

  /// Save competition result for a user
  Future<String> saveCompetitionResult({
    required String userId,
    required String competitionId,
    required double score,
    required double totalQuestions,
    required int correctAnswers,
    required DateTime completedAt,
  }) async {
    try {
      final resultsCollection = _firestore.collection('competitionResults');

      // Check if user already completed this competition
      final existingResult = await resultsCollection
          .where('userId', isEqualTo: userId)
          .where('competitionId', isEqualTo: competitionId)
          .limit(1)
          .get();

      String resultId;

      if (existingResult.docs.isNotEmpty) {
        // Update existing result if new score is better
        final existingDoc = existingResult.docs.first;
        final existingScore = (existingDoc.data()['score'] is int)
            ? (existingDoc.data()['score'] as int).toDouble()
            : (existingDoc.data()['score'] as double? ?? 0.0);

        if (score > existingScore) {
          // Update with better score
          await existingDoc.reference.update({
            'score': score,
            'correctAnswers': correctAnswers,
            'completedAt': Timestamp.fromDate(completedAt),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        resultId = existingDoc.id;
      } else {
        // Create new result
        final docRef = await resultsCollection.add({
          'userId': userId,
          'competitionId': competitionId,
          'score': score,
          'totalQuestions': totalQuestions,
          'correctAnswers': correctAnswers,
          'completedAt': Timestamp.fromDate(completedAt),
          'createdAt': FieldValue.serverTimestamp(),
        });
        resultId = docRef.id;
      }

      return resultId;
    } catch (e) {
      throw Exception('Error saving competition result: $e');
    }
  }

  /// Get user's competition results
  Future<List<Map<String, dynamic>>> getUserCompetitionResults(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('competitionResults')
          .where('userId', isEqualTo: userId)
          .orderBy('completedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => {...doc.data(), 'id': doc.id})
          .toList();
    } catch (e) {
      throw Exception('Error fetching user competition results: $e');
    }
  }

  /// Get competition leaderboard
  Future<List<Map<String, dynamic>>> getCompetitionLeaderboard(
    String competitionId, {
    int limit = 10,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('competitionResults')
          .where('competitionId', isEqualTo: competitionId)
          .orderBy('score', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => {...doc.data(), 'id': doc.id})
          .toList();
    } catch (e) {
      throw Exception('Error fetching competition leaderboard: $e');
    }
  }

  /// Check if user has completed a competition
  Future<bool> hasUserCompletedCompetition(String userId, String competitionId) async {
    try {
      final snapshot = await _firestore
          .collection('competitionResults')
          .where('userId', isEqualTo: userId)
          .where('competitionId', isEqualTo: competitionId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Error checking competition completion: $e');
    }
  }

  /// Get user's result for a specific competition
  Future<Map<String, dynamic>?> getUserCompetitionResult(String userId, String competitionId) async {
    try {
      final snapshot = await _firestore
          .collection('competitionResults')
          .where('userId', isEqualTo: userId)
          .where('competitionId', isEqualTo: competitionId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return {...snapshot.docs.first.data(), 'id': snapshot.docs.first.id};
    } catch (e) {
      throw Exception('Error getting user competition result: $e');
    }
  }
}

