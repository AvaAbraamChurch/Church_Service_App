abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final String uId;

  AuthSuccess(this.uId);
}

class AuthFailure extends AuthState {
  final String error;

  AuthFailure(this.error);
}

class AuthLoggedOut extends AuthState {}

class AuthUserDataLoaded extends AuthState {
  final Map<String, dynamic> userData;

  AuthUserDataLoaded(this.userData);
}

class AuthUserDataLoading extends AuthState {}

class AuthUserDataError extends AuthState {
  final String error;

  AuthUserDataError(this.error);
}

class AuthPasswordResetEmailSent extends AuthState {}