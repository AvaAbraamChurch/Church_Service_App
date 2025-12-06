import 'package:church/core/models/user/user_model.dart';
import 'package:church/core/styles/colors.dart';
import 'package:church/core/styles/themeScaffold.dart';
import 'package:church/core/utils/service_enum.dart';
import 'package:church/core/utils/userType_enum.dart';
import 'package:church/core/utils/gender_enum.dart';
import 'package:church/core/blocs/admin_user/admin_user_cubit.dart';
import 'package:church/core/blocs/admin_user/admin_user_states.dart';
import 'package:church/modules/Admin/user_management/edit_user_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserDetailScreen extends StatelessWidget {
  final UserModel user;

  const UserDetailScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdminUserCubit, AdminUserState>(
      listener: (context, state) {
        if (state is AdminPasswordReset) {
          // Show dialog with the temporary password
          _showPasswordResetSuccessDialog(context, state.temporaryPassword);
        } else if (state is AdminUserError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: ThemedScaffold(
        appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [teal900, teal700, teal500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: teal900.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'تفاصيل المستخدم',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'عرض وتعديل بيانات المستخدم',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Image
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundColor: teal300,
                backgroundImage: user.profileImageUrl != null
                    ? NetworkImage(user.profileImageUrl!)
                    : null,
                child: user.profileImageUrl == null
                    ? Text(
                        user.fullName
                            .split(' ')
                            .map((e) => e[0])
                            .take(2)
                            .join(),
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.fullName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: teal900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              user.email,
              style: const TextStyle(fontSize: 16, color: sage700),
            ),
            const SizedBox(height: 24),
            // User Information Cards
            _buildInfoCard('المعلومات الشخصية', Icons.person_outline, [
              _buildInfoRow('الاسم الكامل', user.fullName),
              _buildInfoRow('اسم المستخدم', user.username),
              _buildInfoRow('البريد الإلكتروني', user.email),
              if (user.phoneNumber != null)
                _buildInfoRow('رقم الهاتف', user.phoneNumber!),
              if (user.address != null) _buildInfoRow('العنوان', user.address!),
            ]),
            const SizedBox(height: 16),
            _buildInfoCard('معلومات الخدمة', Icons.church_outlined, [
              _buildInfoRow('نوع المستخدم', user.userType.label),
              _buildInfoRow('الفصل', user.userClass),
              _buildInfoRow('نوع الخدمة', user.serviceType.displayName),
              _buildInfoRow('الجنس', user.gender.label),
            ]),
            const SizedBox(height: 16),
            _buildInfoCard('معلومات أخرى', Icons.info_outline, [
              _buildInfoRow('نقاط الكوبون', user.couponPoints.toString()),
              _buildInfoRow('أول تسجيل دخول', user.firstLogin ? 'نعم' : 'لا'),
              if (user.birthday != null)
                _buildInfoRow(
                  'تاريخ الميلاد',
                  '${user.birthday!.day}/${user.birthday!.month}/${user.birthday!.year}',
                ),
            ]),
            const SizedBox(height: 16),
            _buildInfoCard('الصلاحيات', Icons.admin_panel_settings_outlined, [
              _buildInfoRow('مسؤول النظام', user.isAdmin ? 'نعم' : 'لا'),
              _buildInfoRow('مسؤول المتجر', user.storeAdmin ? 'نعم' : 'لا'),
              _buildInfoRow('حالة الحساب', user.isActive ? 'نشط' : 'معطل'),
            ]),
            const SizedBox(height: 24),
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditUserScreen(user: user),
                        ),
                      );

                      // If edit was successful, go back to refresh the list
                      if (result == true && context.mounted) {
                        Navigator.pop(context, true);
                      }
                    },
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('تعديل'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: teal500,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showDisableEnableConfirmation(context);
                    },
                    icon: Icon(
                      user.isActive
                          ? Icons.block_rounded
                          : Icons.check_circle_rounded,
                    ),
                    label: Text(user.isActive ? 'تعطيل' : 'تفعيل'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: user.isActive ? brown500 : Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _showDeleteConfirmation(context);
                },
                icon: const Icon(Icons.delete_rounded),
                label: const Text('حذف الحساب نهائياً'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: red500,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            // Show "Get Temporary Password" button if firstLogin is true
            if (user.firstLogin) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showGeneratePasswordDialog(context);
                  },
                  icon: const Icon(Icons.vpn_key_rounded),
                  label: const Text('إنشاء كلمة مرور مؤقتة جديدة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brown500,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildInfoCard(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: teal700),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: teal900,
                  ),
                ),
              ],
            ),
            const Divider(height: 24, color: sage300),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: sage600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: teal900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'تأكيد الحذف',
          style: TextStyle(color: red500, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('هل أنت متأكد من حذف المستخدم ${user.fullName}؟'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: red500.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: red500.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_rounded, color: red500, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'هذا الإجراء لا يمكن التراجع عنه!',
                      style: TextStyle(
                        color: red500,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) =>
                    const Center(child: CircularProgressIndicator()),
              );

              try {
                final cubit = context.read<AdminUserCubit>();
                await cubit.deleteUser(user.id);

                if (context.mounted) {
                  Navigator.pop(context); // Close loading
                  Navigator.pop(context, true); // Go back with success

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم حذف المستخدم ${user.fullName} بنجاح'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context); // Close loading

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('فشل حذف المستخدم: ${e.toString()}'),
                      backgroundColor: red500,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: red500,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف نهائياً'),
          ),
        ],
      ),
    );
  }

  void _showDisableEnableConfirmation(BuildContext context) {
    final isCurrentlyActive = user.isActive;
    final action = isCurrentlyActive ? 'تعطيل' : 'تفعيل';
    final actionPast = isCurrentlyActive ? 'تعطيل' : 'تفعيل';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'تأكيد $action الحساب',
          style: TextStyle(
            color: isCurrentlyActive ? brown500 : Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('هل أنت متأكد من $action حساب ${user.fullName}؟'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isCurrentlyActive ? brown500 : Colors.green)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: (isCurrentlyActive ? brown500 : Colors.green)
                      .withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isCurrentlyActive
                        ? Icons.block_rounded
                        : Icons.check_circle_rounded,
                    color: isCurrentlyActive ? brown500 : Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isCurrentlyActive
                          ? 'لن يتمكن المستخدم من تسجيل الدخول'
                          : 'سيتمكن المستخدم من تسجيل الدخول',
                      style: TextStyle(
                        color: isCurrentlyActive ? brown500 : Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) =>
                    const Center(child: CircularProgressIndicator()),
              );

              try {
                final cubit = context.read<AdminUserCubit>();
                await cubit.toggleUserStatus(user.id, !isCurrentlyActive);

                if (context.mounted) {
                  Navigator.pop(context); // Close loading
                  Navigator.pop(context, true); // Go back with success

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'تم $actionPast حساب ${user.fullName} بنجاح',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context); // Close loading

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('فشل $action الحساب: ${e.toString()}'),
                      backgroundColor: red500,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isCurrentlyActive ? brown500 : Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(action),
          ),
        ],
      ),
    );
  }

  void _showGeneratePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.vpn_key_rounded, color: brown500),
            const SizedBox(width: 8),
            const Text('إعادة تعيين كلمة المرور'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('هل تريد إرسال بريد إعادة تعيين كلمة المرور إلى ${user.fullName}؟'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: teal50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: teal500.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.email_outlined, color: teal700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'البريد الإلكتروني:\n${user.email}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: teal900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: brown500.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: brown500.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: brown700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'سيتلقى المستخدم رابطاً لإعادة تعيين كلمة المرور. سيكون الرابط صالحاً لمدة ساعة واحدة.',
                      style: TextStyle(
                        fontSize: 11,
                        color: brown700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              try {
                final cubit = context.read<AdminUserCubit>();
                await cubit.resetUserPassword(user.id);

                if (context.mounted) {
                  Navigator.pop(context); // Close loading
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context); // Close loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('فشل إرسال البريد: ${e.toString()}'),
                      backgroundColor: red500,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: brown500,
              foregroundColor: Colors.white,
            ),
            child: const Text('إرسال البريد'),
          ),
        ],
      ),
    );
  }

  void _showPasswordResetSuccessDialog(BuildContext context, String temporaryPassword) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 12),
            const Text(
              'تم إعادة التعيين',
              style: TextStyle(color: teal900),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'تم إرسال بريد إعادة تعيين كلمة المرور إلى ${user.email}',
              style: const TextStyle(color: sage700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'كلمة المرور المؤقتة (للطوارئ):',
              style: TextStyle(
                color: brown700,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: teal50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: teal500, width: 2),
              ),
              child: SelectableText(
                temporaryPassword,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: teal900,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: temporaryPassword));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم نسخ كلمة المرور'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.copy),
              label: const Text('نسخ كلمة المرور'),
              style: ElevatedButton.styleFrom(
                backgroundColor: teal500,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: brown100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: brown500.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: brown700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'ملاحظات مهمة:',
                          style: TextStyle(
                            fontSize: 12,
                            color: brown900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• سيتلقى المستخدم رابط إعادة التعيين عبر البريد الإلكتروني\n'
                    '• الرابط صالح لمدة ساعة واحدة\n'
                    '• كلمة المرور المؤقتة أعلاه للطوارئ فقط\n'
                    '• سيُطلب من المستخدم تغيير كلمة المرور عند أول تسجيل دخول',
                    style: TextStyle(
                      fontSize: 11,
                      color: brown900,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }
}
