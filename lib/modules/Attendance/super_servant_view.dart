import 'package:church/core/blocs/attendance/attendance_cubit.dart';
import 'package:church/core/constants/strings.dart';
import 'package:church/core/models/attendance/attendance_model.dart';
import 'package:church/core/models/user/user_model.dart';
import 'package:church/core/styles/colors.dart';
import 'package:church/core/styles/themeScaffold.dart';
import 'package:church/core/utils/attendance_enum.dart';
import 'package:church/core/utils/userType_enum.dart';
import 'package:church/shared/avatar_display_widget.dart';
import 'package:flutter/material.dart';
import '../requests/requests_screen.dart';

/// Priest attendance screen — 2-step internal flow:
///   Step 1 — User type        (خدام · مخدومين)
///   Step 2 — Attendance list  (4-status cards)
///
/// The attendance type (pageIndex) is passed from [SuperServantView].
class SuperServantView extends StatefulWidget {
  final AttendanceCubit cubit;
  final int pageIndex;

  const SuperServantView(this.cubit, {super.key, this.pageIndex = -1});

  @override
  State<SuperServantView> createState() => _SuperServantViewState();
}

class _SuperServantViewState extends State<SuperServantView> {
  // ─── Step state ───────────────────────────────────────────────────────────

  String? selectedUserType; // Arabic label: superServant / servant / child

  // ─── Step 2 state ─────────────────────────────────────────────────────────
  final Map<String, AttendanceStatus> attendanceMap = {};
  List<UserModel> filteredUsers       = [];
  List<UserModel> selectedGroupUsers  = [];
  List<UserModel> servants            = [];
  List<UserModel> children            = [];
  final searchController              = TextEditingController();
  bool isSubmitting                   = false;

  // Filters
  String? selectedClass;
  List<String> availableClasses = [];

  // ─── Attendance type definitions ──────────────────────────────────────────
  static const List<_AttendanceTypeDef> _attendanceTypes = [
    _AttendanceTypeDef(key: 'holy_mass',     label: 'القداس',       icon: Icons.church_rounded,      index: 0, gradient: [Color(0xFF0D9488), Color(0xFF0F766E)]),
    _AttendanceTypeDef(key: 'sunday_school', label: 'مدارس الأحد',  icon: Icons.auto_stories_rounded, index: 1, gradient: [Color(0xFF0EA5E9), Color(0xFF0284C7)]),
    _AttendanceTypeDef(key: 'hymns',         label: 'الألحان',      icon: Icons.music_note_rounded,   index: 2, gradient: [Color(0xFF8B5CF6), Color(0xFF7C3AED)]),
    _AttendanceTypeDef(key: 'bible',         label: 'درس الكتاب',  icon: Icons.menu_book_rounded,    index: 3, gradient: [Color(0xFFF59E0B), Color(0xFFD97706)]),
    _AttendanceTypeDef(key: 'visit',         label: 'الافتقاد',    icon: Icons.home_rounded,         index: 4, gradient: [Color(0xFF10B981), Color(0xFF059669)]),
  ];

  // ─── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    searchController.addListener(_filterUsers);
    _refreshLists();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _refreshLists() {
    servants      = widget.cubit.users?.where((u) => u.userType.code == UserType.servant.code).toList()      ?? [];
    children      = widget.cubit.users?.where((u) => u.userType.code == UserType.child.code).toList()        ?? [];
  }

  void _initializeAttendance() {
    attendanceMap.clear();
    final List<UserModel> baseList;
    if (selectedUserType == servant) {
      baseList = servants;
    } else {
      baseList = children;
    }
    for (final user in baseList) {
      attendanceMap[user.id] = AttendanceStatus.absent;
    }
    selectedGroupUsers = List.from(baseList);
    filteredUsers      = List.from(baseList);

    final classes = baseList.map((u) => u.userClass).toSet().toList()..sort();
    availableClasses = ['الكل', ...classes];
    selectedClass  = 'الكل';
  }

  void _filterUsers() {
    setState(() {
      List<UserModel> tmp = List.from(selectedGroupUsers);
      if (selectedClass  != null && selectedClass  != 'الكل') tmp = tmp.where((u) => u.userClass  == selectedClass).toList();
    });
  }

  _AttendanceTypeDef get _currentTypeDef =>
      _attendanceTypes.firstWhere((t) => t.index == widget.pageIndex,
          orElse: () => _attendanceTypes[0]);

  String _attendanceTypeString(int index) {
    switch (index) {
      case 0: return holyMass;
      case 1: return sunday;
      case 2: return hymns;
      case 3: return bibleClass;
      case 4: return visit;
      default: return '';
    }
  }

