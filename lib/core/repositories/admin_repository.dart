import 'dart:math';
import 'package:church/core/models/user/user_model.dart';
import 'package:church/core/models/registration_request_model.dart';
import 'package:church/core/utils/gender_enum.dart';
import 'package:church/core/utils/service_enum.dart';
import 'package:church/core/utils/userType_enum.dart';
import 'package:church/core/services/supabase_password_reset_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http; // 👈 Add this import for HTTP calls
import 'dart:convert'; // 👈 Add this for JSON encoding

/// Repository for admin operations including user management and registration requests
class AdminRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final SupabasePasswordResetService _supabaseService;

  final String _supabaseFunctionUrl;
  final String _adminApiKey;

  AdminRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    SupabasePasswordResetService? supabaseService,
    String? supabaseFunctionUrl,  // 👈 New parameter
    String? adminApiKey,          // 👈 New parameter
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _supabaseService = supabaseService ?? SupabasePasswordResetService(),
  // 👇 Use provided values or fallback to defaults (replace with env vars in production)
        _supabaseFunctionUrl = supabaseFunctionUrl ??
            'https://your-project-ref.functions.supabase.co/reset-password',
        _adminApiKey = adminApiKey ??
            const String.fromEnvironment('ADMIN_API_KEY', defaultValue: '');

  // ============ HELPER METHODS ============

  /// Generate a secure random temporary password
  /// Returns a password with 8 characters: mix of uppercase, lowercase, numbers, and special chars
  String generateTemporaryPassword({int length = 8}) {
    const String upperChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const String lowerChars = 'abcdefghijklmnopqrstuvwxyz';
    const String numbers = '0123456789';
    const String allChars = upperChars + lowerChars + numbers;

    final Random random = Random.secure();
    final List<String> password = [];

    // Ensure complexity: at least one of each type
    password.add(upperChars[random.nextInt(upperChars.length)]);
    password.add(lowerChars[random.nextInt(lowerChars.length)]);
    password.add(numbers[random.nextInt(numbers.length)]);

    // Fill the rest randomly
    for (int i = password.length; i < length; i++) {
      password.add(allChars[random.nextInt(allChars.length)]);
    }

    // Fisher-Yates shuffle for better randomness
    for (int i = password.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = password[i];
      password[i] = password[j];
      password[j] = temp;
    }

    return password.join();
  }

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
      // Note: This will automatically sign in the new user, logging out the admin
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userId = userCredential.user!.uid;

      // Add user data to Firestore
      await _firestore.collection('users').doc(userId).set({
        ...userData,
        // Ensure we persist userClass instead of legacy 'class'
        if (userData.containsKey('class') && !userData.containsKey('userClass'))
          'userClass': userData['class'],
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Sign out the newly created user
      await _auth.signOut();

      // Return userId - admin needs to re-login
      return userId;
    } catch (e) {
      throw Exception('Error creating user: $e');
    }
  }

  /// Update user data
  Future<void> updateUser(String userId, Map<String, dynamic> userData) async {
    try {
      // Normalize 'class' -> 'userClass' before updating to avoid writing both keys
      final normalizedData = Map<String, dynamic>.from(userData);
      if (normalizedData.containsKey('class') && !normalizedData.containsKey('userClass')) {
        normalizedData['userClass'] = normalizedData['class'];
        normalizedData.remove('class');
      }
      await _firestore.collection('users').doc(userId).update({
        ...normalizedData,
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

  /// 🔐 Reset user password using Supabase Edge Function
  ///
  /// Flow:
  /// 1. Get user's email from Firestore
  /// 2. Call Supabase Edge Function with email + admin auth
  /// 3. Edge Function resets password in Firebase Auth via REST API
  /// 4. Update Firestore with reset flags
  /// 5. Return temporary password (only shown to admin, not stored)
  ///
  /// Fallback: If Edge Function fails, send Firebase password reset email
  ///
  /// ⚠️ Security: Never store or log the temporary password in production
  Future<String> resetUserPassword(String userId) async {
    try {
      // Step 1: Get user's email and full name from Firestore
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('User not found in Firestore');
      }

      final userData = userDoc.data();
      final userEmail = userData?['email'] as String?;
      final userName = userData?['fullName'] as String? ?? 'User';

      if (userEmail == null || userEmail.isEmpty) {
        throw Exception('User email not found or invalid');
      }

      // Step 2: Try to reset password using Supabase Edge Function
      try {
        print('🔄 Calling Supabase Edge Function for password reset...');

        final temporaryPassword = await _supabaseService.resetUserPassword(
          // 👇 Pass email OR uid - Edge Function accepts either
          email: userEmail,
          // uid: userId,  // Alternative: use uid if you prefer
          fullName: userName,
          autoGenerate: true,  // Let Edge Function generate secure password
          // newPassword: 'Custom123!',  // Optional: provide custom password
        );

        print('✅ Supabase Edge Function succeeded');

        // Step 3: Update Firestore with reset flags (Edge Function also does this)
        await _firestore.collection('users').doc(userId).update({
          'firstLogin': true,
          'passwordResetRequested': true,
          'passwordResetAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          // 👇 Do NOT store the temporary password in Firestore in production
          // Only for debugging during development:
          // if (kDebugMode) 'temporaryPassword': temporaryPassword,
        });

        return temporaryPassword;

      } catch (supabaseError) {
        // 👇 Fallback: If Supabase function fails, use Firebase password reset email
        print('⚠️ Supabase Edge Function failed: $supabaseError');
        print('🔄 Falling back to Firebase password reset email...');

        // Generate a temporary password for admin reference (not stored in Firebase Auth)
        final temporaryPassword = generateTemporaryPassword();

        // Update Firestore with reset flags (but NOT the password)
        await _firestore.collection('users').doc(userId).update({
          'firstLogin': true,
          'passwordResetRequested': true,
          'passwordResetMethod': 'firebase_email_fallback',
          'passwordResetAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Send Firebase password reset email (user clicks link to set new password)
        await _auth.sendPasswordResetEmail(email: userEmail);

        print('✅ Firebase password reset email sent to $userEmail');

        // Return the generated password so admin can communicate it via secure channel
        // ⚠️ In production: Send this via SMS/secure email, not in-app alert
        return temporaryPassword;
      }

    } catch (e) {
      print('❌ Error in resetUserPassword: $e');
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
    // Query the modern 'userClass' field. Legacy documents using 'class' will be
    // ignored by this query; consider a migration if you need to include them.
    return _firestore
        .collection('users')
        .where('userClass', isEqualTo: userClass)
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
  /// Returns the generated temporary password that should be given to the user
  Future<String> approveRegistrationRequest(
      String requestId,
      String adminId,
      ) async {
    try {
      // Get the request
      final requestDoc =
      await _firestore.collection('registration_requests').doc(requestId).get();

      if (!requestDoc.exists) {
        throw Exception('Registration request not found');
      }

      final request = RegistrationRequest.fromMap(requestDoc.data()!, id: requestId);

      // Generate a secure temporary password
      final temporaryPassword = generateTemporaryPassword();

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
          // Store as 'userClass' instead of legacy 'class'
          'userClass': request.userClass,
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

      // Return the temporary password so it can be shown to the admin
      return temporaryPassword;
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