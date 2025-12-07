import 'dart:async';
import 'package:church/core/repositories/admin_repository.dart';
import 'package:church/core/blocs/admin_user/admin_user_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Cubit for managing admin user operations
class AdminUserCubit extends Cubit<AdminUserState> {
  final AdminRepository _adminRepository;
  StreamSubscription? _usersSubscription;
  StreamSubscription? _registrationRequestsSubscription;
  StreamSubscription? _pendingRequestsSubscription;
  StreamSubscription? _pendingCountSubscription;

  AdminUserCubit({AdminRepository? adminRepository})
      : _adminRepository = adminRepository ?? AdminRepository(),
        super(AdminUserInitial());

  static AdminUserCubit get(context) => BlocProvider.of(context);

  /// Safe emit that checks if cubit is closed
  void _safeEmit(AdminUserState state) {
    if (!isClosed) {
      emit(state);
    }
  }


  // ============ USER CRUD OPERATIONS ============

  /// Load all users
  void loadAllUsers() {
    _safeEmit(AdminUserLoading());
    try {
      // Cancel previous subscription if exists
      _usersSubscription?.cancel();

      _usersSubscription = _adminRepository.getAllUsers().listen(
        (users) {
          _safeEmit(AdminUserLoaded(users));
        },
        onError: (error) {
          _safeEmit(AdminUserError(error.toString()));
          debugPrint(error.toString());
        },
      );
    } catch (e) {
      _safeEmit(AdminUserError(e.toString()));
      debugPrint(e.toString());
    }
  }

  /// Get user by ID
  Future<void> getUserById(String userId) async {
    _safeEmit(AdminUserLoading());
    try {
      final user = await _adminRepository.getUserById(userId);
      _safeEmit(AdminUserLoaded([user]));
    } catch (e) {
      _safeEmit(AdminUserError(e.toString()));
      debugPrint(e.toString());
    }
  }

  /// Create a new user
  Future<void> createUser({
    required String email,
    required String password,
    required Map<String, dynamic> userData,
  }) async {
    _safeEmit(AdminUserLoading());
    try {
      final userId = await _adminRepository.createUser(
        email: email,
        password: password,
        userData: userData,
      );
      _safeEmit(AdminUserCreated(userId));
    } catch (e) {
      _safeEmit(AdminUserError(e.toString()));
    }
  }

  /// Update user
  Future<void> updateUser(String userId, Map<String, dynamic> userData) async {
    _safeEmit(AdminUserLoading());
    try {
      await _adminRepository.updateUser(userId, userData);
      _safeEmit(AdminUserUpdated());
    } catch (e) {
      _safeEmit(AdminUserError(e.toString()));
      debugPrint(e.toString());
    }
  }

  /// Delete user
  Future<void> deleteUser(String userId) async {
    _safeEmit(AdminUserLoading());
    try {
      await _adminRepository.deleteUser(userId);
      _safeEmit(AdminUserDeleted());
    } catch (e) {
      _safeEmit(AdminUserError(e.toString()));
      debugPrint(e.toString());
    }
  }

  /// Toggle user active status (enable/disable)
  Future<void> toggleUserStatus(String userId, bool isActive) async {
    _safeEmit(AdminUserLoading());
    try {
      await _adminRepository.updateUser(userId, {'isActive': isActive});
      _safeEmit(AdminUserUpdated());
    } catch (e) {
      _safeEmit(AdminUserError(e.toString()));
      debugPrint(e.toString());
    }
  }

  /// Reset user password
  /// Generates a new temporary password and returns it to be shown to the admin
  Future<void> resetUserPassword(String userId) async {
    _safeEmit(AdminUserLoading());
    try {
      final temporaryPassword = await _adminRepository.resetUserPassword(userId);
      _safeEmit(AdminPasswordReset(temporaryPassword: temporaryPassword));
    } catch (e) {
      _safeEmit(AdminUserError('فشل إعادة تعيين كلمة المرور: ${e.toString()}'));
      debugPrint(e.toString());
    }
  }

  /// Search users
  Future<void> searchUsers(String query) async {
    _safeEmit(AdminUserLoading());
    try {
      final users = await _adminRepository.searchUsers(query);
      _safeEmit(AdminUserSearchResults(users));
    } catch (e) {
      _safeEmit(AdminUserError(e.toString()));
      debugPrint(e.toString());
    }
  }

  /// Load users by type
  void loadUsersByType(String userType) {
    _safeEmit(AdminUserLoading());
    try {
      // Cancel previous subscription if exists
      _usersSubscription?.cancel();

      _usersSubscription = _adminRepository.getUsersByType(userType).listen(
        (users) {
          _safeEmit(AdminUserLoaded(users));
        },
        onError: (error) {
          _safeEmit(AdminUserError(error.toString()));
          debugPrint(error.toString());
        },
      );
    } catch (e) {
      _safeEmit(AdminUserError(e.toString()));
      debugPrint(e.toString());
    }
  }

