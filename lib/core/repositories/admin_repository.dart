import 'package:church/core/models/user/user_model.dart';
import 'package:church/core/models/registration_request_model.dart';
import 'package:church/core/utils/gender_enum.dart';
import 'package:church/core/utils/service_enum.dart';
import 'package:church/core/utils/userType_enum.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Repository for admin operations including user management and registration requests
class AdminRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  AdminRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  // ============ USER CRUD OPERATIONS ============

  /// Get all users with real-time updates
  Stream<List<UserModel>> getAllUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), id: doc.id))
          .toList();
    });
  }

  /// Get user by ID
  Future<UserModel> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data(), id: doc.id);
      }
      throw Exception('User not found');
    } catch (e) {
      throw Exception('Error fetching user: $e');
    }
  }

  /// Create a new user (with authentication)
  Future<String> createUser({
    required String email,
    required String password,
    required Map<String, dynamic> userData,
  }) async {
    try {
      // Create authentication account
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userId = userCredential.user!.uid;

      // Add user data to Firestore
      await _firestore.collection('users').doc(userId).set({
        ...userData,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return userId;
    } catch (e) {
      throw Exception('Error creating user: $e');
    }
  }

  /// Update user data
  Future<void> updateUser(String userId, Map<String, dynamic> userData) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        ...userData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error updating user: $e');
    }
  }

  /// Delete user (from Firestore and Authentication)
  Future<void> deleteUser(String userId) async {
    try {
      // Delete from Firestore
      await _firestore.collection('users').doc(userId).delete();

      // Note: Deleting from Firebase Auth requires the user to be signed in
      // or requires Admin SDK (server-side). For client-side, you may need
      // to use Cloud Functions to delete auth users.
    } catch (e) {
      throw Exception('Error deleting user: $e');
    }
  }

  /// Reset user password
  Future<void> resetUserPassword(String userId, String newPassword) async {
    try {
      // Get user's email
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final userEmail = userDoc.data()?['email'] as String?;
      if (userEmail == null) {
        throw Exception('User email not found');
      }

      // Note: Updating password for another user requires Firebase Admin SDK
      // For production, you should implement this as a Cloud Function
      // For now, we'll update the firstLogin flag to force password change
      await _firestore.collection('users').doc(userId).update({
        'firstLogin': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // TODO: Implement Cloud Function to actually reset password
      // Example Cloud Function endpoint:
      // await http.post('/admin/resetPassword', body: {'userId': userId, 'password': newPassword});

    } catch (e) {
      throw Exception('Error resetting password: $e');
    }
  }

  /// Search users by name, email, or username
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final snapshot = await _firestore.collection('users').get();
      final allUsers = snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), id: doc.id))
          .toList();

      final lowerQuery = query.toLowerCase();
      return allUsers.where((user) {
        return user.fullName.toLowerCase().contains(lowerQuery) ||
            user.email.toLowerCase().contains(lowerQuery) ||
            user.username.toLowerCase().contains(lowerQuery);
      }).toList();
    } catch (e) {
      throw Exception('Error searching users: $e');
    }
  }

  /// Get users by type
  Stream<List<UserModel>> getUsersByType(String userType) {
    return _firestore
        .collection('users')
        .where('userType', isEqualTo: userType)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data(), id: doc.id))
            .toList());
  }

  /// Get users by class
  Stream<List<UserModel>> getUsersByClass(String userClass) {
    return _firestore
        .collection('users')
        .where('class', isEqualTo: userClass)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data(), id: doc.id))
            .toList());
  }

  /// Get user statistics
  Future<Map<String, int>> getUserStatistics() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      final users = snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), id: doc.id))
          .toList();

      return {
        'total': users.length,
        'priests': users.where((u) => u.userType.code == 'PR').length,
        'servants': users.where((u) => u.userType.code == 'SS').length,
        'service': users.where((u) => u.userType.code == 'SV').length,
        'children': users.where((u) => u.userType.code == 'CH').length,
        'male': users.where((u) => u.gender.code == 'M').length,
        'female': users.where((u) => u.gender.code == 'F').length,
      };
    } catch (e) {
      throw Exception('Error fetching statistics: $e');
    }
  }

  // ============ REGISTRATION REQUEST OPERATIONS ============

  /// Get all registration requests
  Stream<List<RegistrationRequest>> getAllRegistrationRequests() {
    return _firestore
        .collection('registration_requests')
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RegistrationRequest.fromMap(doc.data(), id: doc.id))
            .toList());
  }

  /// Get pending registration requests
  Stream<List<RegistrationRequest>> getPendingRegistrationRequests() {
    return _firestore
        .collection('registration_requests')
        .where('status', isEqualTo: 'pending')
        .orderBy('requestedAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RegistrationRequest.fromMap(doc.data(), id: doc.id))
            .toList());
  }

  /// Get count of pending registration requests
  Stream<int> getPendingRequestsCount() {
    return _firestore
        .collection('registration_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Create a registration request (called during user signup)
  Future<String> createRegistrationRequest(Map<String, dynamic> requestData) async {
    try {
      final docRef = await _firestore.collection('registration_requests').add({
        ...requestData,
        'requestedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Error creating registration request: $e');
    }
  }

  /// Approve a registration request and create the user
  Future<void> approveRegistrationRequest(
    String requestId,
    String adminId,
    String temporaryPassword,
  ) async {
    try {
      // Get the request
      final requestDoc =
          await _firestore.collection('registration_requests').doc(requestId).get();

      if (!requestDoc.exists) {
        throw Exception('Registration request not found');
      }

      final request = RegistrationRequest.fromMap(requestDoc.data()!, id: requestId);

      // Create user with authentication
      final userId = await createUser(
        email: request.email,
        password: temporaryPassword,
        userData: {
          'fullName': request.fullName,
          'username': request.username,
          'phoneNumber': request.phoneNumber,
          'address': request.address,
          'userType': request.userType.code,
          'gender': request.gender.code,
          'class': request.userClass,
          'serviceType': request.serviceType.key,
          'profileImageUrl': request.profileImageUrl,
          'couponPoints': 0,
          'firstLogin': true,
          'isAdmin': false,
          'storeAdmin': false,
        },
      );

      // Update request status
      await _firestore.collection('registration_requests').doc(requestId).update({
        'status': 'approved',
        'reviewedBy': adminId,
        'reviewedAt': FieldValue.serverTimestamp(),
        'createdUserId': userId,
      });
    } catch (e) {
      throw Exception('Error approving registration request: $e');
    }
  }

  /// Reject a registration request
  Future<void> rejectRegistrationRequest(
    String requestId,
    String adminId,
    String rejectionReason,
  ) async {
    try {
      await _firestore.collection('registration_requests').doc(requestId).update({
        'status': 'rejected',
        'reviewedBy': adminId,
        'reviewedAt': FieldValue.serverTimestamp(),
        'rejectionReason': rejectionReason,
      });
    } catch (e) {
      throw Exception('Error rejecting registration request: $e');
    }
  }

  /// Delete a registration request
  Future<void> deleteRegistrationRequest(String requestId) async {
    try {
      await _firestore.collection('registration_requests').doc(requestId).delete();
    } catch (e) {
      throw Exception('Error deleting registration request: $e');
    }
  }

  /// Get registration request by ID
  Future<RegistrationRequest> getRegistrationRequestById(String requestId) async {
    try {
      final doc = await _firestore.collection('registration_requests').doc(requestId).get();
      if (doc.exists) {
        return RegistrationRequest.fromMap(doc.data()!, id: doc.id);
      }
      throw Exception('Registration request not found');
    } catch (e) {
      throw Exception('Error fetching registration request: $e');
    }
  }
}
