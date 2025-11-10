import 'package:church/core/repositories/admin_repository.dart';
import 'package:church/core/blocs/admin_user/admin_user_states.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Cubit for managing admin user operations
class AdminUserCubit extends Cubit<AdminUserState> {
  final AdminRepository _adminRepository;

  AdminUserCubit({AdminRepository? adminRepository})
      : _adminRepository = adminRepository ?? AdminRepository(),
        super(AdminUserInitial());

  static AdminUserCubit get(context) => BlocProvider.of(context);


  // ============ USER CRUD OPERATIONS ============

  /// Load all users
  void loadAllUsers() {
    emit(AdminUserLoading());
    try {
      _adminRepository.getAllUsers().listen(
        (users) {
          emit(AdminUserLoaded(users));
        },
        onError: (error) {
          emit(AdminUserError(error.toString()));
        },
      );
    } catch (e) {
      emit(AdminUserError(e.toString()));
    }
  }

  /// Get user by ID
  Future<void> getUserById(String userId) async {
    emit(AdminUserLoading());
    try {
      final user = await _adminRepository.getUserById(userId);
      emit(AdminUserLoaded([user]));
    } catch (e) {
      emit(AdminUserError(e.toString()));
    }
  }

  /// Create a new user
  Future<void> createUser({
    required String email,
    required String password,
    required Map<String, dynamic> userData,
  }) async {
    emit(AdminUserLoading());
    try {
      final userId = await _adminRepository.createUser(
        email: email,
        password: password,
        userData: userData,
      );
      emit(AdminUserCreated(userId));
    } catch (e) {
      emit(AdminUserError(e.toString()));
    }
  }

  /// Update user
  Future<void> updateUser(String userId, Map<String, dynamic> userData) async {
    emit(AdminUserLoading());
    try {
      await _adminRepository.updateUser(userId, userData);
      emit(AdminUserUpdated());
    } catch (e) {
      emit(AdminUserError(e.toString()));
    }
  }

  /// Delete user
  Future<void> deleteUser(String userId) async {
    emit(AdminUserLoading());
    try {
      await _adminRepository.deleteUser(userId);
      emit(AdminUserDeleted());
    } catch (e) {
      emit(AdminUserError(e.toString()));
    }
  }

  /// Reset user password
  Future<void> resetUserPassword(String userId, String newPassword) async {
    emit(AdminUserLoading());
    try {
      await _adminRepository.resetUserPassword(userId, newPassword);
      emit(AdminUserUpdated());
    } catch (e) {
      emit(AdminUserError('فشل إعادة تعيين كلمة المرور: ${e.toString()}'));
    }
  }

  /// Search users
  Future<void> searchUsers(String query) async {
    emit(AdminUserLoading());
    try {
      final users = await _adminRepository.searchUsers(query);
      emit(AdminUserSearchResults(users));
    } catch (e) {
      emit(AdminUserError(e.toString()));
    }
  }

  /// Load users by type
  void loadUsersByType(String userType) {
    emit(AdminUserLoading());
    try {
      _adminRepository.getUsersByType(userType).listen(
        (users) {
          emit(AdminUserLoaded(users));
        },
        onError: (error) {
          emit(AdminUserError(error.toString()));
        },
      );
    } catch (e) {
      emit(AdminUserError(e.toString()));
    }
  }

  /// Load users by class
  void loadUsersByClass(String userClass) {
    emit(AdminUserLoading());
    try {
      _adminRepository.getUsersByClass(userClass).listen(
        (users) {
          emit(AdminUserLoaded(users));
        },
        onError: (error) {
          emit(AdminUserError(error.toString()));
        },
      );
    } catch (e) {
      emit(AdminUserError(e.toString()));
    }
  }

  /// Get user statistics
  Future<void> getUserStatistics() async {
    emit(AdminUserLoading());
    try {
      final stats = await _adminRepository.getUserStatistics();
      emit(AdminUserStatisticsLoaded(stats));
    } catch (e) {
      emit(AdminUserError(e.toString()));
    }
  }

  // ============ REGISTRATION REQUEST OPERATIONS ============

  /// Load all registration requests
  void loadAllRegistrationRequests() {
    emit(AdminUserLoading());
    try {
      _adminRepository.getAllRegistrationRequests().listen(
        (requests) {
          emit(AdminRegistrationRequestsLoaded(requests));
        },
        onError: (error) {
          emit(AdminUserError(error.toString()));
        },
      );
    } catch (e) {
      emit(AdminUserError(e.toString()));
    }
  }

  /// Load pending registration requests
  void loadPendingRegistrationRequests() {
    emit(AdminUserLoading());
    try {
      _adminRepository.getPendingRegistrationRequests().listen(
        (requests) {
          emit(AdminPendingRequestsLoaded(requests, requests.length));
        },
        onError: (error) {
          emit(AdminUserError(error.toString()));
        },
      );
    } catch (e) {
      emit(AdminUserError(e.toString()));
    }
  }

  /// Get pending requests count
  void getPendingRequestsCount() {
    try {
      _adminRepository.getPendingRequestsCount().listen(
        (count) {
          // You can emit a specific state for count if needed
        },
        onError: (error) {
          emit(AdminUserError(error.toString()));
        },
      );
    } catch (e) {
      emit(AdminUserError(e.toString()));
    }
  }

  /// Approve registration request
  Future<void> approveRegistrationRequest(
    String requestId,
    String adminId,
    String temporaryPassword,
  ) async {
    emit(AdminUserLoading());
    try {
      await _adminRepository.approveRegistrationRequest(
        requestId,
        adminId,
        temporaryPassword,
      );
      emit(AdminRequestApproved(requestId));
    } catch (e) {
      emit(AdminUserError(e.toString()));
    }
  }

  /// Reject registration request
  Future<void> rejectRegistrationRequest(
    String requestId,
    String adminId,
    String rejectionReason,
  ) async {
    emit(AdminUserLoading());
    try {
      await _adminRepository.rejectRegistrationRequest(
        requestId,
        adminId,
        rejectionReason,
      );
      emit(AdminRequestRejected(requestId));
    } catch (e) {
      emit(AdminUserError(e.toString()));
    }
  }

  /// Delete registration request
  Future<void> deleteRegistrationRequest(String requestId) async {
    emit(AdminUserLoading());
    try {
      await _adminRepository.deleteRegistrationRequest(requestId);
      emit(AdminRequestDeleted());
    } catch (e) {
      emit(AdminUserError(e.toString()));
    }
  }

  /// Get registration request by ID
  Future<void> getRegistrationRequestById(String requestId) async {
    emit(AdminUserLoading());
    try {
      final request = await _adminRepository.getRegistrationRequestById(requestId);
      emit(AdminRegistrationRequestsLoaded([request]));
    } catch (e) {
      emit(AdminUserError(e.toString()));
    }
  }
}

