import 'package:church/core/models/user/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UsersRepository {
  final FirebaseFirestore _firestore;

  UsersRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> addUser(Map<String, dynamic> userData) async {
    try {
      await _firestore.collection('users').add(userData);
    } catch (e) {
      throw Exception('Error adding user: $e');
    }
  }

  Future<void> updateUser(String userId, Map<String, dynamic> userData) async {
    try {
      await _firestore.collection('users').doc(userId).update(userData);
    } catch (e) {
      throw Exception('Error updating user: $e');
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
    } catch (e) {
      throw Exception('Error deleting user: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => {
            'id': doc.id,
            ...doc.data(),
          }).toList();
    });
  }

  // New method to get user by userType
  Stream<List<UserModel>> getUsersByType(String userType) {
    return _firestore
        .collection('users')
        .where('userType', isEqualTo: userType)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromJson(doc.data()..putIfAbsent('id', () => doc.id)))
            .toList());
  }

  Stream<List<UserModel>> getUsersByMultipleTypes(String userClass, List<String> userTypes) {
    return _firestore
        .collection('users')
        .where('userType', whereIn: userTypes).where('userClass', isEqualTo: userClass)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => UserModel.fromJson(doc.data()))
        .toList());
  }

  Future<UserModel> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data()!..putIfAbsent('id', () => doc.id));
      }
      return Future.error('User not found');
    } catch (e) {
      throw Exception('Error fetching user: $e');
    }
  }
}