  // ─── Submit ───────────────────────────────────────────────────────────────
  Future<void> _submitAttendance() async {
    if (isSubmitting) return;

    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime.now(),
      helpText: 'اختر تاريخ الحضور',
      cancelText: 'إلغاء',
      confirmText: 'تأكيد',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: _currentTypeDef.gradient[0], onPrimary: Colors.white, surface: Colors.white, onSurface: teal900),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;

    setState(() => isSubmitting = true);
    try {
      final now  = DateTime.now();
      final attendanceDate = DateTime(date.year, date.month, date.day);

      final list = attendanceMap.entries.map((e) {
        final user = selectedGroupUsers.firstWhere((u) => u.id == e.key);
        return AttendanceModel(
          id: '',
          userId: user.id,
          userName: user.fullName,
          userType: user.userType,
          date: attendanceDate,
          attendanceType: _attendanceTypeString(widget.pageIndex),
          status: e.value,
          checkInTime: (e.value == AttendanceStatus.present || e.value == AttendanceStatus.late) ? now : null,
          createdAt: now,
        );
      }).toList();

      await widget.cubit.batchTakeAttendance(list);

      if (mounted) {
        setState(() {
          attendanceMap.clear();
          selectedUserType   = null;
          selectedGroupUsers = [];
          filteredUsers      = [];
        });
        _showSnack('تم حفظ الحضور بنجاح ✓');
      }
    } catch (e) {
      _showSnack('خطأ في تسجيل الحضور: $e', error: true);
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  void _showSnack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Alexandria', fontSize: 14)),
      backgroundColor: error ? Colors.red[600] : Colors.green[600],
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ─── Router ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return ThemedScaffold(
      body: selectedUserType == null ? _buildUserTypeStep() : _buildAttendanceStep(),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 1 — User type selection
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildUserTypeStep() {
    final typeDef = _currentTypeDef;
    return Column(
      children: [
        // Curved gradient header
        _CurvedHeader(
          icon: typeDef.icon,
          title: 'حضور ${typeDef.label}',
          subtitle: 'اختر نوع المستخدمين',
          gradient: typeDef.gradient,
          onBack: () => Navigator.pop(context),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            children: [
              _UserTypeCard(
                title: 'الخدام',
                subtitle: 'تسجيل حضور الخدام',
                icon: Icons.people_alt_rounded,
                color: red500,
                count: servants.length,
                onTap: () {
                  setState(() {
                    selectedUserType = servant;
                    _initializeAttendance();
                  });
                },
              ),
              const SizedBox(height: 14),
              _UserTypeCard(
                title: 'المخدومين',
                subtitle: 'تسجيل حضور المخدومين',
                icon: Icons.child_care_rounded,
                color: sage500,
                count: children.length,
                onTap: () {
                  setState(() {
                    selectedUserType = child;
                    _initializeAttendance();
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 2 — Attendance taking
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildAttendanceStep() {
    final typeDef   = _currentTypeDef;
    final userLabel = selectedUserType == servant
        ? 'الخدام'
        : 'المخدومين';

    return LayoutBuilder(
      builder: (context, _) {
        final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
        return Column(
          children: [
            // Compact header
            _ListHeader(
              title: '${typeDef.label} · $userLabel',
              gradient: typeDef.gradient,
              icon: typeDef.icon,
              filteredCount: filteredUsers.length,
              totalCount: selectedGroupUsers.length,
              searchEmpty: searchController.text.isEmpty,
              onBack: () => setState(() {
                selectedUserType = null;
                attendanceMap.clear();
                searchController.clear();
                filteredUsers = [];
                selectedGroupUsers = [];
              }),
              keyboardVisible: keyboardVisible,
            ),
            const SizedBox(height: 10),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _SearchBar(controller: searchController, primaryColor: typeDef.gradient[0]),
            ),
            const SizedBox(height: 8),

            // Filters
            if (availableClasses.length > 1) ...[
              _FilterRow(
                label: classroom, icon: Icons.class_, chips: availableClasses,
                selected: selectedClass ?? 'الكل',
                onSelect: (v) => setState(() { selectedClass = v; _filterUsers(); }),
              ),
              const SizedBox(height: 15),
            ],


            // User list
            Flexible(
              child: filteredUsers.isEmpty
                  ? _EmptySearch()
                  : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: filteredUsers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final user   = filteredUsers[i];
                  final status = attendanceMap[user.id] ?? AttendanceStatus.absent;
                  return _AttendanceCard(
                    user: user,
                    status: status,
                    accentColor: typeDef.gradient[0],
                    onStatusChanged: (s) => setState(() => attendanceMap[user.id] = s),
                  );
                },
              ),
            ),

            // Submit + requests buttons
            if (!keyboardVisible)
              _BottomBar(
                cubit: widget.cubit,
                isSubmitting: isSubmitting,
                onSubmit: _submitAttendance,
                onRequests: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => RequestsScreen(cubit: widget.cubit)),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Data class
// ════════════════════════════════════════════════════════════════════════════

class _AttendanceTypeDef {
  final String key, label;
  final IconData icon;
  final int index;
  final List<Color> gradient;
  const _AttendanceTypeDef({required this.key, required this.label, required this.icon, required this.index, required this.gradient});
}

// ════════════════════════════════════════════════════════════════════════════
// Sub-widgets — all shared with the same design language
// ════════════════════════════════════════════════════════════════════════════

// ─── Curved gradient header (Step 1) ─────────────────────────────────────────

class _CurvedHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback? onBack;
  const _CurvedHeader({required this.icon, required this.title, required this.subtitle, required this.gradient, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(36), bottomRight: Radius.circular(36)),
        boxShadow: [BoxShadow(color: gradient[0].withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 6))],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 20, 24),
          child: Row(
            children: [
              if (onBack != null)
                IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20), onPressed: onBack)
              else
                const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title,    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold,  color: Colors.white, fontFamily: 'Alexandria')),
                  Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.85), fontFamily: 'Alexandria')),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Compact list header (Step 2) ─────────────────────────────────────────────

class _ListHeader extends StatelessWidget {
  final String title;
  final List<Color> gradient;
  final IconData icon;
  final int filteredCount, totalCount;
  final bool searchEmpty, keyboardVisible;
  final VoidCallback onBack;
  const _ListHeader({required this.title, required this.gradient, required this.icon, required this.filteredCount, required this.totalCount, required this.searchEmpty, required this.onBack, required this.keyboardVisible});

  @override
  Widget build(BuildContext context) {
    final countText = searchEmpty ? '$totalCount مستخدم' : '$filteredCount من $totalCount';
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
        boxShadow: [BoxShadow(color: gradient[0].withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 5))],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 16, 16),
          child: Row(
            children: [
              if (!keyboardVisible)
                IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20), onPressed: onBack),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Alexandria'))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                child: Text(countText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Alexandria')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── User type card ───────────────────────────────────────────────────────────

class _UserTypeCard extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Color color;
  final int count;
  final VoidCallback onTap;
  const _UserTypeCard({required this.title, required this.subtitle, required this.icon, required this.color, required this.count, required this.onTap});

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
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 14, offset: const Offset(0, 4))],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: teal900, fontFamily: 'Alexandria')),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[600], fontFamily: 'Alexandria')),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                      child: Text('$count مستخدم', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color, fontFamily: 'Alexandria')),
                    ),
                  ]),
                ),
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.arrow_forward_ios_rounded, color: color, size: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Attendance card ──────────────────────────────────────────────────────────