  /// Load users by class
  void loadUsersByClass(String userClass) {
    _safeEmit(AdminUserLoading());
    try {
      // Cancel previous subscription if exists
      _usersSubscription?.cancel();

      _usersSubscription = _adminRepository.getUsersByClass(userClass).listen(
        (users) {
          _safeEmit(AdminUserLoaded(users));
        },
        onError: (error) {
          _safeEmit(AdminUserError(error.toString()));
          debugPrint(error.toString());
        },
      );
    } catch (e) {
      _safeEmit(AdminUserError(e.toString()));
      debugPrint(e.toString());
    }
  }

  /// Get user statistics
  Future<void> getUserStatistics() async {
    _safeEmit(AdminUserLoading());
    try {
      final stats = await _adminRepository.getUserStatistics();
      _safeEmit(AdminUserStatisticsLoaded(stats));
    } catch (e) {
      _safeEmit(AdminUserError(e.toString()));
    }
  }

  // ============ REGISTRATION REQUEST OPERATIONS ============

  /// Load all registration requests
  void loadAllRegistrationRequests() {
    _safeEmit(AdminUserLoading());
    try {
      // Cancel previous subscription if exists
      _registrationRequestsSubscription?.cancel();

      _registrationRequestsSubscription = _adminRepository.getAllRegistrationRequests().listen(
        (requests) {
          _safeEmit(AdminRegistrationRequestsLoaded(requests));
        },
        onError: (error) {
          _safeEmit(AdminUserError(error.toString()));
        },
      );
    } catch (e) {
      _safeEmit(AdminUserError(e.toString()));
    }
  }

  /// Load pending registration requests
  void loadPendingRegistrationRequests() {
    _safeEmit(AdminUserLoading());
    try {
      // Cancel previous subscription if exists
      _pendingRequestsSubscription?.cancel();

      _pendingRequestsSubscription = _adminRepository.getPendingRegistrationRequests().listen(
        (requests) {
          _safeEmit(AdminPendingRequestsLoaded(requests, requests.length));
        },
        onError: (error) {
          _safeEmit(AdminUserError(error.toString()));
        },
      );
    } catch (e) {
      _safeEmit(AdminUserError(e.toString()));
    }
  }

  /// Get pending requests count
  void getPendingRequestsCount() {
    try {
      // Cancel previous subscription if exists
      _pendingCountSubscription?.cancel();

      _pendingCountSubscription = _adminRepository.getPendingRequestsCount().listen(
        (count) {
          // You can emit a specific state for count if needed
        },
        onError: (error) {
          _safeEmit(AdminUserError(error.toString()));
        },
      );
    } catch (e) {
      _safeEmit(AdminUserError(e.toString()));
    }
  }

  /// Approve registration request
  /// Note: This will log out the admin due to Firebase limitation
  Future<void> approveRegistrationRequest(
    String requestId,
    String adminId,
  ) async {
    _safeEmit(AdminUserLoading());
    try {
      final temporaryPassword = await _adminRepository.approveRegistrationRequest(
        requestId,
        adminId,
      );
      // Creating a user logs out the admin, so emit session lost state
      _safeEmit(AdminSessionLost(
        'تم إنشاء المستخدم بنجاح. يرجى تسجيل الدخول مرة أخرى.',
        temporaryPassword: temporaryPassword,
      ));
    } catch (e) {
      _safeEmit(AdminUserError(e.toString()));
    }
  }

  /// Reject registration request
  Future<void> rejectRegistrationRequest(
    String requestId,
    String adminId,
    String rejectionReason,
  ) async {
    _safeEmit(AdminUserLoading());
    try {
      await _adminRepository.rejectRegistrationRequest(
        requestId,
        adminId,
        rejectionReason,
      );
      _safeEmit(AdminRequestRejected(requestId));
    } catch (e) {
      _safeEmit(AdminUserError(e.toString()));
    }
  }

  /// Delete registration request
  Future<void> deleteRegistrationRequest(String requestId) async {
    _safeEmit(AdminUserLoading());
    try {
      await _adminRepository.deleteRegistrationRequest(requestId);
      _safeEmit(AdminRequestDeleted());
    } catch (e) {
      _safeEmit(AdminUserError(e.toString()));
    }
  }

  /// Get registration request by ID
  Future<void> getRegistrationRequestById(String requestId) async {
    _safeEmit(AdminUserLoading());
    try {
      final request = await _adminRepository.getRegistrationRequestById(requestId);
      _safeEmit(AdminRegistrationRequestsLoaded([request]));
    } catch (e) {
      _safeEmit(AdminUserError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    // Cancel all stream subscriptions to prevent memory leaks
    _usersSubscription?.cancel();
    _registrationRequestsSubscription?.cancel();
    _pendingRequestsSubscription?.cancel();
    _pendingCountSubscription?.cancel();
    return super.close();
  }
}

