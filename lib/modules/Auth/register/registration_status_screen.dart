import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/registration_request_model.dart';
import '../../../core/styles/colors.dart';
import '../../../core/styles/themeScaffold.dart';
import '../../../core/constants/strings.dart';
import '../login/login_screen.dart';

class RegistrationStatusScreen extends StatelessWidget {
  final String requestId;
  final String email;

  const RegistrationStatusScreen({
    super.key,
    required this.requestId,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return ThemedScaffold(
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('registration_requests')
              .doc(requestId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: teal500),
                    const SizedBox(height: 24),
                    Text(
                      loadingData,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontFamily: 'Alexandria',
                      ),
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return _buildErrorState(context);
            }

            final request = RegistrationRequest.fromMap(
              snapshot.data!.data() as Map<String, dynamic>,
              id: requestId,
            );

            return _buildStatusContent(context, request);
          },
        ),
      ),
    );
  }

  Widget _buildStatusContent(BuildContext context, RegistrationRequest request) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Status Icon
          _buildStatusIcon(request.status),
          const SizedBox(height: 32),

          // Status Title
          Text(
            _getStatusTitle(request.status),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Alexandria',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Status Description
          Text(
            _getStatusDescription(request.status),
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.9),
              fontFamily: 'Alexandria',
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Request Details Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(Icons.person, fullName, request.fullName),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.email, email, request.email),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.access_time, 'تاريخ الطلب', _formatDate(request.requestedAt)),
                if (request.status == RegistrationStatus.rejected && request.rejectionReason != null) ...[
                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.info_outline, 'سبب الرفض', request.rejectionReason!),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Action Button
          _buildActionButton(context, request.status),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(RegistrationStatus status) {
    IconData icon;
    Color color;

    switch (status) {
      case RegistrationStatus.pending:
        icon = Icons.hourglass_empty;
        color = Colors.orange;
        break;
      case RegistrationStatus.approved:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case RegistrationStatus.rejected:
        icon = Icons.cancel;
        color = Colors.red;
        break;
    }

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 3),
      ),
      child: Icon(
        icon,
        size: 60,
        color: color,
      ),
    );
  }

  String _getStatusTitle(RegistrationStatus status) {
    switch (status) {
      case RegistrationStatus.pending:
        return 'طلبك قيد المراجعة';
      case RegistrationStatus.approved:
        return 'تم قبول طلبك!';
      case RegistrationStatus.rejected:
        return 'عذراً، تم رفض الطلب';
    }
  }

  String _getStatusDescription(RegistrationStatus status) {
    switch (status) {
      case RegistrationStatus.pending:
        return 'تم استلام طلب التسجيل الخاص بك. سيقوم المسؤول بمراجعته قريباً.\nسنقوم بإشعارك عند اتخاذ قرار بشأن طلبك.';
      case RegistrationStatus.approved:
        return 'مبروك! تم قبول طلب التسجيل الخاص بك.\nستتلقى كلمة مرور مؤقتة عبر البريد الإلكتروني لتسجيل الدخول.';
      case RegistrationStatus.rejected:
        return 'للأسف، تم رفض طلب التسجيل الخاص بك.\nيمكنك التواصل مع الدعم لمزيد من المعلومات.';
    }
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: teal300),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.7),
                  fontFamily: 'Alexandria',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontFamily: 'Alexandria',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, RegistrationStatus status) {
    String buttonText;
    VoidCallback onPressed;
    Color buttonColor;

    switch (status) {
      case RegistrationStatus.pending:
        buttonText = 'حسناً';
        buttonColor = teal500;
        onPressed = () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LoginScreen()),
        );
        break;
      case RegistrationStatus.approved:
        buttonText = 'تسجيل الدخول';
        buttonColor = Colors.green;
        onPressed = () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LoginScreen()),
        );
        break;
      case RegistrationStatus.rejected:
        buttonText = 'العودة للتسجيل';
        buttonColor = Colors.red;
        onPressed = () => Navigator.pop(context);
        break;
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Alexandria',
          ),
        ),
        child: Text(buttonText),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 24),
            Text(
              'خطأ في تحميل حالة الطلب',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Alexandria',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'لم نتمكن من العثور على طلب التسجيل الخاص بك.\nيرجى المحاولة مرة أخرى أو الاتصال بالدعم.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.9),
                fontFamily: 'Alexandria',
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: teal500,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'العودة لتسجيل الدخول',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Alexandria',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'يناير', 'فبراير', 'مارس', 'إبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

