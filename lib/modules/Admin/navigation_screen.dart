import 'package:church/core/styles/themeScaffold.dart';
import 'package:church/core/styles/colors.dart';
import 'package:flutter/material.dart';
import 'package:church/modules/Admin/main_dashboard.dart';
import 'package:church/modules/Admin/admin_dashboard_screen.dart';
import 'package:church/modules/Admin/user_management/manage_user_classes_screen.dart';
import 'package:church/modules/Admin/user_management/manage_class_mappings_screen.dart';
import 'package:church/modules/Admin/attendance_defaults_page.dart';

class NavigationScreen extends StatelessWidget {
  const NavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ThemedScaffold(
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
                  // Back button
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  // Title and subtitle
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
                                Icons.dashboard_customize_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'لوحة التحكم',
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
                          'إدارة إعدادات التطبيق',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Placeholder to balance layout
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                const Text(
                  'لوحة التحكم الإدارية',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'اختر لوحة تحكم للإدارة',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 60),

                // Main Dashboard Button
                _buildModernButton(
                  context,
                  title: 'لوحة التحكم الرئيسية',
                  subtitle: 'عرض النظرة العامة والإحصائيات',
                  icon: Icons.dashboard_rounded,
                  gradientColors: [Colors.blue.shade400, Colors.blue.shade600],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MainDashboard(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Theme Dashboard Button
                _buildModernButton(
                  context,
                  title: 'لوحة تحكم المظهر',
                  subtitle: 'تخصيص مظهر التطبيق',
                  icon: Icons.palette_rounded,
                  gradientColors: [Colors.purple.shade400, Colors.purple.shade600],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminDashboardScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // User Classes Management Button
                _buildModernButton(
                  context,
                  title: 'إدارة صفوف المستخدمين',
                  subtitle: 'تعيين المستخدمين للصفوف الدراسية',
                  icon: Icons.school_rounded,
                  gradientColors: [Colors.green.shade400, Colors.green.shade600],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ManageUserClassesScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Class Mappings Configuration Button
                _buildModernButton(
                  context,
                  title: 'إدارة تعيينات الصفوف',
                  subtitle: 'إضافة وتعديل أسماء الصفوف (مثال: اسرة القديس استفانوس)',
                  icon: Icons.settings_applications_rounded,
                  gradientColors: [Colors.orange.shade400, Colors.orange.shade600],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ManageClassMappingsScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Attendance Defaults Button
                _buildModernButton(
                  context,
                  title: 'النقاط الافتراضية للحضور',
                  subtitle: 'تعيين قيم النقاط لأنواع الحضور المختلفة',
                  icon: Icons.stars_rounded,
                  gradientColors: [Colors.teal.shade400, Colors.teal.shade600],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AttendanceDefaultsPage(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 400),
      child: Material(
        elevation: 8,
        shadowColor: gradientColors[1].withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      icon,
                      size: 36,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

