import 'dart:async';
import 'package:church/core/blocs/attendance/attendance_states.dart';
import 'package:church/core/constants/strings.dart';
import 'package:church/core/styles/colors.dart';
import 'package:church/core/styles/themeScaffold.dart';
import 'package:church/core/utils/userType_enum.dart';
import 'package:church/core/utils/gender_enum.dart';
import 'package:church/modules/Attendance/child_view.dart';
import 'package:church/modules/Attendance/priest_view.dart';
import 'package:church/modules/Attendance/servant_home_view.dart';
import 'package:church/modules/Attendance/super_servant_view.dart';
import 'package:church/modules/Attendance/visits/visit_child_view.dart';
import 'package:church/modules/requests/requests_screen.dart';
import 'package:conditional_builder_null_safety/conditional_builder_null_safety.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/blocs/attendance/attendance_cubit.dart';

class AttendanceScreen extends StatefulWidget {
  final String userId;
  final UserType userType;
  final String userClass;
  final Gender gender;

  const AttendanceScreen({
    super.key,
    required this.userId,
    required this.userType,
    required this.userClass,
    required this.gender,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  late final AttendanceCubit cubit;
  late final Stream stream;
  StreamSubscription? _currentUserSubscription;

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    cubit = AttendanceCubit();

    bool tabsIsShown = false;

    _currentUserSubscription =
        cubit.getCurrentUser(widget.userId).listen((_) {});

    if (widget.userType == UserType.priest) {
      stream = cubit.getUsersByTypeForPriest([
        userTypeToJson(UserType.superServant),
        userTypeToJson(UserType.servant),
        userTypeToJson(UserType.child),
      ]);
    } else if (widget.userType == UserType.superServant) {
      stream = cubit.getUsersByTypeAndGender(
        [userTypeToJson(UserType.servant), userTypeToJson(UserType.child)],
        genderToJson(widget.gender),
      );
    } else if (widget.userType == UserType.servant) {
      stream = cubit.getUsersByType(
        widget.userClass,
        [userTypeToJson(UserType.child)],
        genderToJson(widget.gender),
      );
    } else {
      tabsIsShown = true;
      stream = cubit.getUserAttendanceHistory(widget.userId);
    }
  }

  @override
  void dispose() {
    _currentUserSubscription?.cancel();
    super.dispose();
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cubit,
      child: BlocConsumer<AttendanceCubit, AttendanceState>(
        listener: _handleStateChanges,
        builder: (context, state) {
          final cubit = AttendanceCubit.get(context);

          return StreamBuilder(
            stream: stream,
            builder: (context, snapshot) {
              // ── Child role: keep original ChildView + FAB layout ──────────
              if (widget.userType == UserType.child) {
                return _buildChildScaffold(context, cubit, snapshot);
              }

              // ── Servant / SuperServant / Priest: new home card layout ─────
              return _buildServantScaffold(context, cubit, snapshot);
            },
          );
        },
      ),
    );
  }

  // ─── Servant / SuperServant / Priest scaffold ─────────────────────────────

