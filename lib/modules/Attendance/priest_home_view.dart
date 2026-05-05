import 'package:church/core/blocs/attendance/attendance_cubit.dart';
import 'package:church/core/styles/colors.dart';
import 'package:church/core/utils/userType_enum.dart';
import 'package:church/modules/Attendance/priest_view.dart';
import 'package:flutter/material.dart';

class PriestHomeView extends StatelessWidget {
  final AttendanceCubit cubit;
  final UserType userType;

  const PriestHomeView({
    super.key,
    required this.cubit,
    required this.userType,
  });

  static const List<_AttendanceTypeDef> _types = [
    _AttendanceTypeDef(
      key: 'holy_mass',
      label: 'القداس',
      subtitle: 'تسجيل حضور القداس الإلهي',
      icon: Icons.church_rounded,
      gradient: [Color(0xFF0D9488), Color(0xFF0F766E)],
      pageIndex: 0,
    ),
    _AttendanceTypeDef(
      key: 'sunday_school',
      label: 'مدارس الأحد',
      subtitle: 'تسجيل حضور مدارس الأحد',
      icon: Icons.auto_stories_rounded,
      gradient: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
      pageIndex: 1,
    ),
    _AttendanceTypeDef(
      key: 'hymns',
      label: 'الألحان',
      subtitle: 'تسجيل حضور فصل الألحان',
      icon: Icons.music_note_rounded,
      gradient: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
      pageIndex: 2,
    ),
    _AttendanceTypeDef(
      key: 'bible',
      label: 'درس الكتاب',
      subtitle: 'تسجيل حضور درس الكتاب المقدس',
      icon: Icons.menu_book_rounded,
      gradient: [Color(0xFFF59E0B), Color(0xFFD97706)],
      pageIndex: 3,
    ),
    _AttendanceTypeDef(
      key: 'visit',
      label: 'الافتقاد',
      subtitle: 'تسجيل زيارات الافتقاد',
      icon: Icons.home_rounded,
      gradient: [Color(0xFF10B981), Color(0xFF059669)],
      pageIndex: 4,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        // Greeting banner
        _GreetingBanner(cubit: cubit),
        const SizedBox(height: 24),

        // Section label
        Padding(
          padding: const EdgeInsets.only(bottom: 14, right: 4),
          child: Text(
            'أنواع الحضور',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: teal900,
              fontFamily: 'Alexandria',
              letterSpacing: 0.3,
            ),
          ),
        ),

        // Attendance type cards
        ..._types.map(
          (t) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _AttendanceCard(
              type: t,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PriestView(cubit, pageIndex: t.pageIndex),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Data class & Shared UI (mirrors servant_home_view.dart)
// ════════════════════════════════════════════════════════════════════════════
class _AttendanceTypeDef {
  final String key, label, subtitle;
  final IconData icon;
  final List<Color> gradient;
  final int pageIndex;

  const _AttendanceTypeDef({
    required this.key,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.pageIndex,
  });
}

class _GreetingBanner extends StatelessWidget {
  final AttendanceCubit cubit;

  const _GreetingBanner({required this.cubit});

  @override
  Widget build(BuildContext context) {
    final name = cubit.currentUser?.fullName ?? 'الأب الكاهن';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [teal600, teal800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: teal700.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'أهلاً، $name 👋',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Alexandria',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'اختر نوع الحضور لتسجيله',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.8),
                    fontFamily: 'Alexandria',
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.how_to_reg_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  final _AttendanceTypeDef type;
  final VoidCallback onTap;

  const _AttendanceCard({required this.type, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: type.gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: type.gradient[0].withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(type.icon, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type.label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Alexandria',
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        type.subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontFamily: 'Alexandria',
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: type.gradient[0].withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: type.gradient[0],
                    size: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
