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
        backgroundColor: brown100,
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
                child: const Text(
                  '💬',
                  style: TextStyle(fontSize: 18),
                ),
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
              colors: [
                brown300.withValues(alpha: 0.9),
                brown300.withValues(alpha: 0.7),
              ],
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
          colors: [
            teal100.withValues(alpha: 0.3),
            teal300.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: const Text('🙏', style: TextStyle(fontSize: 40)),
          ),
          const SizedBox(height: 16),
          const Text(
            'نحن هنا لمساعدتك',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: brown900,
              fontFamily: 'Alexandria',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'تواصل معنا في أي وقت وسنكون سعداء بخدمتك',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: brown700,
              fontFamily: 'Alexandria',
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(right: 8, bottom: 12),
          child: Text(
            'طرق التواصل',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: brown900,
              fontFamily: 'Alexandria',
            ),
          ),
        ),
        _buildContactCard(
          icon: Icons.phone_rounded,
          title: 'اتصل بنا',
          subtitle: '+20 123 456 7890',
          color: Colors.green,
          onTap: () => _makePhoneCall('+201234567890'),
        ),
        const SizedBox(height: 12),
        _buildContactCard(
          icon: Icons.email_rounded,
          title: 'راسلنا',
          subtitle: 'support@church.com',
          color: Colors.blue,
          onTap: () => _sendEmail('support@church.com'),
        ),
        const SizedBox(height: 12),
        _buildContactCard(
          icon: Icons.location_on_rounded,
          title: 'زرنا',
          subtitle: 'العنوان: شارع الكنيسة، القاهرة',
          color: Colors.red,
          onTap: () => _openMaps(),
        ),
      ],
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
                Icon(
                  Icons.arrow_back_ios,
                  color: brown300,
                  size: 16,
                ),
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
        const Padding(
          padding: EdgeInsets.only(right: 8, bottom: 12),
          child: Text(
            'تابعنا على',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: brown900,
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
                emoji: '📘',
                label: 'فيسبوك',
                color: const Color(0xFF1877F2),
                onTap: () => _openUrl('https://facebook.com'),
              ),
              _buildSocialIcon(
                emoji: '📷',
                label: 'انستجرام',
                color: const Color(0xFFE4405F),
                onTap: () => _openUrl('https://instagram.com'),
              ),
              _buildSocialIcon(
                emoji: '▶️',
                label: 'يوتيوب',
                color: const Color(0xFFFF0000),
                onTap: () => _openUrl('https://youtube.com'),
              ),
              _buildSocialIcon(
                emoji: '💬',
                label: 'واتساب',
                color: const Color(0xFF25D366),
                onTap: () => _openWhatsApp(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSocialIcon({
    required String emoji,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: brown700,
              fontFamily: 'Alexandria',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(right: 8, bottom: 12),
          child: Text(
            'إجراءات سريعة',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: brown900,
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

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=استفسار من تطبيق الكنيسة',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Future<void> _openMaps() async {
    final Uri mapsUri = Uri.parse('https://maps.google.com/');
    if (await canLaunchUrl(mapsUri)) {
      await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openWhatsApp() async {
    final Uri whatsappUri = Uri.parse('https://wa.me/201234567890');
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
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
                'س: كيف يمكنني تغيير كلمة المرور؟\nج: انتقل إلى الإعدادات ثم اختر تغيير كلمة المرور.',
                style: TextStyle(fontFamily: 'Alexandria'),
                textAlign: TextAlign.right,
              ),
              SizedBox(height: 16),
              Text(
                'س: كيف أضيف تذكير بعيد ميلاد؟\nج: اذهب إلى صفحة أعياد الميلاد واضغط على زر الإضافة.',
                style: TextStyle(fontFamily: 'Alexandria'),
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