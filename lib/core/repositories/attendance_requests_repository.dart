import 'package:church/core/models/attendance/attendance_request_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceRequestsRepository {
  final FirebaseFirestore _firestore;
  static const String _collection = 'attendance_requests';

  AttendanceRequestsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(_collection);

  /// Create a request.
  /// Uses auto-id; duplicates are allowed (UI can prevent if needed).
  Future<String> createRequest(AttendanceRequestModel request) async {
    final doc = await _col.add(request.toMap());
    return doc.id;
  }

  Stream<List<AttendanceRequestModel>> streamForChild(String childId) {
    return _col
        .where('childId', isEqualTo: childId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(AttendanceRequestModel.fromDoc).toList());
  }

  Stream<List<AttendanceRequestModel>> streamPendingForPriest() {
    return _col
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(AttendanceRequestModel.fromDoc).toList());
  }

  Stream<List<AttendanceRequestModel>> streamPendingForSuperServant({
    required String gender,
  }) {
    return _col
        .where('status', isEqualTo: 'pending')
        .where('childGender', isEqualTo: gender)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(AttendanceRequestModel.fromDoc).toList());
  }

  Stream<List<AttendanceRequestModel>> streamPendingForServant({
    required String gender,
    required String userClass,
  }) {
    return _col
        .where('status', isEqualTo: 'pending')
        .where('childGender', isEqualTo: gender)
        .where('childClass', isEqualTo: userClass)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(AttendanceRequestModel.fromDoc).toList());
  }

  Future<void> updateRequest(String requestId, Map<String, dynamic> data) async {
    await _col.doc(requestId).update(data);
  }
}

