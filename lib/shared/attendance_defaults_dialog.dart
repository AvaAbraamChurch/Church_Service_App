import 'package:flutter/material.dart';
import 'package:church/core/repositories/attendance_defaults_repository.dart';
import 'package:church/core/styles/colors.dart';

/// Show a dialog displaying the current default attendance points
Future<void> showAttendanceDefaultsDialog(BuildContext context) async {
  final repo = AttendanceDefaultsRepository();

  // Show loading dialog first
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const Center(
      child: CircularProgressIndicator(),
    ),
  );

  // Fetch the values
  Map<String, int> values;
  try {
    values = await repo.getDefaults();
  } catch (e) {
    values = {
      'holy_mass': 0,
      'sunday_school': 0,
      'hymns': 0,
      'bible': 0,
    };
  }

  // Close loading dialog
  if (context.mounted) {
    Navigator.of(context).pop();
  }

  // Show the actual dialog
  if (!context.mounted) return;

  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [teal700, teal500],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.stars_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'نقاط الحضور',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Alexandria',
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'النقاط المكتسبة عند الحضور',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                            fontFamily: 'Alexandria',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildPointItem(
                    icon: Icons.church_rounded,
                    title: 'القداس الإلهي',
                    points: values['holy_mass']!,
                    color: Colors.purple,
                  ),
                  const SizedBox(height: 16),
                  _buildPointItem(
                    icon: Icons.school_rounded,
                    title: 'مدارس الأحد',
                    points: values['sunday_school']!,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  _buildPointItem(
                    icon: Icons.music_note_rounded,
                    title: 'الألحان',
                    points: values['hymns']!,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  _buildPointItem(
                    icon: Icons.menu_book_rounded,
                    title: 'الكتاب المقدس',
                    points: values['bible']!,
                    color: Colors.green,
                  ),
                ],
              ),
            ),

            // Close button
            Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: teal700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'إغلاق',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Alexandria',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildPointItem({
  required IconData icon,
  required String title,
  required int points,
  required Color color,
}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: teal700,
              fontSize: 16,
              fontFamily: 'Alexandria',
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.7)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$points',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Alexandria',
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.star,
                color: Colors.white,
                size: 16,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

