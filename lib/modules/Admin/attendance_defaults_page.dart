import 'package:flutter/material.dart';
import 'package:church/core/repositories/attendance_defaults_repository.dart';
import 'package:church/core/styles/colors.dart';
import 'package:church/core/styles/themeScaffold.dart';

/// Admin page for managing default attendance points
class AttendanceDefaultsPage extends StatefulWidget {
  const AttendanceDefaultsPage({super.key});

  @override
  State<AttendanceDefaultsPage> createState() => _AttendanceDefaultsPageState();
}

class _AttendanceDefaultsPageState extends State<AttendanceDefaultsPage> {
  final _repo = AttendanceDefaultsRepository();
  final _formKey = GlobalKey<FormState>();
  final _holyMassController = TextEditingController();
  final _sundaySchoolController = TextEditingController();
  final _hymnsController = TextEditingController();
  final _bibleController = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final values = await _repo.getDefaults();
      _holyMassController.text = '${values['holy_mass']}';
      _sundaySchoolController.text = '${values['sunday_school']}';
      _hymnsController.text = '${values['hymns']}';
      _bibleController.text = '${values['bible']}';
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل البيانات: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final holyMass = int.parse(_holyMassController.text.trim());
    final sundaySchool = int.parse(_sundaySchoolController.text.trim());
    final hymns = int.parse(_hymnsController.text.trim());
    final bible = int.parse(_bibleController.text.trim());

    setState(() => _saving = true);
    try {
      await _repo.setDefaults(
        holyMass: holyMass,
        sundaySchool: sundaySchool,
        hymns: hymns,
        bible: bible,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ النقاط الافتراضية بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل الحفظ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _holyMassController.dispose();
    _sundaySchoolController.dispose();
    _hymnsController.dispose();
    _bibleController.dispose();
    super.dispose();
  }

  Widget _buildNumberField({
    required String label,
    required String subtitle,
    required TextEditingController controller,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Alexandria',
                      color: teal700
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontFamily: 'Alexandria',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 80,
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Alexandria',
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'مطلوب';
                  final n = int.tryParse(v.trim());
                  if (n == null || n < 0) return 'رقم صحيح';
                  return null;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                                Icons.stars_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'النقاط الافتراضية للحضور',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                fontFamily: 'Alexandria',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'تعيين قيم النقاط للحضور',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                            fontFamily: 'Alexandria',
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Info card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [teal500.withValues(alpha: 0.1), teal300.withValues(alpha: 0.05)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: teal500.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: teal700, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'يمكنك تعيين النقاط الافتراضية لكل نوع من أنواع الحضور',
                              style: TextStyle(
                                color: teal500,
                                fontSize: 14,
                                fontFamily: 'Alexandria',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    _buildNumberField(
                      label: 'القداس الإلهي',
                      subtitle: 'نقاط حضور القداس',
                      controller: _holyMassController,
                      icon: Icons.church_rounded,
                      iconColor: Colors.purple,
                    ),

                    _buildNumberField(
                      label: 'مدارس الأحد',
                      subtitle: 'نقاط حضور مدارس الأحد',
                      controller: _sundaySchoolController,
                      icon: Icons.school_rounded,
                      iconColor: Colors.blue,
                    ),

                    _buildNumberField(
                      label: 'الألحان',
                      subtitle: 'نقاط حضور درس الألحان',
                      controller: _hymnsController,
                      icon: Icons.music_note_rounded,
                      iconColor: Colors.orange,
                    ),

                    _buildNumberField(
                      label: 'الكتاب المقدس',
                      subtitle: 'نقاط حضور درس الكتاب المقدس',
                      controller: _bibleController,
                      icon: Icons.menu_book_rounded,
                      iconColor: Colors.green,
                    ),

                    const SizedBox(height: 32),

                    // Save button
                    ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: teal700,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save_rounded, color: Colors.white),
                                SizedBox(width: 12),
                                Text(
                                  'حفظ التغييرات',
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
                  ],
                ),
              ),
            ),
    );
  }
}

