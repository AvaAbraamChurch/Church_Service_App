abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final String uId;
  final String userType;
  final String userClass;
  final String gender;


  AuthSuccess(this.uId, this.userType, this.userClass, this.gender);
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