import 'package:church/core/blocs/attendance/attendance_cubit.dart';
import 'package:church/core/constants/functions.dart';
import 'package:church/core/constants/strings.dart';
import 'package:church/core/models/attendance/attendance_model.dart';
import 'package:church/core/models/user/user_model.dart';
import 'package:church/core/repositories/attendance_defaults_repository.dart';
import 'package:church/core/services/coupon_points_service.dart';
import 'package:church/core/styles/colors.dart';
import 'package:church/core/utils/attendance_enum.dart';
import 'package:church/core/utils/gender_enum.dart';
import 'package:church/core/utils/userType_enum.dart';
import 'package:church/shared/avatar_display_widget.dart';
import 'package:church/shared/points_sync_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Opened when the servant taps an attendance-type card in [ServantHomeView].
///
/// Layout:
///   • Sticky curved header containing title + search bar
///   • Scrollable list of child cards  (name · points · edit button · toggle)
///   • Fixed submit button at the bottom
class AttendanceTypeScreen extends StatefulWidget {
  final AttendanceCubit cubit;
  final UserType userType;
  final Gender gender;
  final String attendanceKey;
  final String label;
  final IconData icon;
  final List<Color> gradient;
  final int pageIndex;

  const AttendanceTypeScreen({
    super.key,
    required this.cubit,
    required this.userType,
    required this.gender,
    required this.attendanceKey,
    required this.label,
    required this.icon,
    required this.gradient,
    required this.pageIndex,
  });

  @override
  State<AttendanceTypeScreen> createState() => _AttendanceTypeScreenState();
}

class _AttendanceTypeScreenState extends State<AttendanceTypeScreen> {
  // ─── State ────────────────────────────────────────────────────────────────

  final _searchCtrl = TextEditingController();
  final Map<String, bool> _attendanceMap = {};
  final Map<String, int> _pointsMap = {};
  List<UserModel> _filtered = [];
  bool _isSubmitting = false;

  final _pointsService = CouponPointsService();
  final _defaultsRepo = AttendanceDefaultsRepository();

  // ─── Shortcuts ────────────────────────────────────────────────────────────

  Color get _primary => widget.gradient[0];
  Color get _secondary => widget.gradient[1];

  bool get _canEditPoints {
    final c = widget.cubit.currentUser?.userType.code;
    return c == UserType.servant.code ||
        c == UserType.superServant.code ||
        c == UserType.priest.code;
  }