class _AttendanceCard extends StatelessWidget {
  final UserModel user;
  final AttendanceStatus status;
  final Color accentColor;
  final ValueChanged<AttendanceStatus> onStatusChanged;
  const _AttendanceCard({required this.user, required this.status, required this.accentColor, required this.onStatusChanged});

  Color get _statusColor {
    switch (status) {
      case AttendanceStatus.present: return Colors.green;
      case AttendanceStatus.absent:  return Colors.red;
      case AttendanceStatus.late:    return Colors.orange;
      case AttendanceStatus.excused: return Colors.blue;
    }
  }

  IconData get _statusIcon {
    switch (status) {
      case AttendanceStatus.present: return Icons.check_circle;
      case AttendanceStatus.absent:  return Icons.cancel;
      case AttendanceStatus.late:    return Icons.access_time;
      case AttendanceStatus.excused: return Icons.info;
    }
  }

  String get _statusText {
    switch (status) {
      case AttendanceStatus.present: return 'حاضر';
      case AttendanceStatus.absent:  return 'غائب';
      case AttendanceStatus.late:    return 'متأخر';
      case AttendanceStatus.excused: return 'معتذر';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(colors: [Colors.white, _statusColor.withValues(alpha: 0.05)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [BoxShadow(color: _statusColor.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            // User info row
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _statusColor, width: 2)),
                  child: AvatarDisplayWidget(user: user, size: 52, showBorder: false, borderWidth: 0),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(user.fullName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: teal900, fontFamily: 'Alexandria')),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(color: _statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(_statusIcon, size: 13, color: _statusColor),
                        const SizedBox(width: 4),
                        Text(_statusText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor, fontFamily: 'Alexandria')),
                      ]),
                    ),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Status buttons
            Row(
              children: [
                Expanded(child: _StatusBtn(label: 'حاضر',  icon: Icons.check_circle,  color: Colors.green,  isSelected: status == AttendanceStatus.present, onTap: () => onStatusChanged(AttendanceStatus.present))),
                const SizedBox(width: 6),
                Expanded(child: _StatusBtn(label: 'غائب',  icon: Icons.cancel,        color: Colors.red,    isSelected: status == AttendanceStatus.absent,  onTap: () => onStatusChanged(AttendanceStatus.absent))),
                const SizedBox(width: 6),
                Expanded(child: _StatusBtn(label: 'متأخر', icon: Icons.access_time,   color: Colors.orange, isSelected: status == AttendanceStatus.late,    onTap: () => onStatusChanged(AttendanceStatus.late))),
                const SizedBox(width: 6),
                Expanded(child: _StatusBtn(label: 'معتذر', icon: Icons.info,          color: Colors.blue,   isSelected: status == AttendanceStatus.excused, onTap: () => onStatusChanged(AttendanceStatus.excused))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Status button ────────────────────────────────────────────────────────────

class _StatusBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  const _StatusBtn({required this.label, required this.icon, required this.color, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: isSelected ? color : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: isSelected ? color : color.withValues(alpha: 0.3), width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(children: [
              Icon(icon, color: isSelected ? Colors.white : color, size: 20),
              const SizedBox(height: 3),
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : color, fontFamily: 'Alexandria')),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─── Search bar ───────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final Color primaryColor;
  const _SearchBar({required this.controller, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: TextField(
        controller: controller,
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(fontFamily: 'Alexandria', fontSize: 14),
        decoration: InputDecoration(
          hintText: 'ابحث عن مستخدم...',
          hintStyle: TextStyle(color: Colors.grey[400], fontFamily: 'Alexandria', fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded, color: primaryColor, size: 20),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, val, __) => val.text.isNotEmpty
                ? IconButton(icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)), onPressed: controller.clear)
                : const SizedBox.shrink(),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

// ─── Filter row ───────────────────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<String> chips;
  final String selected;
  final ValueChanged<String> onSelect;
  const _FilterRow({required this.label, required this.icon, required this.chips, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, color: teal300, size: 16),
          const SizedBox(width: 6),
          Text('$label:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white, fontFamily: 'Alexandria')),
          const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: chips.map((c) {
                  final isSel = selected == c;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(c),
                      selected: isSel,
                      onSelected: (_) => onSelect(c),
                      backgroundColor: Colors.white,
                      selectedColor: teal400,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(color: isSel ? Colors.white : teal900, fontWeight: FontWeight.w600, fontSize: 12, fontFamily: 'Alexandria'),
                      side: BorderSide(color: isSel ? teal500 : Colors.grey[300]!, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final AttendanceCubit cubit;
  final bool isSubmitting;
  final VoidCallback onSubmit;
  final VoidCallback onRequests;
  const _BottomBar({required this.cubit, required this.isSubmitting, required this.onSubmit, required this.onRequests});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: Row(
        children: [
          // Submit button
          Expanded(
            flex: 3,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: isSubmitting
                    ? LinearGradient(colors: [Colors.grey[300]!, Colors.grey[400]!])
                    : const LinearGradient(colors: [Color(0xFF0D9488), Color(0xFF0F766E)], begin: Alignment.centerRight, end: Alignment.centerLeft),
                boxShadow: isSubmitting ? [] : [BoxShadow(color: teal500.withValues(alpha: 0.4), blurRadius: 14, offset: const Offset(0, 5))],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isSubmitting ? null : onSubmit,
                  borderRadius: BorderRadius.circular(16),
                  child: Center(
                    child: isSubmitting
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('حفظ الحضور', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Alexandria')),
                    ]),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Requests button with badge
          StreamBuilder<List<dynamic>>(
            stream: cubit.streamPendingAttendanceRequestsForSuperServant(),
            builder: (context, snapshot) {
              final count = (snapshot.data ?? []).length;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 54, width: 54,
                    decoration: BoxDecoration(
                      color: teal100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: teal300, width: 1.5),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onRequests,
                        borderRadius: BorderRadius.circular(16),
                        child: Icon(Icons.request_page_rounded, color: teal700, size: 24),
                      ),
                    ),
                  ),
                  if (count > 0)
                    Positioned(
                      right: -8,
                      top: -8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        child: Center(
                          child: Text(
                            count > 99 ? '99+' : '$count',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Empty search ─────────────────────────────────────────────────────────────

class _EmptySearch extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[300]),
        const SizedBox(height: 14),
        Text('لا توجد نتائج', style: TextStyle(fontSize: 16, color: Colors.grey[500], fontFamily: 'Alexandria')),
      ]),
    );
  }
}