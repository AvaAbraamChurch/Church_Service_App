import 'package:church/core/models/user/user_model.dart';
import 'package:church/core/repositories/users_reopsitory.dart';
import 'package:church/core/utils/userType_enum.dart';
import 'package:church/core/utils/gender_enum.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/widgets.dart';
import '../../constants/strings.dart';
import '../../repositories/auth_repository.dart';
import 'auth_states.dart';

class AuthCubit extends Cubit<AuthState> {

  final AuthRepository _authRepository;

  static AuthCubit get(BuildContext context) => BlocProvider.of<AuthCubit>(context);

  AuthCubit({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository(),
        super(AuthInitial());

  Future<void> logIn(String email, String password) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.signInWithEmailAndPassword(email, password);
      if (user == null) {
        emit(AuthFailure(loginFailed));
      } else {
        final UserModel model = await UsersRepository().getUserById(user.uid);
        emit(AuthSuccess(user.uid, model.userType.label, model.userClass, model.gender.label));
      }
    } catch (error) {
      emit(AuthFailure(error.toString()));
    }
  }

  Future<void> logOut() async {
    try {
      await _authRepository.signOut();
    } catch (_) {
      // ignore errors on sign out, we'll still emit logged out
    }
    emit(AuthLoggedOut());
  }

  // Forget password
  Future<void> sendPasswordResetEmail(String email) async {
    emit(AuthLoading());
    try {
      await _authRepository.sendPasswordResetEmail(email);
      emit(AuthPasswordResetEmailSent()); // or a specific state indicating email sent
    } catch (error) {
      emit(AuthFailure(error.toString()));
    }
  }

  Future<void> loadUserData() async {
    emit(AuthUserDataLoading());
    try {
      final userDataSnapshot = await _authRepository.getUserData();
      if (userDataSnapshot == null || !userDataSnapshot.exists) {
        emit(AuthUserDataError('User data not found'));
      } else {
        emit(AuthUserDataLoaded(userDataSnapshot.data()!));
      }
    } catch (error) {
      emit(AuthUserDataError(error.toString()));
    }
  }

  // Sign up method
  Future<void> signUp(String email, String password, {Map<String, dynamic>? extraData}) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.signUpWithEmailAndPassword(email, password, extraData: extraData);
      if (user == null) {
        emit(AuthFailure(registrationFailed));
      } else {
        // Parse gender and userType from strings to enums
        final genderValue = parseGender(extraData?['gender']?.toString());
        final userTypeValue = parseUserType(extraData?['userType']?.toString());

        UserModel userData = UserModel(
          id: user.uid,
          email: email,
          username: extraData?['username'] ?? '',
          fullName: extraData?['fullName'] ?? '',
          phoneNumber: extraData?['phone'] ?? '',
          address: extraData?['address'] ?? '',
          gender: genderValue,
          userType: userTypeValue,
          userClass: extraData?['userClass'] ?? '',
        );
        emit(AuthSuccess(user.uid, userData.userType.label, userData.userClass, userData.gender.label));
      }
    } catch (error) {
      emit(AuthFailure(error.toString()));
      print(error);
    }
  }

}