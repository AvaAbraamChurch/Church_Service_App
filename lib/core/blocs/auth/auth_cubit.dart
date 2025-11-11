import 'package:church/core/models/user/user_model.dart';
import 'package:church/core/repositories/users_reopsitory.dart';
import 'package:church/core/utils/error_handler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/widgets.dart';
import 'dart:io';
import '../../constants/strings.dart';
import '../../repositories/auth_repository.dart';
import '../../services/image_upload_service.dart';
import 'auth_states.dart';

class AuthCubit extends Cubit<AuthState> {

  final AuthRepository _authRepository;
  final ImageUploadService _imageUploadService;

  static AuthCubit get(BuildContext context) => BlocProvider.of<AuthCubit>(context);

  AuthCubit({AuthRepository? authRepository, ImageUploadService? imageUploadService})
      : _authRepository = authRepository ?? AuthRepository(),
        _imageUploadService = imageUploadService ?? ImageUploadService(),
        super(AuthInitial());

  Future<void> logIn(String email, String password) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.signInWithEmailAndPassword(email, password);
      if (user == null) {
        emit(AuthFailure(loginFailed));
      } else {
        final UserModel model = await UsersRepository().getUserById(user.uid);
        emit(AuthSuccess(model, user.uid, model.userType, model.userClass, model.gender, model.firstLogin));
      }
    } catch (error) {
      final friendlyError = ErrorHandler.getAuthErrorMessage(error);
      emit(AuthFailure(friendlyError));
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
      final friendlyError = ErrorHandler.getAuthErrorMessage(error);
      emit(AuthFailure(friendlyError));
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

  // Sign up method - creates registration request instead of direct user creation
  Future<void> signUp(String email, String password, {Map<String, dynamic>? extraData, File? profileImage}) async {
    emit(AuthLoading());
    try {
      // Upload profile image to storage first
      String? profileImageUrl;
      if (profileImage != null) {
        try {
          // Use email as identifier since user doesn't exist yet
          final tempId = email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
          profileImageUrl = await _imageUploadService.uploadProfileImage(profileImage, tempId);
        } catch (e) {
          print('خطأ في رفع الصورة: $e');
          emit(AuthFailure('فشل رفع الصورة. الرجاء المحاولة مرة أخرى.'));
          return;
        }
      }

      // Create registration request data
      final requestData = {
        'fullName': extraData?['fullName'] ?? '',
        'username': extraData?['username'] ?? '',
        'email': email,
        'phoneNumber': extraData?['phoneNumber'] ?? '',
        'address': extraData?['address'] ?? '',
        'gender': extraData?['gender'] ?? '',
        'userType': extraData?['userType'] ?? '',
        'class': extraData?['userClass'] ?? '',
        'serviceType': extraData?['serviceType'] ?? '',
        if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
        'requestedAt': DateTime.now().toIso8601String(),
        'status': 'pending',
      };

      // Create registration request in Firestore
      final requestId = await _authRepository.createRegistrationRequest(requestData);

      // Emit success state with request ID
      emit(AuthRegistrationRequestSubmitted(requestId, email));

    } catch (error) {
      final friendlyError = ErrorHandler.getAuthErrorMessage(error);
      emit(AuthFailure(friendlyError));
      print(error);
    }
  }

  // Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    emit(AuthLoading());
    try {
      await _authRepository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      emit(AuthPasswordChanged());
    } catch (error) {
      final friendlyError = ErrorHandler.getAuthErrorMessage(error);
      emit(AuthFailure(friendlyError));
    }
  }

}