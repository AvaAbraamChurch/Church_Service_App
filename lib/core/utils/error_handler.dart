import 'package:firebase_auth/firebase_auth.dart';
import '../constants/strings.dart';

/// Utility class to convert Firebase Auth errors to user-friendly Arabic messages
class ErrorHandler {
  /// Convert Firebase Auth error to user-friendly Arabic message
  static String getAuthErrorMessage(dynamic error) {
    // If error is already a string, parse it
    String errorMessage = error.toString().toLowerCase();

    // Firebase Auth specific error codes
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return errorInvalidEmail;
        case 'user-not-found':
          return errorUserNotFound;
        case 'wrong-password':
          return errorWrongPassword;
        case 'user-disabled':
          return errorUserDisabled;
        case 'too-many-requests':
          return errorTooManyRequests;
        case 'operation-not-allowed':
          return errorOperationNotAllowed;
        case 'weak-password':
          return errorWeakPassword;
        case 'email-already-in-use':
          return errorEmailAlreadyInUse;
        case 'invalid-credential':
          return errorInvalidCredential;
        case 'account-exists-with-different-credential':
          return errorAccountExistsWithDifferentCredential;
        case 'requires-recent-login':
          return errorRequiresRecentLogin;
        case 'network-request-failed':
          return errorNetworkRequestFailed;
        default:
          return errorUnknownError;
      }
    }

    // Parse error message for common patterns
    if (errorMessage.contains('invalid-email') ||
        errorMessage.contains('badly formatted')) {
      return errorInvalidEmail;
    } else if (errorMessage.contains('user-not-found') ||
               errorMessage.contains('no user record')) {
      return errorUserNotFound;
    } else if (errorMessage.contains('wrong-password') ||
               errorMessage.contains('password is invalid')) {
      return errorWrongPassword;
    } else if (errorMessage.contains('user-disabled')) {
      return errorUserDisabled;
    } else if (errorMessage.contains('too-many-requests')) {
      return errorTooManyRequests;
    } else if (errorMessage.contains('network') ||
               errorMessage.contains('connection')) {
      return errorNetworkRequestFailed;
    } else if (errorMessage.contains('weak-password')) {
      return errorWeakPassword;
    } else if (errorMessage.contains('email-already-in-use')) {
      return errorEmailAlreadyInUse;
    } else if (errorMessage.contains('invalid-credential')) {
      return errorInvalidCredential;
    } else if (errorMessage.contains('timeout')) {
      return errorConnectionTimeout;
    } else if (errorMessage.contains('server') ||
               errorMessage.contains('internal')) {
      return errorServerError;
    }

    // If no specific error matched, return generic error
    return errorUnknownError;
  }

  /// Get user-friendly error message for general errors
  static String getGeneralErrorMessage(dynamic error) {
    String errorMessage = error.toString().toLowerCase();

    if (errorMessage.contains('network') ||
        errorMessage.contains('connection') ||
        errorMessage.contains('socket')) {
      return errorNetworkRequestFailed;
    } else if (errorMessage.contains('timeout')) {
      return errorConnectionTimeout;
    } else if (errorMessage.contains('permission') ||
               errorMessage.contains('denied')) {
      return errorOperationNotAllowed;
    } else if (errorMessage.contains('not found')) {
      return 'البيانات المطلوبة غير موجودة';
    }

    return errorUnknownError;
  }
}

