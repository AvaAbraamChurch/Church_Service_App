import 'package:church/core/models/attendance/attendance_model.dart';
import 'package:church/core/utils/userType_enum.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceRepository {
  final FirebaseFirestore _firestore;
  static const String _collectionName = 'attendance';

  AttendanceRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Initialize the attendance collection if it doesn't exist
  /// This creates the collection with an initial dummy document that can be deleted later
  Future<void> initializeCollection() async {
    try {
      final collection = _firestore.collection(_collectionName);
      final snapshot = await collection.limit(1).get();

      if (snapshot.docs.isEmpty) {
        // Create a dummy document to initialize the collection
        await collection.doc('_init').set({
          'initialized': true,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Optionally delete the dummy document
        await collection.doc('_init').delete();
      }
    } catch (e) {
      throw Exception('Error initializing attendance collection: $e');
    }
  }

  /// Add a new attendance record
  Future<String> addAttendance(AttendanceModel attendance) async {
    try {
      final docRef = await _firestore.collection(_collectionName).add(attendance.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Error adding attendance: $e');
    }
  }

  /// Add attendance with custom ID
  Future<void> setAttendance(String id, AttendanceModel attendance) async {
    try {
      await _firestore.collection(_collectionName).doc(id).set(attendance.toMap());
    } catch (e) {
      throw Exception('Error setting attendance: $e');
    }
  }

  /// Update an existing attendance record
  Future<void> updateAttendance(String attendanceId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_collectionName).doc(attendanceId).update(data);
    } catch (e) {
      throw Exception('Error updating attendance: $e');
    }
  }

  /// Delete an attendance record
  Future<void> deleteAttendance(String attendanceId) async {
    try {
      await _firestore.collection(_collectionName).doc(attendanceId).delete();
    } catch (e) {
      throw Exception('Error deleting attendance: $e');
    }
  }

  /// Get all attendance records as a stream
  Stream<List<AttendanceModel>> getAttendanceStream() {
    return _firestore
        .collection(_collectionName)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AttendanceModel.fromMap(doc.data(), id: doc.id))
            .toList());
  }

  /// Get all attendance records as a future
  Future<List<AttendanceModel>> getAttendanceFuture() async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => AttendanceModel.fromMap(doc.data(), id: doc.id))
          .toList();
    } catch (e) {
      throw Exception('Error fetching attendance: $e');
    }
  }

  /// Get attendance records by user type (stream)
  Stream<List<AttendanceModel>> getAttendanceByUserTypeStream(UserType userType) {
    return _firestore
        .collection(_collectionName)
        .where('userType', isEqualTo: userTypeToJson(userType))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AttendanceModel.fromMap(doc.data(), id: doc.id))
            .toList());
  }

  /// Get attendance records by user type (future)
  Future<List<AttendanceModel>> getAttendanceByUserTypeFuture(UserType userType) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userType', isEqualTo: userTypeToJson(userType))
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => AttendanceModel.fromMap(doc.data(), id: doc.id))
          .toList();
    } catch (e) {
      throw Exception('Error fetching attendance by user type: $e');
    }
  }

  /// Get attendance records by multiple user types (stream)
  Stream<List<AttendanceModel>> getAttendanceByMultipleTypesStream(List<UserType> userTypes) {
    final userTypeStrings = userTypes.map((type) => userTypeToJson(type)).toList();

    return _firestore
        .collection(_collectionName)
        .where('userType', whereIn: userTypeStrings)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AttendanceModel.fromMap(doc.data(), id: doc.id))
            .toList());
  }

  /// Get attendance records by multiple user types (future)
  Future<List<AttendanceModel>> getAttendanceByMultipleTypesFuture(List<UserType> userTypes) async {
    try {
      final userTypeStrings = userTypes.map((type) => userTypeToJson(type)).toList();

      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userType', whereIn: userTypeStrings)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => AttendanceModel.fromMap(doc.data(), id: doc.id))
          .toList();
    } catch (e) {
      throw Exception('Error fetching attendance by multiple user types: $e');
    }
  }

  /// Get attendance records for a specific user (stream)
  Stream<List<AttendanceModel>> getAttendanceByUserIdStream(String userId) {
    return _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AttendanceModel.fromMap(doc.data(), id: doc.id))
            .toList());
  }

  /// Get attendance records for a specific user (future)
  Future<List<AttendanceModel>> getAttendanceByUserIdFuture(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => AttendanceModel.fromMap(doc.data(), id: doc.id))
          .toList();
    } catch (e) {
      throw Exception('Error fetching attendance by user ID: $e');
    }
  }

  /// Get attendance records for a specific date range (stream)
  Stream<List<AttendanceModel>> getAttendanceByDateRangeStream(DateTime startDate, DateTime endDate) {
    return _firestore
        .collection(_collectionName)
        .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
        .where('date', isLessThanOrEqualTo: endDate.toIso8601String())
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AttendanceModel.fromMap(doc.data(), id: doc.id))
            .toList());
  }

  /// Get attendance records for a specific date range (future)
  Future<List<AttendanceModel>> getAttendanceByDateRangeFuture(DateTime startDate, DateTime endDate) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('date', isLessThanOrEqualTo: endDate.toIso8601String())
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => AttendanceModel.fromMap(doc.data(), id: doc.id))
          .toList();
    } catch (e) {
      throw Exception('Error fetching attendance by date range: $e');
    }
  }

  /// Get attendance by ID
  Future<AttendanceModel?> getAttendanceById(String attendanceId) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(attendanceId).get();
      if (doc.exists && doc.data() != null) {
        return AttendanceModel.fromMap(doc.data()!, id: doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching attendance by ID: $e');
    }
  }

  /// Batch insert multiple attendance records
  Future<void> batchAddAttendance(List<AttendanceModel> attendanceList) async {
    try {
      final batch = _firestore.batch();

      for (final attendance in attendanceList) {
        final docRef = _firestore.collection(_collectionName).doc();
        batch.set(docRef, attendance.toMap());
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Error batch adding attendance: $e');
    }
  }

  /// Check if attendance exists for a user on a specific date
  Future<AttendanceModel?> getAttendanceByUserAndDate(String userId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('date', isLessThanOrEqualTo: endOfDay.toIso8601String())
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return AttendanceModel.fromMap(snapshot.docs.first.data(), id: snapshot.docs.first.id);
      }
      return null;
    } catch (e) {
      throw Exception('Error checking attendance: $e');
    }
  }
}