  Widget _buildServantScaffold(
      BuildContext context,
      AttendanceCubit cubit,
      AsyncSnapshot snapshot,
      ) {
    return ThemedScaffold(
      body: Column(
        children: [
          // ── Curved gradient header ────────────────────────────────────────
          _ServantHeader(
            cubit: cubit,
            userType: widget.userType,
            onRequestsTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RequestsScreen(cubit: cubit),
              ),
            ),
          ),

          // ── Body content ─────────────────────────────────────────────────
          Expanded(
            child: ConditionalBuilder(
              condition: snapshot.hasData &&
                  cubit.users != null &&
                  cubit.users!.isNotEmpty,
              builder: (_) => ServantHomeView(
                cubit: cubit,
                userType: widget.userType,
                gender: widget.gender,
              ),
              fallback: (_) => _buildFallback(snapshot),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Child scaffold (unchanged logic, refreshed visually) ────────────────

  Widget _buildChildScaffold(
      BuildContext context,
      AttendanceCubit cubit,
      AsyncSnapshot snapshot,
      ) {
    return ThemedScaffold(
      body: Column(
        children: [
          _ChildHeader(title: attendance),
          Expanded(
            child: ConditionalBuilder(
              condition: snapshot.hasData &&
                  cubit.attendanceHistory != null &&
                  cubit.attendanceHistory!.isNotEmpty,
              builder: (_) => ChildView(cubit, pageIndex: 0),
              fallback: (_) => _buildFallback(snapshot),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildChildFab(context, cubit),
    );
  }

  // ─── Child FAB ────────────────────────────────────────────────────────────

  Widget _buildChildFab(BuildContext context, AttendanceCubit cubit) {
    return FloatingActionButton(
      backgroundColor: teal500,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onPressed: () async {
        final key = await _showAttendanceTypeSheet(context);
        if (key == null || !context.mounted) return;

        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(DateTime.now().year - 1),
          lastDate: DateTime.now(),
        );
        if (date == null || !context.mounted) return;

        await cubit.submitAttendanceRequest(attendanceKey: key, date: date);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'تم إرسال الطلب وسيظهر في السجل كـ قيد المراجعة',
                style: TextStyle(fontFamily: 'Alexandria'),
              ),
              backgroundColor: teal500,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      },
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  Future<String?> _showAttendanceTypeSheet(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AttendanceTypeSheet(),
    );
  }

  // ─── Fallback states (loading / error / empty) ────────────────────────────

  Widget _buildFallback(AsyncSnapshot snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return _LoadingState();
    }
    if (snapshot.hasError) {
      return _ErrorState(onRetry: () => setState(() {}));
    }
    return _EmptyState(isChild: widget.userType == UserType.child);
  }

  // ─── BLoC listener ────────────────────────────────────────────────────────

  void _handleStateChanges(BuildContext context, AttendanceState state) {
    SnackBar? snack;

    if (state is takeAttendanceSuccess) {
      snack = _snack(
        icon: Icons.check_circle,
        message: 'تم حفظ الحضور بنجاح على الخادم',
        color: Colors.green,
      );
    } else if (state is takeAttendanceSuccessOffline) {
      snack = _snack(
        icon: Icons.offline_bolt,
        message:
        'تم حفظ الحضور محلياً\nسيتم المزامنة عند توفر الإنترنت${state.pendingCount > 1 ? "\nالسجلات المعلقة: ${state.pendingCount}" : ""}',
        color: Colors.orange[700]!,
        duration: const Duration(seconds: 5),
      );
    } else if (state is SyncComplete) {
      snack = _snack(
        icon: Icons.cloud_done,
        message: 'تمت المزامنة بنجاح! (${state.syncedCount} سجل)',
        color: teal500,
      );
    } else if (state is SyncPartiallyComplete) {
      snack = _snack(
        icon: Icons.warning,
        message: 'مزامنة جزئية — تم: ${state.syncedCount} • فشل: ${state.failedCount}',
        color: Colors.orange[800]!,
        duration: const Duration(seconds: 4),
      );
    } else if (state is OfflineModeActive) {
      snack = _snack(
        icon: Icons.wifi_off,
        message: state.pendingCount > 0
            ? 'وضع عدم الاتصال (${state.pendingCount} معلق)'
            : 'وضع عدم الاتصال',
        color: Colors.grey[700]!,
      );
    }

    if (snack != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(snack);
    }
  }

  SnackBar _snack({
    required IconData icon,
    required String message,
    required Color color,
    Duration duration = const Duration(seconds: 3),
  }) {
    return SnackBar(
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Alexandria',
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: duration,
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Private sub-widgets
// ════════════════════════════════════════════════════════════════════════════

// ─── Servant / Priest curved header ──────────────────────────────────────────

class _ServantHeader extends StatelessWidget {
  final AttendanceCubit cubit;
  final UserType userType;
  final VoidCallback onRequestsTap;

  const _ServantHeader({
    required this.cubit,
    required this.userType,
    required this.onRequestsTap,
  });

  Stream get _requestStream {
    if (userType == UserType.priest) {
      return cubit.streamPendingAttendanceRequestsForPriest();
    } else if (userType == UserType.superServant) {
      return cubit.streamPendingAttendanceRequestsForSuperServant();
    }
    return cubit.streamPendingAttendanceRequestsForServant();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [teal600, teal400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: teal500.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Row(
            children: [
              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attendance,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Alexandria',
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'اختر نوع الحضور',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.8),
                        fontFamily: 'Alexandria',
                      ),
                    ),
                  ],
                ),
              ),

              // Requests badge button
              StreamBuilder(
                stream: _requestStream,
                builder: (context, snapshot) {
                  final count = (snapshot.data ?? []).length as int;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _IconBtn(
                        icon: Icons.receipt_long_rounded,
                        onTap: onRequestsTap,
                        tooltip: 'الطلبات',
                      ),
                      if (count > 0)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border:
                              Border.all(color: Colors.white, width: 1.5),
                            ),
                            constraints: const BoxConstraints(
                                minWidth: 18, minHeight: 18),
                            child: Center(
                              child: Text(
                                count > 99 ? '99+' : '$count',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
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
        ),
      ),
    );
  }
}

// ─── Child header ─────────────────────────────────────────────────────────────

class _ChildHeader extends StatelessWidget {
  final String title;
  const _ChildHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [teal600, teal400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: teal500.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Alexandria',
                  ),
                ),
              ),
              const SizedBox(width: 44),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Reusable icon button ─────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  const _IconBtn({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}

// ─── Loading state ────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: teal100,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: teal300.withValues(alpha: 0.35),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Center(
              child: SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(color: teal500, strokeWidth: 3),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'جاري التحميل...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: teal900,
              fontFamily: 'Alexandria',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'يرجى الانتظار',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
              fontFamily: 'Alexandria',
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Error state ──────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, size: 40, color: Colors.red[400]),
            ),
            const SizedBox(height: 20),
            Text('حدث خطأ!',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                    fontFamily: 'Alexandria')),
            const SizedBox(height: 8),
            Text('حدث خطأ أثناء تحميل البيانات',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontFamily: 'Alexandria')),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
              label: const Text('إعادة المحاولة',
                  style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Alexandria',
                      fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: teal500,
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isChild;
  const _EmptyState({required this.isChild});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: teal300.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: teal100,
                shape: BoxShape.circle,
                border: Border.all(color: teal300, width: 2),
              ),
              child: Icon(
                isChild
                    ? Icons.history_edu_outlined
                    : Icons.people_outline_rounded,
                size: 46,
                color: teal700,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isChild ? 'لا توجد سجلات' : 'لا يوجد مستخدمين',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: teal900,
                  fontFamily: 'Alexandria'),
            ),
            const SizedBox(height: 8),
            Text(
              isChild
                  ? 'لم يتم العثور على أي سجلات\nلحضورك في هذه الفئة'
                  : 'لم يتم العثور على أي مستخدمين\nفي هذه الفئة',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                  height: 1.6,
                  fontFamily: 'Alexandria'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Attendance type bottom sheet (child FAB) ─────────────────────────────────

class _AttendanceTypeSheet extends StatelessWidget {
  static const _options = [
    {'key': 'holy_mass', 'icon': Icons.church, 'color': Color(0xFF7C3AED)},
    {'key': 'sunday_school', 'icon': Icons.school, 'color': Color(0xFF0284C7)},
    {'key': 'hymns', 'icon': Icons.music_note, 'color': Color(0xFFD97706)},
    {'key': 'bible', 'icon': Icons.menu_book, 'color': Color(0xFF059669)},
  ];

  static const _labels = {
    'holy_mass': 'القداس',
    'sunday_school': 'مدارس الأحد',
    'hymns': 'الألحان',
    'bible': 'درس الكتاب',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [teal500, teal300],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.event_note,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'اختر نوع الخدمة',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: teal900,
                      fontFamily: 'Alexandria',
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 6),
            ..._options.map(
                  (o) => _SheetOption(
                icon: o['icon'] as IconData,
                label: _labels[o['key']]!,
                color: o['color'] as Color,
                onTap: () => Navigator.pop(context, o['key']),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SheetOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: teal900,
                    fontFamily: 'Alexandria',
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.grey[400], size: 16),
            ],
          ),
        ),
      ),
    );
  }
}