  int get _presentCount => _attendanceMap.values.where((v) => v).length;

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _initData();
    _searchCtrl.addListener(_filter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _initData() {
    final users = widget.cubit.users ?? [];
    for (final u in users) {
      _attendanceMap[u.id] = false;
      _pointsMap[u.id] = u.couponPoints;
    }
    _filtered = List.from(users);
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? List.from(widget.cubit.users ?? [])
          : (widget.cubit.users ?? [])
                .where((u) =>
                    normalizeArabic(u.fullName.toLowerCase()).contains(q))
                .toList();
    });
  }

  // ─── Toggle attendance ────────────────────────────────────────────────────

  void _toggle(String userId) =>
      setState(() => _attendanceMap[userId] = !(_attendanceMap[userId] ?? false));

  // ─── Points dialog ────────────────────────────────────────────────────────

  void _showPointsDialog(UserModel user) {
    if (!_canEditPoints || user.userType.code != UserType.child.code) return;

    final pointsCtrl = TextEditingController();
    final reasonCtrl = TextEditingController(text: 'تعديل يدوي');

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ───────────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.person_rounded, color: _primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Alexandria',
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'النقاط الحالية: ${_pointsMap[user.id] ?? user.couponPoints}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontFamily: 'Alexandria',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 20),

              // ── Points field ──────────────────────────────────────────────
              _DialogField(
                controller: pointsCtrl,
                label: 'عدد النقاط',
                hint: 'أدخل رقماً (موجب أو سالب)',
                icon: Icons.add_circle_outline_rounded,
                primaryColor: _primary,
                keyboardType:
                    const TextInputType.numberWithOptions(signed: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')),
                ],
              ),

              const SizedBox(height: 14),

              // ── Reason field ──────────────────────────────────────────────
              _DialogField(
                controller: reasonCtrl,
                label: 'السبب',
                hint: 'سبب التعديل',
                icon: Icons.notes_rounded,
                primaryColor: _primary,
                maxLines: 2,
              ),

              const SizedBox(height: 24),

              // ── Actions ───────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      child: const Text(
                        'إلغاء',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontFamily: 'Alexandria',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () async {
                        final txt = pointsCtrl.text.trim();
                        final reason = reasonCtrl.text.trim();
                        if (txt.isEmpty || reason.isEmpty) {
                          _snack('الرجاء ملء جميع الحقول', error: true);
                          return;
                        }
                        final pts = int.tryParse(txt);
                        if (pts == null) {
                          _snack('الرجاء إدخال رقم صحيح', error: true);
                          return;
                        }
                        Navigator.pop(ctx);
                        await _applyPoints(user, pts, reason);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text(
                        'تطبيق',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Alexandria',
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Apply points ─────────────────────────────────────────────────────────

  Future<void> _applyPoints(UserModel user, int pts, String reason) async {
    if (!_canEditPoints || user.userType.code != UserType.child.code) {
      _snack('غير مسموح بتعديل النقاط لهذا المستخدم', error: true);
      return;
    }
    try {
      setState(() => _isSubmitting = true);
      await _pointsService.setPoints(
        user.id, pts, reason,
        widget.cubit.currentUser?.id ?? 'system',
      );
      final updated = await _pointsService.getUserPoints(user.id);
      setState(() => _pointsMap[user.id] = updated);
      _snack('تم ${pts >= 0 ? 'إضافة' : 'خصم'} ${pts.abs()} نقطة بنجاح ✓');
    } catch (e) {
      _snack('خطأ في تطبيق النقاط: $e', error: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ─── Submit attendance ────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (_isSubmitting || _presentCount == 0) return;

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
          colorScheme: ColorScheme.light(
            primary: _primary,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: teal900,
          ),
        ),
        child: child!,
      ),
    );

    if (date == null || !mounted) return;

    setState(() => _isSubmitting = true);

    try {
      final now = DateTime.now();
      final attendanceDate = DateTime(date.year, date.month, date.day);
      final defaults = await _defaultsRepo.getDefaults();

      final List<AttendanceModel> list = [];
      final Map<String, int> toAdd = {};

      for (final e in _attendanceMap.entries) {
        if (!e.value) continue;
        final user =
            widget.cubit.users!.firstWhere((u) => u.id == e.key);

        list.add(AttendanceModel(
          id: '',
          userId: user.id,
          userName: user.fullName,
          userType: user.userType,
          date: attendanceDate,
          attendanceType: _typeString(widget.attendanceKey),
          status: AttendanceStatus.present,
          checkInTime: now,
          createdAt: now,
        ));

        if (user.userType.code == UserType.child.code) {
          toAdd[user.id] =
              (toAdd[user.id] ?? 0) + (defaults[widget.attendanceKey] ?? 1);
        }
      }

      if (list.isNotEmpty) await widget.cubit.batchTakeAttendance(list);

      for (final e in toAdd.entries) {
        await _pointsService.setPoints(
          e.key, e.value,
          'حضور ${widget.label}',
          widget.cubit.currentUser?.id ?? 'system',
        );
      }

      _snack('تم تسجيل حضور $_presentCount شخص بنجاح ✓');
      setState(() => _attendanceMap.updateAll((_, __) => false));
    } catch (e) {
      _snack('خطأ في تسجيل الحضور: $e', error: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _typeString(String key) {
    switch (key) {
      case 'holy_mass':     return holyMass;
      case 'sunday_school': return sunday;
      case 'hymns':         return hymns;
      case 'bible':         return bibleClass;
      case 'visit':         return visit;
      default:              return '';
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(fontFamily: 'Alexandria', fontSize: 14)),
      backgroundColor: error ? Colors.red[600] : Colors.green[600],
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(
        children: [
          // ── Sticky header (back + title + search) ─────────────────────────
          _AttendanceHeader(
            label: widget.label,
            icon: widget.icon,
            gradient: widget.gradient,
            searchCtrl: _searchCtrl,
            primaryColor: _primary,
          ),

          // ── Sync status ───────────────────────────────────────────────────
          const PointsSyncStatusWidget(),

          // ── Counter chip ──────────────────────────────────────────────────
          if (_presentCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: _CounterChip(
                  count: _presentCount, color: _primary),
            ),

          // ── Children list ─────────────────────────────────────────────────
          Expanded(
            child: _filtered.isEmpty
                ? _EmptySearch(query: _searchCtrl.text)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final user = _filtered[i];
                      final present =
                          _attendanceMap[user.id] ?? false;
                      final pts =
                          _pointsMap[user.id] ?? user.couponPoints;
                      return _ChildCard(
                        user: user,
                        isPresent: present,
                        points: pts,
                        primaryColor: _primary,
                        secondaryColor: _secondary,
                        canEdit: _canEditPoints &&
                            user.userType.code ==
                                UserType.child.code,
                        onTap: () => _toggle(user.id),
                        onEdit: () => _showPointsDialog(user),
                      );
                    },
                  ),
          ),
        ],
      ),

      // ── Submit button ──────────────────────────────────────────────────────
      bottomNavigationBar: _SubmitBar(
        label: widget.label,
        presentCount: _presentCount,
        isSubmitting: _isSubmitting,
        primaryColor: _primary,
        secondaryColor: _secondary,
        onTap: _submit,
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Sub-widgets
// ════════════════════════════════════════════════════════════════════════════

// ─── Sticky header ─────────────────────────────────────────────────────────

class _AttendanceHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<Color> gradient;
  final TextEditingController searchCtrl;
  final Color primaryColor;

  const _AttendanceHeader({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.searchCtrl,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 16, 20),
          child: Column(
            children: [
              // Title row
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'حضور $label',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Alexandria',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Search bar
              Container(
                height: 48,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: searchCtrl,
                  textAlignVertical: TextAlignVertical.center,
                  style: const TextStyle(
                    fontFamily: 'Alexandria',
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن طفل...',
                    hintStyle: const TextStyle(
                      fontFamily: 'Alexandria',
                      fontSize: 14,
                      color: Color(0xFF94A3B8),
                    ),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: primaryColor, size: 20),
                    suffixIcon: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: searchCtrl,
                      builder: (_, val, __) => val.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded,
                                  size: 18, color: Color(0xFF94A3B8)),
                              onPressed: searchCtrl.clear,
                            )
                          : const SizedBox.shrink(),
                    ),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Counter chip ─────────────────────────────────────────────────────────────

class _CounterChip extends StatelessWidget {
  final int count;
  final Color color;
  const _CounterChip({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              '$count ${count == 1 ? 'شخص' : 'أشخاص'} محضرين',
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: 'Alexandria',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Child card ───────────────────────────────────────────────────────────────

class _ChildCard extends StatelessWidget {
  final UserModel user;
  final bool isPresent;
  final int points;
  final Color primaryColor;
  final Color secondaryColor;
  final bool canEdit;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const _ChildCard({
    required this.user,
    required this.isPresent,
    required this.points,
    required this.primaryColor,
    required this.secondaryColor,
    required this.canEdit,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: isPresent
            ? LinearGradient(
                colors: [primaryColor, secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isPresent ? null : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPresent ? primaryColor : const Color(0xFFE2E8F0),
          width: isPresent ? 0 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isPresent
                ? primaryColor.withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: isPresent ? 14 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
            child: Row(
              children: [
                // ── Avatar ────────────────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isPresent
                          ? Colors.white.withValues(alpha: 0.7)
                          : primaryColor.withValues(alpha: 0.4),
                      width: 2.5,
                    ),
                  ),
                  child: AvatarDisplayWidget(
                    user: user,
                    size: 52,
                    showBorder: false,
                    borderWidth: 0,
                  ),
                ),

                const SizedBox(width: 14),

                // ── Name + points ──────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Alexandria',
                          color: isPresent
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 5),
                      // Points badge
                      _PointsBadge(
                        points: points,
                        isPresent: isPresent,
                        primaryColor: primaryColor,
                      ),
                    ],
                  ),
                ),

                // ── Edit button ────────────────────────────────────────────
                if (canEdit) ...[
                  _ActionBtn(
                    icon: Icons.edit_rounded,
                    color: isPresent
                        ? Colors.white.withValues(alpha: 0.85)
                        : primaryColor,
                    bgColor: isPresent
                        ? Colors.white.withValues(alpha: 0.18)
                        : primaryColor.withValues(alpha: 0.1),
                    tooltip: 'تعديل النقاط',
                    onTap: onEdit,
                  ),
                  const SizedBox(width: 6),
                ],

                // ── Attendance toggle ──────────────────────────────────────
                AnimatedScale(
                  duration: const Duration(milliseconds: 250),
                  scale: isPresent ? 1.05 : 1.0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isPresent
                          ? Colors.white
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isPresent
                            ? Colors.white
                            : const Color(0xFFCBD5E1),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      isPresent
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      color: isPresent ? primaryColor : const Color(0xFFCBD5E1),
                      size: 26,
                    ),
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

// ─── Points badge ─────────────────────────────────────────────────────────────

class _PointsBadge extends StatelessWidget {
  final int points;
  final bool isPresent;
  final Color primaryColor;

  const _PointsBadge({
    required this.points,
    required this.isPresent,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPresent
            ? Colors.white.withValues(alpha: 0.22)
            : primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPresent
              ? Colors.white.withValues(alpha: 0.4)
              : primaryColor.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            size: 13,
            color: isPresent ? Colors.white : primaryColor,
          ),
          const SizedBox(width: 4),
          Text(
            '$points نقطة',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'Alexandria',
              color: isPresent ? Colors.white : primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action button (edit) ─────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}

// ─── Empty search ─────────────────────────────────────────────────────────────

class _EmptySearch extends StatelessWidget {
  final String query;
  const _EmptySearch({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded,
              size: 60, color: Colors.grey[300]),
          const SizedBox(height: 14),
          Text(
            'لا نتائج لـ "$query"',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[500],
              fontFamily: 'Alexandria',
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Submit bar ───────────────────────────────────────────────────────────────

class _SubmitBar extends StatelessWidget {
  final String label;
  final int presentCount;
  final bool isSubmitting;
  final Color primaryColor;
  final Color secondaryColor;
  final VoidCallback onTap;

  const _SubmitBar({
    required this.label,
    required this.presentCount,
    required this.isSubmitting,
    required this.primaryColor,
    required this.secondaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = presentCount > 0 && !isSubmitting;

    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: enabled
              ? LinearGradient(
                  colors: [primaryColor, secondaryColor],
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                )
              : LinearGradient(
                  colors: [Colors.grey[300]!, Colors.grey[400]!],
                ),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.45),
                    blurRadius: 16,
                    offset: const Offset(0, 5),
                  ),
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(18),
            child: Center(
              child: isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline_rounded,
                            color: Colors.white, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          presentCount > 0
                              ? 'تسجيل حضور $label ($presentCount)'
                              : 'اختر الحاضرين أولاً',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Alexandria',
                            color: enabled
                                ? Colors.white
                                : Colors.grey[500],
                          ),
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

// ─── Reusable dialog text field ───────────────────────────────────────────────

class _DialogField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final Color primaryColor;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;

  const _DialogField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.primaryColor,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      style: const TextStyle(fontFamily: 'Alexandria', fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: primaryColor, size: 20),
        labelStyle: TextStyle(fontFamily: 'Alexandria', color: primaryColor),
        hintStyle: const TextStyle(
            fontFamily: 'Alexandria', color: Color(0xFF94A3B8), fontSize: 13),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      ),
    );
  }
}
