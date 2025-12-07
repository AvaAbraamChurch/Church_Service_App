import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../network/local/cache_helper.dart';

/// Service to manage multiple user accounts and switching between them
class AccountManagerService {
  static const String _accountsKey = 'saved_accounts';
  static const String _activeAccountKey = 'active_account_id';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all saved accounts
  Future<List<Map<String, dynamic>>> getSavedAccounts() async {
    try {
      final accountsJson = await CacheHelper.getData(key: _accountsKey);
      if (accountsJson == null) return [];

      final List<dynamic> accountsList = accountsJson as List<dynamic>;
      return accountsList.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      debugPrint('Error getting saved accounts: $e');
      return [];
    }
  }

  /// Save account credentials after successful login
  Future<void> saveAccount({
    required String userId,
    required String email,
    required String password,
    required String displayName,
    String? photoUrl,
    required String userType,
  }) async {
    try {
      final accounts = await getSavedAccounts();

      // Check if account already exists
      final existingIndex = accounts.indexWhere((acc) => acc['userId'] == userId);

      final accountData = {
        'userId': userId,
        'email': email,
        'password': password, // Encrypted in production
        'displayName': displayName,
        'photoUrl': photoUrl,
        'userType': userType,
        'lastUsed': DateTime.now().toIso8601String(),
      };

      if (existingIndex >= 0) {
        // Update existing account
        accounts[existingIndex] = accountData;
      } else {
        // Add new account
        accounts.add(accountData);
      }

      await CacheHelper.saveData(key: _accountsKey, value: accounts);
      await CacheHelper.saveData(key: _activeAccountKey, value: userId);
      debugPrint('Account saved: $email');
    } catch (e) {
      debugPrint('Error saving account: $e');
    }
  }

  /// Switch to a different saved account
  Future<bool> switchAccount(String userId) async {
    try {
      final accounts = await getSavedAccounts();
      final account = accounts.firstWhere(
        (acc) => acc['userId'] == userId,
        orElse: () => {},
      );

      if (account.isEmpty) {
        debugPrint('Account not found: $userId');
        return false;
      }

      // Sign out current user
      await _auth.signOut();

      // Sign in with saved credentials
      final email = account['email'] as String;
      final password = account['password'] as String;

      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update last used timestamp
      account['lastUsed'] = DateTime.now().toIso8601String();
      final index = accounts.indexWhere((acc) => acc['userId'] == userId);
      accounts[index] = account;

      await CacheHelper.saveData(key: _accountsKey, value: accounts);
      await CacheHelper.saveData(key: _activeAccountKey, value: userId);

      debugPrint('Switched to account: $email');
      return true;
    } catch (e) {
      debugPrint('Error switching account: $e');
      return false;
    }
  }

  /// Remove an account from saved accounts
  Future<void> removeAccount(String userId) async {
    try {
      final accounts = await getSavedAccounts();
      accounts.removeWhere((acc) => acc['userId'] == userId);

      await CacheHelper.saveData(key: _accountsKey, value: accounts);

      // If removed account was active, clear active account
      final activeAccountId = await CacheHelper.getData(key: _activeAccountKey);
      if (activeAccountId == userId) {
        await CacheHelper.removeData(key: _activeAccountKey);
      }

      debugPrint('Account removed: $userId');
    } catch (e) {
      debugPrint('Error removing account: $e');
    }
  }

  /// Get currently active account ID
  Future<String?> getActiveAccountId() async {
    try {
      return await CacheHelper.getData(key: _activeAccountKey);
    } catch (e) {
      debugPrint('Error getting active account: $e');
      return null;
    }
  }

  /// Check if user has multiple accounts
  Future<bool> hasMultipleAccounts() async {
    final accounts = await getSavedAccounts();
    return accounts.length > 1;
  }

  /// Get account count
  Future<int> getAccountCount() async {
    final accounts = await getSavedAccounts();
    return accounts.length;
  }

  /// Update account photo
  Future<void> updateAccountPhoto(String userId, String? photoUrl) async {
    try {
      final accounts = await getSavedAccounts();
      final index = accounts.indexWhere((acc) => acc['userId'] == userId);

      if (index >= 0) {
        accounts[index]['photoUrl'] = photoUrl;
        await CacheHelper.saveData(key: _accountsKey, value: accounts);
        debugPrint('Account photo updated: $userId');
      }
    } catch (e) {
      debugPrint('Error updating account photo: $e');
    }
  }

  /// Clear all saved accounts (for logout all)
  Future<void> clearAllAccounts() async {
    try {
      await CacheHelper.removeData(key: _accountsKey);
      await CacheHelper.removeData(key: _activeAccountKey);
      await _auth.signOut();
      debugPrint('All accounts cleared');
    } catch (e) {
      debugPrint('Error clearing accounts: $e');
    }
  }
}

