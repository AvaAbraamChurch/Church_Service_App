import 'package:church/core/blocs/admin_user/admin_user_cubit.dart';
import 'package:church/core/blocs/admin_user/admin_user_states.dart';
import 'package:church/core/models/registration_request_model.dart';
import 'package:church/core/styles/colors.dart';
import 'package:church/core/styles/themeScaffold.dart';
import 'package:church/core/utils/userType_enum.dart';
import 'package:church/modules/Auth/login/login_screen.dart';
import 'package:church/modules/Splash/splash_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class RegistrationRequestsScreen extends StatefulWidget {
  const RegistrationRequestsScreen({super.key});

  @override
  State<RegistrationRequestsScreen> createState() => _RegistrationRequestsScreenState();
}

class _RegistrationRequestsScreenState extends State<RegistrationRequestsScreen> {
  String _filterStatus = 'pending'; // pending, all, approved, rejected

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  void _loadRequests() {
    if (_filterStatus == 'pending') {
      context.read<AdminUserCubit>().loadPendingRegistrationRequests();
    } else {
      context.read<AdminUserCubit>().loadAllRegistrationRequests();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ThemedScaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade800, Colors.orange.shade600, Colors.orange.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.shade800.withValues(alpha: 0.3),
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
                                Icons.pending_actions_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'طلبات التسجيل',
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
                          'مراجعة وقبول طلبات التسجيل',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                      onPressed: _loadRequests,
                      tooltip: 'تحديث',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter tabs
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildFilterChip('قيد الانتظار', 'pending', brown500),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildFilterChip('الكل', 'all', sage500),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildFilterChip('مقبولة', 'approved', teal500),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildFilterChip('مرفوضة', 'rejected', red500),
                ),
              ],
            ),
          ),
          // Requests list
          Expanded(
            child: BlocConsumer<AdminUserCubit, AdminUserState>(
              listener: (context, state) {
                if (state is AdminSessionLost) {
                  // Show dialog with the generated temporary password before logging out
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (dialogContext) => AlertDialog(
                      title: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green.shade600),
                          const SizedBox(width: 8),
                          const Text('تم قبول الطلب'),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'تم إنشاء الحساب بنجاح!',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          if (state.temporaryPassword != null) ...[
                            const Text('كلمة المرور المؤقتة:'),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () {
                                _copyToClipboard(state.temporaryPassword!, 'تم نسخ كلمة المرور');
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: teal50,
                                  border: Border.all(color: teal500, width: 2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: SelectableText(
                                        state.temporaryPassword!,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 2,
                                          color: teal900,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(Icons.copy, color: teal700, size: 20),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'اضغط على كلمة المرور لنسخها',
                              style: TextStyle(
                                fontSize: 11,
                                color: teal700,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                          ],
                          Text(
                            'يرجى نسخ كلمة المرور وإرسالها للمستخدم. سيُطلب منه تغييرها عند تسجيل الدخول الأول.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.shade300),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'ستحتاج إلى تسجيل الدخول مرة أخرى',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange.shade900,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(dialogContext);
                            // Sign out the current user (who got logged out when new user was created)
                            await FirebaseAuth.instance.signOut();
                            // Navigate back to splash screen (will handle authentication check)
                            if (context.mounted) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                                (route) => false,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: teal500,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('تسجيل الدخول'),
                        ),
                      ],
                    ),
                  );
                } else if (state is AdminRequestApproved) {
                  // Keep this for backwards compatibility if needed
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (dialogContext) => AlertDialog(
                      title: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green.shade600),
                          const SizedBox(width: 8),
                          const Text('تم قبول الطلب'),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'تم إنشاء الحساب بنجاح!',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          const Text('كلمة المرور المؤقتة:'),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () {
                              _copyToClipboard(state.temporaryPassword, 'تم نسخ كلمة المرور');
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: teal50,
                                border: Border.all(color: teal500, width: 2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: SelectableText(
                                      state.temporaryPassword,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2,
                                        color: teal900,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(Icons.copy, color: teal700, size: 20),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'اضغط على كلمة المرور لنسخها',
                            style: TextStyle(
                              fontSize: 11,
                              color: teal700,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'يرجى نسخ كلمة المرور وإرسالها للمستخدم. سيُطلب منه تغييرها عند تسجيل الدخول الأول.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            _loadRequests();
                          },
                          child: const Text('حسناً'),
                        ),
                      ],
                    ),
                  );
                } else if (state is AdminRequestRejected) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم رفض الطلب'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  _loadRequests();
                } else if (state is AdminUserError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is AdminUserLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is AdminUserError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'حدث خطأ',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (state is AdminRegistrationRequestsLoaded || state is AdminPendingRequestsLoaded) {
                  List<RegistrationRequest> requests = [];

                  if (state is AdminRegistrationRequestsLoaded) {
                    requests = state.requests;
                  } else if (state is AdminPendingRequestsLoaded) {
                    requests = state.requests;
                  }

                  // Filter based on selected status
                  if (_filterStatus != 'all' && _filterStatus != 'pending') {
                    requests = requests.where((r) => r.status.name == _filterStatus).toList();
                  }

                  if (requests.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد طلبات',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      return _buildRequestCard(requests[index]);
                    },
                  );
                }

                return const Center(child: Text('لا توجد بيانات'));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, Color color) {
    final isSelected = _filterStatus == value;
    return InkWell(
      onTap: () {
        setState(() {
          _filterStatus = value;
        });
        _loadRequests();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(RegistrationRequest request) {
    final statusColor = request.status == RegistrationStatus.pending
        ? brown500
        : request.status == RegistrationStatus.approved
            ? teal500
            : red500;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withValues(alpha: 0.3), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.fullName,
                    style: const TextStyle(
                      color: teal900,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusLabel(request.status),
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // User details
            _buildInfoRow(Icons.email_outlined, request.email),
            if (request.phoneNumber != null)
              _buildCopyableInfoRow(Icons.phone_outlined, request.phoneNumber!),
            _buildInfoRow(Icons.person_outline, request.userType.label),
            _buildInfoRow(Icons.class_outlined, request.userClass),
            _buildInfoRow(Icons.calendar_today_outlined,
              DateFormat('dd/MM/yyyy HH:mm').format(request.requestedAt)),

            if (request.rejectionReason != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: red300.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: red300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: red700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'سبب الرفض: ${request.rejectionReason}',
                        style: TextStyle(
                          fontSize: 12,
                          color: red700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Action buttons (only for pending requests)
            if (request.status == RegistrationStatus.pending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showApproveDialog(request),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('قبول'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: teal500,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showRejectDialog(request),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('رفض'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: red500,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyableInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          InkWell(
            onTap: () {
              _copyToClipboard(text, 'تم نسخ رقم الهاتف');
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: teal500.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(Icons.copy, size: 16, color: teal700),
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _getStatusLabel(RegistrationStatus status) {
    switch (status) {
      case RegistrationStatus.pending:
        return 'قيد الانتظار';
      case RegistrationStatus.approved:
        return 'مقبول';
      case RegistrationStatus.rejected:
        return 'مرفوض';
    }
  }

  void _showApproveDialog(RegistrationRequest request) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('قبول طلب التسجيل'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('هل أنت متأكد من قبول طلب ${request.fullName}؟'),
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
                  Icon(Icons.info_outline, color: teal700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'سيتم إنشاء كلمة مرور مؤقتة تلقائياً',
                      style: TextStyle(
                        fontSize: 13,
                        color: teal900,
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
            onPressed: () {
              Navigator.pop(dialogContext);
              final adminId = FirebaseAuth.instance.currentUser?.uid ?? '';
              context.read<AdminUserCubit>().approveRegistrationRequest(
                    request.id,
                    adminId,
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: teal500,
              foregroundColor: Colors.white,
            ),
            child: const Text('قبول'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(RegistrationRequest request) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('رفض طلب التسجيل'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('هل أنت متأكد من رفض طلب ${request.fullName}؟'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'سبب الرفض',
                hintText: 'أدخل سبب رفض الطلب',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('يرجى إدخال سبب الرفض'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(dialogContext);
              final adminId = FirebaseAuth.instance.currentUser?.uid ?? '';
              context.read<AdminUserCubit>().rejectRegistrationRequest(
                    request.id,
                    adminId,
                    reasonController.text,
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: red500,
              foregroundColor: Colors.white,
            ),
            child: const Text('رفض'),
          ),
        ],
      ),
    );
  }
}

