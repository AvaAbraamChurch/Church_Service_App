import 'package:church/core/models/user/user_model.dart';
import 'package:church/core/utils/gender_enum.dart';
import 'package:church/core/utils/userType_enum.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final UserModel user;
  final String uId;
  final UserType userType;
  final String userClass;
  final Gender gender;
  final bool isFirstLogin;


  AuthSuccess(this.user,this.uId, this.userType, this.userClass, this.gender, this.isFirstLogin);
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

class AuthPasswordChanged extends AuthState {}

class AuthRegistrationRequestSubmitted extends AuthState {
  final String requestId;
  final String email;

  AuthRegistrationRequestSubmitted(this.requestId, this.email);
}


