import 'package:church/core/models/user/user_model.dart';
import 'package:church/core/utils/userType_enum.dart';
import 'package:church/core/utils/gender_enum.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Service to check admin privileges
/// Admins are: priests or specific user IDs
class AdminService {
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // List of specific user IDs that have admin access (can be configured in Firebase or hardcoded)
  static const List<String> _adminUserIds = [
    // Add specific user IDs here if needed
    'h2xPvUO88qVuVwFed9YDqV33E2A2',
    // 'user_id_2',
  ];

  /// Check if current user is an admin (priest or in admin list)
  Future<bool> isAdmin() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // Check if user ID is in admin list
      if (_adminUserIds.contains(currentUser.uid)) {
        return true;
      }

      // Check if user is a priest
      final DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) return false;

      final data = userDoc.data() as Map<String, dynamic>?;
      if (data == null) return false;

      final String? userTypeCode = data['userType'] as String?;
      return userTypeCode == UserType.priest.code;
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      return false;
    }
  }

  /// Get current user data
  Future<UserModel?> getCurrentUser() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      final DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) return null;

      final data = userDoc.data() as Map<String, dynamic>?;
      if (data == null) return null;

      // Use UserModel.fromFirestore if available, otherwise construct manually
      return UserModel(
        id: currentUser.uid,
        fullName: data['fullName'] ?? '',
        username: data['username'] ?? '',
        email: data['email'] ?? '',
        phoneNumber: data['phoneNumber'],
        address: data['address'],
        userType: UserTypeX.fromCode(data['userType'] ?? 'CH'),
        gender: GenderX.fromCode(data['gender'] ?? 'M'),
        userClass: data['class'] ?? '',
        serviceType: data['serviceType'],
        profileImageUrl: data['profileImageUrl'],
        couponPoints: data['couponPoints'] ?? 0,
        firstLogin: data['firstLogin'] ?? true,
      );
    } catch (e) {
      debugPrint('Error getting current user: $e');
      return null;
    }
  }

  /// Check if user is admin by user ID
  Future<bool> isUserAdmin(String userId) async {
    try {
      // Check if user ID is in admin list
      if (_adminUserIds.contains(userId)) {
        return true;
      }

      // Check if user is a priest
      final DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) return false;

      final data = userDoc.data() as Map<String, dynamic>?;
      if (data == null) return false;

      final String? userTypeCode = data['userType'] as String?;
      return userTypeCode == UserType.priest.code;
    } catch (e) {
      debugPrint('Error checking user admin status: $e');
      return false;
    }
  }
}

// Extension imports for fromCode methods
extension GenderX on Gender {
  static Gender fromCode(String code) {
    switch (code.toUpperCase()) {
      case 'M':
        return Gender.male;
      case 'F':
        return Gender.female;
      default:
        return Gender.male;
    }
  }
}

extension UserTypeX on UserType {
  static UserType fromCode(String code) {
    switch (code.toUpperCase()) {
      case 'PR':
        return UserType.priest;
      case 'SS':
        return UserType.superServant;
      case 'SV':
        return UserType.servant;
      case 'CH':
        return UserType.child;
      default:
        return UserType.child;
    }
  }
}

