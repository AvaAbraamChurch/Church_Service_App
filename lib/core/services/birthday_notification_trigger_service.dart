import 'package:cloud_functions/cloud_functions.dart';

class BirthdayNotificationTriggerService {
  final FirebaseFunctions _functions;

  BirthdayNotificationTriggerService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  /// Manually trigger birthday notifications
  /// This calls the Cloud Function to check for birthdays today
  /// and send push notifications to all servants and priests
  Future<Map<String, dynamic>> triggerBirthdayNotifications() async {
    try {
      final callable = _functions.httpsCallable('sendBirthdayNotifications');
      final result = await callable.call();

      return {
        'success': result.data['success'] ?? false,
        'message': result.data['message'] ?? '',
        'count': result.data['count'] ?? 0,
        'successCount': result.data['successCount'] ?? 0,
        'failureCount': result.data['failureCount'] ?? 0,
        'users': result.data['users'] ?? [],
      };
    } catch (e) {
      print('Error triggering birthday notifications: $e');
      return {
        'success': false,
        'message': 'فشل إرسال الإشعارات: ${e.toString()}',
        'count': 0,
      };
    }
  }

  /// Check if there are any birthdays today without sending notifications
  Future<bool> hasBirthdaysToday() async {
    try {
      final result = await triggerBirthdayNotifications();
      return (result['count'] as int) > 0;
    } catch (e) {
      print('Error checking birthdays: $e');
      return false;
    }
  }
}

