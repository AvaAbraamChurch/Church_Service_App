import 'package:church/core/models/user/user_model.dart';
import 'package:church/core/models/registration_request_model.dart';

/// Base state for admin user management
abstract class AdminUserState {}

class AdminUserInitial extends AdminUserState {}

class AdminUserLoading extends AdminUserState {}

class AdminUserLoaded extends AdminUserState {
  final List<UserModel> users;

  AdminUserLoaded(this.users);
}

class AdminUserError extends AdminUserState {
  final String message;

  AdminUserError(this.message);
}

class AdminUserCreated extends AdminUserState {
  final String userId;

  AdminUserCreated(this.userId);
}

/// Emitted after a single user is created via [AdminUserCubit.createSingleUser].
/// Carries the auto-generated credentials so the screen can display a summary card.
class AdminUserCreatedWithCredentials extends AdminUserState {
  final String userId;
  final String fullName;
  final String username;
  final String email;
  final String password;
  final String userType;

  AdminUserCreatedWithCredentials({
    required this.userId,
    required this.fullName,
    required this.username,
    required this.email,
    required this.password,
    required this.userType,
  });
}

class AdminUserUpdated extends AdminUserState {}

class AdminUserDeleted extends AdminUserState {}

class AdminUserSearchResults extends AdminUserState {
  final List<UserModel> users;

  AdminUserSearchResults(this.users);
}

class AdminUserStatisticsLoaded extends AdminUserState {
  final Map<String, int> statistics;

  AdminUserStatisticsLoaded(this.statistics);
}

// ============ REGISTRATION REQUEST STATES ============

class AdminRegistrationRequestsLoaded extends AdminUserState {
  final List<RegistrationRequest> requests;

  AdminRegistrationRequestsLoaded(this.requests);
}

class AdminPendingRequestsLoaded extends AdminUserState {
  final List<RegistrationRequest> requests;
  final int count;

  AdminPendingRequestsLoaded(this.requests, this.count);
}

class AdminRequestApproved extends AdminUserState {
  final String requestId;
  final String temporaryPassword;

  AdminRequestApproved(this.requestId, this.temporaryPassword);
}

class AdminRequestRejected extends AdminUserState {
  final String requestId;

  AdminRequestRejected(this.requestId);
}

class AdminRequestDeleted extends AdminUserState {}

class AdminSessionLost extends AdminUserState {
  final String message;
  final String? temporaryPassword;

  AdminSessionLost(this.message, {this.temporaryPassword});
}

class AdminPasswordReset extends AdminUserState {
  final String temporaryPassword;

  AdminPasswordReset({required this.temporaryPassword});
}

class resetPassSuccess extends AdminUserState {}

class resetPassError extends AdminUserState {}