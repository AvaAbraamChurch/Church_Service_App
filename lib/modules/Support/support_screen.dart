import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/styles/colors.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: teal50,
        body: CustomScrollView(
          slivers: [
            _buildModernAppBar(context),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildWelcomeCard(),
                    const SizedBox(height: 20),
                    _buildContactSection(),
                    const SizedBox(height: 20),
                    _buildSocialMediaSection(),
                    const SizedBox(height: 20),
                    _buildQuickActionsSection(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('💬', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 8),
              const Text(
                'الدعم والمساعدة',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Alexandria',
                ),
              ),
            ],
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.green[400]!, Colors.green[700]!],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.green[50]!, Colors.green[100]!],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green[200]!, width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[100],
              shape: BoxShape.circle,
            ),
            child: const Text('🙏', style: TextStyle(fontSize: 40)),
          ),
          const SizedBox(height: 16),
          Text(
            'نحن هنا لمساعدتك',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green[900],
              fontFamily: 'Alexandria',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'تواصل معنا في أي وقت وسنكون سعداء بخدمتك',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.green[700],
              fontFamily: 'Alexandria',
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Builder(
      builder: (context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(right: 8, bottom: 12),
              child: Text(
                'طرق التواصل',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[900],
                  fontFamily: 'Alexandria',
                ),
              ),
            ),
            _buildContactCard(
              icon: Icons.phone_rounded,
              title: 'اتصل بنا',
              subtitle: '01270464705',
              color: Colors.green,
              onTap: () => _openWhatsApp('01270464705'),
            ),
            const SizedBox(height: 12),
            _buildContactCard(
              icon: Icons.email_rounded,
              title: 'راسلنا',
              subtitle: 'andrewmichel2002@gmail.com',
              color: Colors.blue,
              onTap: () =>
                  _sendEmailWithContext('andrewmichel2002@gmail.com', context),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: brown900,
                          fontFamily: 'Alexandria',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: brown500,
                          fontFamily: 'Alexandria',
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_back_ios, color: brown300, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialMediaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(right: 8, bottom: 12),
          child: Text(
            'تابعنا على',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green[900],
              fontFamily: 'Alexandria',
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSocialIcon(
                icon: Icons.facebook_rounded,
                label: 'فيسبوك',
                color: const Color(0xFF1877F2),
                onTap: () => _openUrl('https://facebook.com'),
              ),
              // Add Instagram logo
              _buildSocialIcon(
                image: 'assets/images/instagram.png',
                label: 'انستجرام',
                color: const Color(0xFFE4405F),
                onTap: () => _openUrl('https://instagram.com'),
              ),
              // Add Youtube logo
              _buildSocialIcon(
                image: 'assets/images/youtube.png',
                label: 'يوتيوب',
                color: const Color(0xFFFF0000),
                onTap: () => _openUrl('https://youtu.be/h7FipiSG_p4'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSocialIcon({
    String? emoji,
    IconData? icon,
    String? image,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              if (emoji != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 28)),
                ),
              ] else if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
              ] else if (image != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.asset(image, width: 32, height: 32),
                ),
              ],

              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: brown700,
                  fontFamily: 'Alexandria',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(right: 8, bottom: 12),
          child: Text(
            'إجراءات سريعة',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green[900],
              fontFamily: 'Alexandria',
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.bug_report_rounded,
                title: 'إبلاغ عن مشكلة',
                color: Colors.orange,
                onTap: () => _showReportDialog(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.help_rounded,
                title: 'الأسئلة الشائعة',
                color: Colors.purple,
                onTap: () => _showFAQDialog(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: brown900,
                    fontFamily: 'Alexandria',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendEmailWithContext(String email, BuildContext context) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=${Uri.encodeComponent('استفسار من تطبيق الكنيسة')}',
    );

    try {
      final canLaunch = await canLaunchUrl(emailUri);
      if (canLaunch) {
        await launchUrl(emailUri);
      } else {
        // No email app available - show dialog with copy option
        _showNoEmailAppDialogWithContext(context, email);
      }
    } catch (e) {
      _showNoEmailAppDialogWithContext(context, email);
    }
  }

  void _showNoEmailAppDialogWithContext(BuildContext context, String email) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.email_outlined, color: Colors.blue[700]),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'لا يوجد تطبيق بريد إلكتروني',
                style: TextStyle(fontFamily: 'Alexandria', fontSize: 18),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'يمكنك نسخ البريد الإلكتروني واستخدامه في تطبيق آخر:',
              style: TextStyle(fontFamily: 'Alexandria'),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.email, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      email,
                      style: TextStyle(
                        fontFamily: 'Alexandria',
                        color: Colors.blue[900],
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'إلغاء',
              style: TextStyle(fontFamily: 'Alexandria'),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: email));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'تم نسخ البريد الإلكتروني',
                    style: TextStyle(fontFamily: 'Alexandria'),
                    textAlign: TextAlign.right,
                  ),
                  backgroundColor: Colors.green[600],
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text(
              'نسخ البريد',
              style: TextStyle(fontFamily: 'Alexandria'),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openWhatsApp(phoneNumber) async {
     phoneNumber = '2$phoneNumber';
    const message = 'مرحباً، أحتاج للمساعدة في برنامج أبناء الملك';

    // Try WhatsApp app scheme first
    final Uri whatsappAppUri = Uri.parse(
      'whatsapp://send?phone=$phoneNumber&text=${Uri.encodeComponent(message)}',
    );

    try {
      if (await canLaunchUrl(whatsappAppUri)) {
        await launchUrl(whatsappAppUri);
      } else {
        // Fallback to web WhatsApp if app is not installed
        final Uri whatsappWebUri = Uri.parse(
          'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}',
        );
        await launchUrl(whatsappWebUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // If all fails, try direct web URL
      final Uri whatsappWebUri = Uri.parse(
        'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}',
      );
      await launchUrl(whatsappWebUri, mode: LaunchMode.externalApplication);
    }
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'إبلاغ عن مشكلة',
          style: TextStyle(fontFamily: 'Alexandria'),
          textAlign: TextAlign.right,
        ),
        content: const Text(
          'يرجى التواصل معنا عبر البريد الإلكتروني أو الهاتف لإبلاغنا عن أي مشكلة.',
          style: TextStyle(fontFamily: 'Alexandria'),
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'حسناً',
              style: TextStyle(fontFamily: 'Alexandria'),
            ),
          ),
        ],
      ),
    );
  }

  void _showFAQDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'الأسئلة الشائعة',
          style: TextStyle(fontFamily: 'Alexandria'),
          textAlign: TextAlign.right,
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              Text(
                'س: كيف يمكنني الوصول إلى المتجر؟\nج: انتقل إلى صفحة الملف الشخصي واختر "كوبون" لتصفح المنتجات المتاحة.',
                style: TextStyle(fontFamily: 'Alexandria', color: Colors.grey),
                textAlign: TextAlign.right,
              ),
              SizedBox(height: 16),
              Text(
                'س: كيف أشارك في المسابقات؟\nج: اذهب إلى صفحة المسابقات واختر المسابقة المتاحة لك حسب فصلك الدراسي.',
                style: TextStyle(fontFamily: 'Alexandria', color: Colors.grey),
                textAlign: TextAlign.right,
              ),
              SizedBox(height: 16),
              Text(
                'س: كيف أتابع درجاتي ونقاطي؟\nج: يمكنك رؤية نقاطك من خلال صفحة الملف الشخصي.',
                style: TextStyle(fontFamily: 'Alexandria', color: Colors.grey),
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'إغلاق',
              style: TextStyle(fontFamily: 'Alexandria'),
            ),
          ),
        ],
      ),
    );
  }
}
