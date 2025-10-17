import 'package:church/core/models/user/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../network/local/cache_helper.dart';
import '../constants/auth_constants.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRepository({FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  Future<User?> signInWithEmailAndPassword(String email, String password) async {
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
    await CacheHelper.saveData(key: AuthConstants.cacheKeyIsLoggedIn, value: true);
    await CacheHelper.saveData(key: AuthConstants.cacheKeyEmail, value: email);
    await CacheHelper.saveData(key: AuthConstants.cacheKeyLastLoginTime, value: now.millisecondsSinceEpoch);
    await CacheHelper.saveData(key: AuthConstants.cacheKeySessionExpiry, value: sessionExpiry.millisecondsSinceEpoch);

    print('✅ User session saved: $uid');
    print('📅 Session expires: $sessionExpiry (Duration: ${AuthConstants.sessionTimeout.inDays} days, ${AuthConstants.sessionTimeout.inHours % 24} hours)');
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
      // First check custom session expiry
      if (AuthConstants.forceReauthAfterTimeout) {
        final sessionExpiryMs = CacheHelper.getData(key: AuthConstants.cacheKeySessionExpiry);
        if (sessionExpiryMs != null) {
          final sessionExpiry = DateTime.fromMillisecondsSinceEpoch(sessionExpiryMs);
          if (DateTime.now().isAfter(sessionExpiry)) {
            print('❌ Custom session timeout expired at: $sessionExpiry');
            await _clearUserCache();
            return false;
          }
        }
      }

      final user = _firebaseAuth.currentUser;

      // Check if user exists
      if (user == null) {
        print('❌ Token validation failed: No user logged in');
        await _clearUserCache();
        return false;
      }

      // Reload user to ensure we have the latest auth state
      await user.reload();
      final reloadedUser = _firebaseAuth.currentUser;

      // Check if user still exists after reload
      if (reloadedUser == null) {
        print('❌ Token validation failed: User session expired');
        await _clearUserCache();
        return false;
      }

      // Get and validate the ID token
      final tokenResult = await reloadedUser.getIdTokenResult(true);

      // Check if Firebase token is expired
      final expirationTime = tokenResult.expirationTime;
      if (expirationTime != null && expirationTime.isBefore(DateTime.now())) {
        print('❌ Token validation failed: Firebase token expired at $expirationTime');
        await _clearUserCache();
        return false;
      }

      // Check if token needs refresh (within threshold of expiring)
      if (AuthConstants.autoRefreshTokens && expirationTime != null) {
        final timeUntilExpiry = expirationTime.difference(DateTime.now());
        if (timeUntilExpiry < AuthConstants.tokenRefreshThreshold) {
          print('🔄 Token expiring soon, refreshing...');
          await reloadedUser.getIdToken(true);
        }
      }

      // Verify token claims are valid
      if (tokenResult.token == null || tokenResult.token!.isEmpty) {
        print('❌ Token validation failed: Invalid token');
        await _clearUserCache();
        return false;
      }

      // Token is valid - sync cache with current user
      final cachedUid = CacheHelper.getData(key: AuthConstants.cacheKeyUserId);
      if (cachedUid != reloadedUser.uid) {
        await _saveUserSessionToCache(reloadedUser.uid, reloadedUser.email ?? '');
      }

      print('✅ Token validation successful for user: ${reloadedUser.uid}');
      return true;

    } on FirebaseAuthException catch (e) {
      print('❌ Token validation failed: Firebase Auth error - ${e.code}: ${e.message}');
      await _clearUserCache();
      return false;
    } catch (e) {
      print('❌ Token validation failed: Unexpected error - $e');
      await _clearUserCache();
      return false;
    }
  }

  /// Check if custom session has expired
  bool isSessionExpired() {
    final sessionExpiryMs = CacheHelper.getData(key: AuthConstants.cacheKeySessionExpiry);
    if (sessionExpiryMs == null) return true;

    final sessionExpiry = DateTime.fromMillisecondsSinceEpoch(sessionExpiryMs);
    return DateTime.now().isAfter(sessionExpiry);
  }

  /// Get remaining session time
  Duration? getRemainingSessionTime() {
    final sessionExpiryMs = CacheHelper.getData(key: AuthConstants.cacheKeySessionExpiry);
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
      print('♻️ Session extended for user: $uid');
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

  Future<User?> signUpWithEmailAndPassword(String email, String password,
      {Map<String, dynamic>? extraData}) async {
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
      print('✅ User registered and session saved: ${user.uid}');
    }
    return user;
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    // Clear cache on sign out
    await _clearUserCache();
    print('✅ User signed out and cache cleared');
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
}
