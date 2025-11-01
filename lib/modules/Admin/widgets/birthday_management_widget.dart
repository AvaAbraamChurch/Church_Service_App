import 'package:flutter/material.dart';
import 'package:church/core/services/birthday_notification_trigger_service.dart';
import 'package:church/core/services/birthday_notification_service.dart';
import 'package:church/core/models/user/user_model.dart';

/// Widget for managing birthday notifications in the admin dashboard
class BirthdayManagementWidget extends StatefulWidget {
  const BirthdayManagementWidget({super.key});

  @override
  State<BirthdayManagementWidget> createState() => _BirthdayManagementWidgetState();
}

class _BirthdayManagementWidgetState extends State<BirthdayManagementWidget> {
  final BirthdayNotificationTriggerService _triggerService = BirthdayNotificationTriggerService();
  final BirthdayNotificationService _birthdayService = BirthdayNotificationService();
  bool _isSending = false;

  Future<void> _sendBirthdayNotifications() async {
    setState(() {
      _isSending = true;
    });

    try {
      final result = await _triggerService.triggerBirthdayNotifications();

      if (!mounted) return;

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['count'] > 0
                  ? 'تم إرسال ${result['successCount']} إشعار بنجاح لـ ${result['count']} عيد ميلاد'
                  : 'لا توجد أعياد ميلاد اليوم',
            ),
            backgroundColor: result['count'] > 0 ? Colors.green : Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'فشل إرسال الإشعارات'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cake, color: Colors.amber, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'إدارة أعياد الميلاد',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'إرسال إشعارات لأعياد الميلاد اليوم',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Today's birthdays preview
            StreamBuilder<List<UserModel>>(
              stream: _birthdayService.getBirthdaysToday(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  final users = snapshot.data!;
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🎉 أعياد ميلاد اليوم (${users.length})',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...users.map((user) {
                          final age = _birthdayService.calculateAge(user.birthday!);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '• ${user.fullName} ($age سنة)',
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  );
                } else if (snapshot.hasData) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'لا توجد أعياد ميلاد اليوم',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSending ? null : _sendBirthdayNotifications,
                icon: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(_isSending ? 'جاري الإرسال...' : 'إرسال الإشعارات'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Info text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'يتم إرسال الإشعارات تلقائياً كل يوم الساعة 8 صباحاً',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

