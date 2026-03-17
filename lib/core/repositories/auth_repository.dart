import 'package:church/core/models/user/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../constants/auth_constants.dart';
import '../network/local/cache_helper.dart';
import '../utils/gender_enum.dart';
import '../utils/userType_enum.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRepository({FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  Future<User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    final result = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Save user data to cache after successful login with custom session expiry
    if (result.user != null) {
      await _saveUserSessionToCache(result.user!.uid, result.user!.email ?? '');
    }

    return result.user;
  }

  /// Save user session data to cache with custom expiration
  Future<void> _saveUserSessionToCache(String uid, String email) async {
    final now = DateTime.now();
    final sessionExpiry = now.add(AuthConstants.sessionTimeout);

    await CacheHelper.saveData(key: AuthConstants.cacheKeyUserId, value: uid);
    await CacheHelper.saveData(
      key: AuthConstants.cacheKeyIsLoggedIn,
      value: true,
    );
    await CacheHelper.saveData(key: AuthConstants.cacheKeyEmail, value: email);
    await CacheHelper.saveData(
      key: AuthConstants.cacheKeyLastLoginTime,
      value: now.millisecondsSinceEpoch,
    );
    await CacheHelper.saveData(
      key: AuthConstants.cacheKeySessionExpiry,
      value: sessionExpiry.millisecondsSinceEpoch,
    );

  }

  /// Save user profile data to cache for offline access
  Future<void> saveUserProfileToCache(UserModel user) async {
    await CacheHelper.saveData(
      key: AuthConstants.cacheKeyUserType,
      value: user.userType.code,
    );
    await CacheHelper.saveData(
      key: AuthConstants.cacheKeyUserClass,
      value: user.userClass,
    );
    await CacheHelper.saveData(
      key: AuthConstants.cacheKeyGender,
      value: user.gender.code,
    );
  }

  /// Get cached user profile data (for offline access)
  Map<String, dynamic>? getCachedUserProfile() {
    final userTypeCode = CacheHelper.getData(
      key: AuthConstants.cacheKeyUserType,
    );
    final userClass = CacheHelper.getData(key: AuthConstants.cacheKeyUserClass);
    final genderCode = CacheHelper.getData(key: AuthConstants.cacheKeyGender);

    if (userTypeCode == null || genderCode == null) {
      return null;
    }

    try {
      final userType = userTypeFromCode(userTypeCode);
      final gender = genderFromCode(genderCode);

      return {
        'userType': userType,
        'userClass': userClass ?? '',
        'gender': gender,
      };
    } catch (e) {
      return null;
    }
  }

  /// Get current user
  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  /// Get current user ID
  String? getCurrentUserId() {
    return _firebaseAuth.currentUser?.uid;
  }

  /// Get current user data using the UserModel
  Future<UserModel> getCurrentUserData() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('No user is currently logged in.');
    }
    final doc = await _firestore.collection('users').doc(user.uid).get();
    return UserModel.fromDocumentSnapshot(doc);
  }

  /// Validate Firebase Auth token with custom session timeout
  Future<bool> validateToken() async {
    try {
      // First check app-level session expiry
      if (AuthConstants.forceReauthAfterTimeout) {
        final sessionExpiryMs = CacheHelper.getData(
          key: AuthConstants.cacheKeySessionExpiry,
        );
        if (sessionExpiryMs != null) {
          final sessionExpiry = DateTime.fromMillisecondsSinceEpoch(
            sessionExpiryMs,
          );
          if (DateTime.now().isAfter(sessionExpiry)) {
            await _clearUserCache();
            return false;
          }
        }
      }

      final user = _firebaseAuth.currentUser;

      // Firebase Auth handles its own local persistence. If currentUser is null
      // after initialisation it means the user genuinely signed out or the
      // account was removed.
      if (user == null) {
        await _clearUserCache();
        return false;
      }

      // Use non-force token fetch to avoid unnecessary network round-trip.
      // Firebase SDK refreshes the token automatically when needed.
      try {
        final tokenResult = await user.getIdTokenResult(false);
        final expirationTime = tokenResult.expirationTime;

        if (expirationTime != null && expirationTime.isBefore(DateTime.now())) {
          // Token already expired â€“ force a silent refresh
          try {
            await user.getIdToken(true);
          } catch (refreshError) {
            await _clearUserCache();
            return false;
          }
        } else if (AuthConstants.autoRefreshTokens && expirationTime != null) {
          final timeUntilExpiry = expirationTime.difference(DateTime.now());
          if (timeUntilExpiry < AuthConstants.tokenRefreshThreshold) {
            // Fire-and-forget proactive refresh
            user.getIdToken(true).catchError((e) {
              return '';
            });
          }
        }
      } catch (tokenError) {
        // Token introspection failed â€“ could be transient network issue.
        // Don't log the user out for this; Firebase Auth still knows the user.
      }

      // Keep cache in sync with the Firebase user
      final cachedUid = CacheHelper.getData(key: AuthConstants.cacheKeyUserId);
      if (cachedUid != user.uid) {
        await _saveUserSessionToCache(user.uid, user.email ?? '');
      } else {
        // Extend session expiry so active users never get kicked out
        await extendSession();
      }

      return true;
    } on FirebaseAuthException catch (e) {
      // Only hard-clear for definitive account issues
      if (e.code == 'user-disabled' || e.code == 'user-not-found') {
        await _clearUserCache();
        return false;
      }
      // For any other Firebase error return true if we still have a user
      return _firebaseAuth.currentUser != null;
    } catch (e) {
      // Don't punish the user for transient errors
      return _firebaseAuth.currentUser != null;
    }
  }

  /// Check if custom session has expired
  bool isSessionExpired() {
    final sessionExpiryMs = CacheHelper.getData(
      key: AuthConstants.cacheKeySessionExpiry,
    );
    if (sessionExpiryMs == null) return true;

    final sessionExpiry = DateTime.fromMillisecondsSinceEpoch(sessionExpiryMs);
    return DateTime.now().isAfter(sessionExpiry);
  }

  /// Get remaining session time
  Duration? getRemainingSessionTime() {
    final sessionExpiryMs = CacheHelper.getData(
      key: AuthConstants.cacheKeySessionExpiry,
    );
    if (sessionExpiryMs == null) return null;

    final sessionExpiry = DateTime.fromMillisecondsSinceEpoch(sessionExpiryMs);
    final remaining = sessionExpiry.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Extend current session (refresh session expiry time)
  Future<void> extendSession() async {
    final uid = getSavedUserId();
    final email = getSavedEmail();
    if (uid.isNotEmpty && email.isNotEmpty) {
      await _saveUserSessionToCache(uid, email);
    }
  }

  /// Clear user data from cache
  Future<void> clearUserData() async {
    await _clearUserCache();
  }

  /// Clear user data from cache
  Future<void> _clearUserCache() async {
    await CacheHelper.removeData(key: AuthConstants.cacheKeyUserId);
    await CacheHelper.removeData(key: AuthConstants.cacheKeyIsLoggedIn);
    await CacheHelper.removeData(key: AuthConstants.cacheKeyEmail);
    await CacheHelper.removeData(key: AuthConstants.cacheKeyLastLoginTime);
    await CacheHelper.removeData(key: AuthConstants.cacheKeySessionExpiry);
    await CacheHelper.removeData(key: AuthConstants.cacheKeyUserType);
    await CacheHelper.removeData(key: AuthConstants.cacheKeyUserClass);
    await CacheHelper.removeData(key: AuthConstants.cacheKeyGender);
  }

  /// Check if user is logged in from cache
  bool isLoggedInFromCache() {
    return CacheHelper.getData(key: 'isLoggedIn') ?? false;
  }

  /// Get saved user ID from cache
  String getSavedUserId() {
    return CacheHelper.getData(key: AuthConstants.cacheKeyUserId) ?? '';
  }

  /// Get saved email from cache
  String getSavedEmail() {
    return CacheHelper.getData(key: AuthConstants.cacheKeyEmail) ?? '';
  }

  Future<User?> signUpWithEmailAndPassword(
    String email,
    String password, {
    Map<String, dynamic>? extraData,
  }) async {
    final result = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = result.user;
    if (user != null) {
      // Save user data to Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        ...?extraData,
      });

      // Save user session to cache with custom expiry
      await _saveUserSessionToCache(user.uid, email);
    }
    return user;
  }

  /// Create a registration request (for approval workflow)
  Future<String> createRegistrationRequest(
    Map<String, dynamic> requestData,
  ) async {
    try {
      final docRef = await _firestore.collection('registration_requests').add({
        ...requestData,
        'requestedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Ø®Ø·Ø£ ÙÙŠ Ø¥Ù†Ø´Ø§Ø¡ Ø·Ù„Ø¨ Ø§Ù„ØªØ³Ø¬ÙŠÙ„: $e');
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    // Clear cache on sign out
    await _clearUserCache();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> getUserData() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    return await _firestore.collection('users').doc(user.uid).get();
  }

  //Forget password
  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  /// Update user profile image URL in Firestore
  Future<void> updateUserProfileImage(String userId, String imageUrl) async {
    await _firestore.collection('users').doc(userId).update({
      'profileImageUrl': imageUrl,
    });
  }

  /// Change password for the current user
  /// Requires re-authentication with current password for security
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('No user is currently logged in');
    }

    // Re-authenticate user with current password
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );

    try {
      // Re-authenticate to ensure user knows the current password
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw Exception('ÙƒÙ„Ù…Ø© Ø§Ù„Ù…Ø±ÙˆØ± Ø§Ù„Ø­Ø§Ù„ÙŠØ© ØºÙŠØ± ØµØ­ÙŠØ­Ø©');
      } else if (e.code == 'weak-password') {
        throw Exception('ÙƒÙ„Ù…Ø© Ø§Ù„Ù…Ø±ÙˆØ± Ø§Ù„Ø¬Ø¯ÙŠØ¯Ø© Ø¶Ø¹ÙŠÙØ© Ø¬Ø¯Ø§Ù‹');
      } else {
        throw Exception('Ø­Ø¯Ø« Ø®Ø·Ø£: ${e.message}');
      }
    }
  }
}
