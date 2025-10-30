import 'package:church/core/blocs/auth/auth_cubit.dart';
import 'package:church/core/models/user/user_model.dart';
import 'package:church/core/utils/userType_enum.dart';
import 'package:church/modules/Admin/admin_dashboard_screen.dart';
import 'package:church/modules/Auth/login/login_screen.dart';
import 'package:church/shared/widgets.dart';
import 'package:flutter/material.dart';
import '../../core/styles/colors.dart';
import '../Classes/manage_classes_screen.dart';

Widget drawer(BuildContext context, UserModel userData) => Drawer(
      width: MediaQuery.of(context).size.width * 0.75,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              teal900,
              teal700,
              teal500,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Background pattern overlay
            Positioned.fill(
              child: Opacity(
                opacity: 0.1,
                child: Image.asset(
                  'assets/images/bg.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Main content
            SafeArea(
              child: Column(
                children: [
                  // Modern Header Section
                  _buildModernHeader(context, userData),

                  const SizedBox(height: 20),

                  // Menu Items
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _buildMenuItem(
                          context: context,
                          icon: Icons.home_rounded,
                          title: 'الرئيسية',
                          subtitle: 'العودة للصفحة الرئيسية',
                          gradient: [teal300, teal500],
                          onTap: () => Navigator.pop(context),
                        ),

                        const SizedBox(height: 12),

                        _buildMenuItem(
                          context: context,
                          icon: Icons.person_rounded,
                          title: 'إدارة الأسر',
                          subtitle: 'عرض وتعديل البيانات',
                          gradient: [brown300, brown500],
                          onTap: () {
                            navigateTo(context, ManageClassesScreen());
                          },
                        ),

                        const SizedBox(height: 12),

                        _buildMenuItem(
                          context: context,
                          icon: Icons.settings_rounded,
                          title: 'الإعدادات',
                          subtitle: 'تخصيص التطبيق',
                          gradient: [sage500, brown500],
                          onTap: () {
                            Navigator.pop(context);
                            // TODO: Navigate to settings
                          },
                        ),

                        const SizedBox(height: 12),

                        _buildMenuItem(
                          context: context,
                          icon: Icons.notifications_rounded,
                          title: 'الإشعارات',
                          subtitle: 'إدارة الإشعارات',
                          gradient: [tawny, red500],
                          onTap: () {
                            Navigator.pop(context);
                            // TODO: Navigate to notifications
                          },
                        ),

                        const SizedBox(height: 12),

                        // Admin Dashboard - Only for priests
                        if (userData.userType == UserType.priest || userData.id == 'h2xPvUO88qVuVwFed9YDqV33E2A2')
                          _buildMenuItem(
                            context: context,
                            icon: Icons.admin_panel_settings_rounded,
                            title: 'لوحة التحكم',
                            subtitle: 'إدارة إعدادات المظهر',
                            gradient: [Colors.purple[400]!, Colors.purple[600]!],
                            onTap: () {
                              Navigator.pop(context);
                              navigateTo(context, const AdminDashboardScreen());
                            },
                          ),

                        if (userData.userType == UserType.priest)
                          const SizedBox(height: 12),

                        _buildMenuItem(
                          context: context,
                          icon: Icons.help_rounded,
                          title: 'المساعدة',
                          subtitle: 'الدعم والمساعدة',
                          gradient: [Colors.blue[400]!, Colors.blue[600]!],
                          onTap: () {
                            Navigator.pop(context);
                            // TODO: Navigate to help
                          },
                        ),

                        const SizedBox(height: 24),

                        // Divider
                        Container(
                          height: 1,
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0),
                                Colors.white.withValues(alpha: 0.3),
                                Colors.white.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Logout button
                        _buildLogoutButton(context),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),

                  // Footer
                  _buildFooter(),
                ],
              ),
            ),
          ],
        ),
      ),
    );

Widget _buildModernHeader(BuildContext context,  UserModel userData) {
  return Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.15),
          Colors.white.withValues(alpha: 0.05),
        ],
      ),
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(30),
        bottomRight: Radius.circular(30),
      ),
      border: Border(
        bottom: BorderSide(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Avatar
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [teal100, teal300],
                ),
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 35,
              ),
            ),

            const SizedBox(width: 16),

            // Welcome text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مرحباً بك',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.9),
                      fontFamily: 'Alexandria',
                    ),
                  ),
                  const SizedBox(height: 4),
                   Text(
                    userData.fullName,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Alexandria',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Status badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.green.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.greenAccent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'نشط الآن',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: 'Alexandria',
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildMenuItem({
  required BuildContext context,
  required IconData icon,
  required String title,
  required String subtitle,
  required List<Color> gradient,
  required VoidCallback onTap,
}) {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.1),
          Colors.white.withValues(alpha: 0.05),
        ],
      ),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.1),
        width: 1,
      ),
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
              // Icon container
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: gradient[0].withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),

              const SizedBox(width: 16),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Alexandria',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                        fontFamily: 'Alexandria',
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow icon
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white.withValues(alpha: 0.5),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    ));
}

Widget _buildLogoutButton(BuildContext context) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 4),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: LinearGradient(
        colors: [
          Colors.red[400]!,
          Colors.red[600]!,
        ],
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.red.withValues(alpha: 0.4),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: teal700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'تسجيل الخروج',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Alexandria',
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: const Text(
                'هل أنت متأكد من رغبتك في تسجيل الخروج؟',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Alexandria',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'إلغاء',
                    style: TextStyle(
                      color: teal100,
                      fontFamily: 'Alexandria',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    AuthCubit().logOut().then((value) {
                      navigateAndFinish(context, LoginScreen());
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'تسجيل الخروج',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Alexandria',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.logout_rounded,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'تسجيل الخروج',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
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

Widget _buildFooter() {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      border: Border(
        top: BorderSide(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
    ),
    child: Column(
      children: [
        Text(
          'تطبيق الكنيسة',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white.withValues(alpha: 0.9),
            fontFamily: 'Alexandria',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'الإصدار 1.0.0',
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.6),
            fontFamily: 'Alexandria',
          ),
        ),
      ],
    ),
  );
}
