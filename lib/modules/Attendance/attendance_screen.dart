import 'dart:async';
import 'package:church/core/blocs/attendance/attendance_states.dart';
import 'package:church/core/constants/strings.dart';
import 'package:church/core/styles/colors.dart';
import 'package:church/core/utils/userType_enum.dart';
import 'package:church/core/utils/gender_enum.dart';
import 'package:church/modules/Attendance/child_view.dart';
import 'package:church/modules/Attendance/priest_view.dart';
import 'package:church/modules/Attendance/servant_view.dart';
import 'package:church/modules/Attendance/super_servant_view.dart';
import 'package:church/modules/Attendance/visits/visit_priest_view.dart';
import 'package:church/modules/Attendance/visits/visit_super_servant_view.dart';
import 'package:church/modules/Attendance/visits/visit_servant_view.dart';
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

class _AttendanceScreenState extends State<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final AttendanceCubit cubit;
  late final Stream stream;
  StreamSubscription? _currentUserSubscription;

  @override
  void initState() {
    super.initState();
    cubit = AttendanceCubit();

    final userTypeEnum = widget.userType;
    final genderEnum = widget.gender;

    // Load current user first (subscribe to the stream to set currentUser)
    _currentUserSubscription = cubit.getCurrentUser(widget.userId).listen((
      user,
    ) {
      // currentUser is updated inside the stream
    });

    if (userTypeEnum == UserType.priest) {
      // Priest can see all users: superServants, servants, and children
      stream = cubit.getUsersByTypeForPriest([
        userTypeToJson(UserType.superServant),
        userTypeToJson(UserType.servant),
        userTypeToJson(UserType.child),
      ]);
    } else if (userTypeEnum == UserType.superServant) {
      // SuperServant can see servants and children of same gender
      stream = cubit.getUsersByTypeAndGender([
        userTypeToJson(UserType.servant),
        userTypeToJson(UserType.child),
      ], genderToJson(genderEnum));
    } else if (userTypeEnum == UserType.servant) {
      // Servant can see children of same class and gender
      stream = cubit.getUsersByType(widget.userClass, [
        userTypeToJson(UserType.child),
      ], genderToJson(genderEnum));
    } else if (userTypeEnum == UserType.child) {
      // Get attendance history for children
      stream = cubit.getUserAttendanceHistory(widget.userId);
    }
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _currentUserSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cubit,
      child: BlocConsumer<AttendanceCubit, AttendanceState>(
        builder: (BuildContext context, state) {
          final cubit = AttendanceCubit.get(context);
          final userTypeEnum = widget.userType;
          final genderEnum = widget.gender;

          return StreamBuilder(
            stream: stream,
            builder: (context, snapshot) {
              return Scaffold(
                appBar: PreferredSize(
                  preferredSize: Size.fromHeight(
                    MediaQuery.of(context).size.height * 0.18,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(60),
                        bottomRight: Radius.circular(60),
                      ),
                      gradient: LinearGradient(
                        colors: [teal500, teal300],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: teal500.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Column(
                        children: [
                          // Top toolbar with title and requests button
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 12.0,
                            ),
                            child: Row(
                              children: [
                                const Spacer(),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    attendance,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 1.2,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withValues(alpha: 0.2),
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: (userTypeEnum == UserType.servant ||
                                            userTypeEnum == UserType.superServant ||
                                            userTypeEnum == UserType.priest)
                                        ? StreamBuilder(
                                            stream: userTypeEnum == UserType.priest
                                                ? cubit.streamPendingAttendanceRequestsForPriest()
                                                : userTypeEnum == UserType.superServant
                                                    ? cubit.streamPendingAttendanceRequestsForSuperServant()
                                                    : cubit.streamPendingAttendanceRequestsForServant(),
                                            builder: (context, reqSnapshot) {
                                              final pendingCount = (reqSnapshot.data ?? []).length;
                                              return Stack(
                                                children: [
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors.white.withValues(alpha: 0.2),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: IconButton(
                                                      icon: const Icon(Icons.receipt_long, color: Colors.white),
                                                      onPressed: () {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) => RequestsScreen(cubit: cubit),
                                                          ),
                                                        );
                                                      },
                                                      tooltip: 'الطلبات',
                                                    ),
                                                  ),
                                                  if (pendingCount > 0)
                                                    Positioned(
                                                      left: 6,
                                                      top: 6,
                                                      child: Container(
                                                        padding: const EdgeInsets.all(4),
                                                        decoration: BoxDecoration(
                                                          color: Colors.red,
                                                          shape: BoxShape.circle,
                                                          border: Border.all(color: Colors.white, width: 2),
                                                        ),
                                                        constraints: const BoxConstraints(
                                                          minWidth: 20,
                                                          minHeight: 20,
                                                        ),
                                                        child: Center(
                                                          child: Text(
                                                            pendingCount > 99 ? '99+' : '$pendingCount',
                                                            style: const TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 10,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              );
                                            },
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Modern TabBar
                          Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: TabBar(
                              controller: _tabController,
                              dividerColor: Colors.transparent,
                              indicator: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white,
                                    Colors.white.withValues(alpha: 0.9),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              indicatorPadding: EdgeInsets.all(4),
                              labelColor: teal900,
                              unselectedLabelColor: Colors.white,
                              labelStyle: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Alexandria',
                              ),
                              unselectedLabelStyle: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Alexandria',
                              ),
                              isScrollable: true,
                              tabAlignment: TabAlignment.center,
                              padding: EdgeInsets.zero,
                              tabs: [
                                Tab(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.church, size: 18),
                                        SizedBox(width: 6),
                                        Text(holyMass),
                                      ],
                                    ),
                                  ),
                                ),
                                Tab(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.auto_stories, size: 18),
                                        SizedBox(width: 6),
                                        Text(sunday),
                                      ],
                                    ),
                                  ),
                                ),
                                Tab(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.music_note, size: 18),
                                        SizedBox(width: 6),
                                        Text(hymns),
                                      ],
                                    ),
                                  ),
                                ),
                                Tab(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.menu_book, size: 18),
                                        SizedBox(width: 6),
                                        Text(bibleClass),
                                      ],
                                    ),
                                  ),
                                ),
                                Tab(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.home_outlined, size: 18),
                                        SizedBox(width: 6),
                                        Text(visit),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                backgroundColor: Colors.transparent,
                body: ConditionalBuilder(
                  condition:
                      snapshot.hasData &&
                      ((userTypeEnum != UserType.child &&
                              cubit.users != null &&
                              cubit.users!.isNotEmpty) ||
                          (userTypeEnum == UserType.child &&
                              cubit.attendanceHistory != null &&
                              cubit.attendanceHistory!.isNotEmpty)),
                  builder: (BuildContext context) {
                    return TabBarView(
                      controller: _tabController,
                      children: [
                        // Holy Mass tab
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              if (userTypeEnum == UserType.priest) ...[
                                Expanded(
                                  child: PriestView(cubit, pageIndex: 0),
                                ),
                              ] else if (userTypeEnum ==
                                  UserType.superServant) ...[
                                Expanded(
                                  child: SuperServantView(
                                    cubit,
                                    gender: genderToJson(genderEnum),
                                    pageIndex: 0,
                                  ),
                                ),
                              ] else if (userTypeEnum == UserType.servant) ...[
                                Expanded(
                                  child: ServantView(
                                    cubit: cubit,
                                    pageIndex: 0,
                                  ),
                                ),
                              ] else ...[
                                Expanded(child: ChildView(cubit, pageIndex: 0)),
                              ],
                            ],
                          ),
                        ),
                        // Sunday tab
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              if (userTypeEnum == UserType.priest) ...[
                                Expanded(
                                  child: PriestView(cubit, pageIndex: 1),
                                ),
                              ] else if (userTypeEnum ==
                                  UserType.superServant) ...[
                                Expanded(
                                  child: SuperServantView(
                                    cubit,
                                    pageIndex: 1,
                                    gender: genderToJson(genderEnum),
                                  ),
                                ),
                              ] else if (userTypeEnum == UserType.servant) ...[
                                Expanded(
                                  child: ServantView(
                                    cubit: cubit,
                                    pageIndex: 1,
                                  ),
                                ),
                              ] else ...[
                                Expanded(child: ChildView(cubit, pageIndex: 1)),
                              ],
                            ],
                          ),
                        ),
                        // Hymns tab
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              if (userTypeEnum == UserType.priest) ...[
                                Expanded(
                                  child: PriestView(cubit, pageIndex: 2),
                                ),
                              ] else if (userTypeEnum ==
                                  UserType.superServant) ...[
                                Expanded(
                                  child: SuperServantView(
                                    cubit,
                                    pageIndex: 2,
                                    gender: genderToJson(genderEnum),
                                  ),
                                ),
                              ] else if (userTypeEnum == UserType.servant) ...[
                                Expanded(
                                  child: ServantView(
                                    cubit: cubit,
                                    pageIndex: 2,
                                  ),
                                ),
                              ] else ...[
                                Expanded(child: ChildView(cubit, pageIndex: 2)),
                              ],
                            ],
                          ),
                        ),
                        // Bible tab
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              if (userTypeEnum == UserType.priest) ...[
                                Expanded(
                                  child: PriestView(cubit, pageIndex: 3),
                                ),
                              ] else if (userTypeEnum ==
                                  UserType.superServant) ...[
                                Expanded(
                                  child: SuperServantView(
                                    cubit,
                                    pageIndex: 3,
                                    gender: genderToJson(genderEnum),
                                  ),
                                ),
                              ] else if (userTypeEnum == UserType.servant) ...[
                                Expanded(
                                  child: ServantView(
                                    cubit: cubit,
                                    pageIndex: 3,
                                  ),
                                ),
                              ] else ...[
                                Expanded(child: ChildView(cubit, pageIndex: 3)),
                              ],
                            ],
                          ),
                        ),
                        // Visit tab
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Builder(
                            builder: (context) {
                              if (userTypeEnum == UserType.priest) {
                                return VisitPriestView(
                                  users: cubit.users ?? [],
                                  currentUser: cubit.currentUser!,
                                  attendanceCubit: cubit,
                                );
                              } else if (userTypeEnum ==
                                  UserType.superServant) {
                                return VisitSuperServantView(
                                  users: cubit.users ?? [],
                                  currentUser: cubit.currentUser!,
                                  attendanceCubit: cubit,
                                );
                              } else if (userTypeEnum == UserType.servant) {
                                return VisitServantView(
                                  users: cubit.users ?? [],
                                  currentUser: cubit.currentUser!,
                                  attendanceCubit: cubit,
                                );
                              } else {
                                return VisitChildView(
                                  currentUser: cubit.currentUser!,
                                  attendanceCubit: cubit,
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    );
                  },
                  fallback: (BuildContext context) => Center(
                    child: snapshot.connectionState == ConnectionState.waiting
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Modern loading indicator with decorative container
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: teal100,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: teal300.withValues(alpha: 0.3),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: SizedBox(
                                    width: 50,
                                    height: 50,
                                    child: CircularProgressIndicator(
                                      color: teal500,
                                      strokeWidth: 4,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              Text(
                                'جاري التحميل...',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: teal900,
                                  fontFamily: 'Alexandria',
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'يرجى الانتظار',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontFamily: 'Alexandria',
                                ),
                              ),
                            ],
                          )
                        : snapshot.hasError
                        ? Container(
                            margin: const EdgeInsets.all(24.0),
                            padding: const EdgeInsets.all(24.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.error_outline,
                                    size: 50,
                                    color: Colors.red[400],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'حدث خطأ!',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red[700],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'حدث خطأ أثناء تحميل البيانات',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      // Trigger a rebuild to retry loading
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.refresh,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    'إعادة المحاولة',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: teal500,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 4,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _buildEmptyState(),
                  ),
                ),
                floatingActionButton: userTypeEnum == UserType.child
                    ? FloatingActionButton(
                        backgroundColor: teal500,
                        onPressed: () async {
                          final attendanceKey = await showModalBottomSheet<String>(
                            context: context,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            builder: (context) {
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [teal500, teal100],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(30),
                                    topRight: Radius.circular(30),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: teal500.withValues(alpha: 0.2),
                                      blurRadius: 20,
                                      offset: const Offset(0, -5),
                                    ),
                                  ],
                                ),
                                child: SafeArea(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Handle bar
                                      Container(
                                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                                        width: 40,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade300,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                      // Title
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [teal500, teal300],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Icon(Icons.event_note, color: Colors.white, size: 24),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                'اختر نوع الخدمة',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: teal900,
                                                  fontFamily: 'Alexandria',
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Divider(height: 1),
                                      const SizedBox(height: 8),
                                      // Options
                                      _buildServiceOption(
                                        context,
                                        icon: Icons.church,
                                        title: holyMass,
                                        color: Colors.purple,
                                        onTap: () => Navigator.pop(context, 'holy_mass'),
                                      ),
                                      _buildServiceOption(
                                        context,
                                        icon: Icons.school,
                                        title: sunday,
                                        color: Colors.blue,
                                        onTap: () => Navigator.pop(context, 'sunday_school'),
                                      ),
                                      _buildServiceOption(
                                        context,
                                        icon: Icons.music_note,
                                        title: hymns,
                                        color: Colors.orange,
                                        onTap: () => Navigator.pop(context, 'hymns'),
                                      ),
                                      _buildServiceOption(
                                        context,
                                        icon: Icons.menu_book,
                                        title: bibleClass,
                                        color: Colors.green,
                                        onTap: () => Navigator.pop(context, 'bible'),
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );

                          if (attendanceKey == null) return;

                          final selectedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(DateTime.now().year - 1),
                            lastDate: DateTime.now(),
                          );

                          if (selectedDate == null) return;

                          await cubit.submitAttendanceRequest(
                            attendanceKey: attendanceKey,
                            date: selectedDate,
                          );

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'تم إرسال الطلب وسيظهر في السجل كـ قيد المراجعة',
                                  style: TextStyle(fontFamily: 'Alexandria'),
                                ),
                                backgroundColor: teal500,
                              ),
                            );
                          }
                        },
                        child: const Icon(Icons.add, color: Colors.white),
                      )
                    : null,
              );
            },
          );
        },
        listener: (BuildContext context, state) {
          if (state is takeAttendanceSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'تم حفظ الحضور بنجاح على الخادم',
                        style: TextStyle(
                          fontFamily: 'Alexandria',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: EdgeInsets.all(16),
                duration: Duration(seconds: 3),
              ),
            );
          } else if (state is takeAttendanceSuccessOffline) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.offline_bolt, color: Colors.white),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'تم حفظ الحضور محلياً',
                            style: TextStyle(
                              fontFamily: 'Alexandria',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'سيتم مزامنة البيانات مع الخادم عند توفر الإنترنت',
                      style: TextStyle(
                        fontFamily: 'Alexandria',
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    if (state.pendingCount > 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'عدد السجلات المعلقة: ${state.pendingCount}',
                          style: TextStyle(
                            fontFamily: 'Alexandria',
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                  ],
                ),
                backgroundColor: Colors.orange[700],
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: EdgeInsets.all(16),
                duration: Duration(seconds: 5),
              ),
            );
          } else if (state is SyncComplete) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.cloud_done, color: Colors.white),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'تمت المزامنة بنجاح! (${state.syncedCount} سجل)',
                        style: TextStyle(
                          fontFamily: 'Alexandria',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: teal500,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: EdgeInsets.all(16),
                duration: Duration(seconds: 3),
              ),
            );
          } else if (state is SyncPartiallyComplete) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: Colors.white),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'مزامنة جزئية',
                            style: TextStyle(
                              fontFamily: 'Alexandria',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'تم: ${state.syncedCount} • فشل: ${state.failedCount}',
                      style: TextStyle(
                        fontFamily: 'Alexandria',
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.orange[800],
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: EdgeInsets.all(16),
                duration: Duration(seconds: 4),
              ),
            );
          } else if (state is OfflineModeActive) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.wifi_off, color: Colors.white),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        state.pendingCount > 0
                            ? 'وضع عدم الاتصال (${state.pendingCount} معلق)'
                            : 'وضع عدم الاتصال',
                        style: TextStyle(
                          fontFamily: 'Alexandria',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.grey[700],
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: EdgeInsets.all(16),
                duration: Duration(seconds: 3),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    if (widget.userType == UserType.child) {
      return Container(
        margin: const EdgeInsets.all(24.0),
        padding: const EdgeInsets.all(32.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, teal100.withValues(alpha: 0.3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: teal300.withValues(alpha: 0.2),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: teal100,
                shape: BoxShape.circle,
                border: Border.all(color: teal300, width: 3),
              ),
              child: Icon(Icons.history_edu_outlined, size: 50, color: teal700),
            ),
            const SizedBox(height: 24),
            Text(
              'لا توجد سجلات',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: teal900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'لم يتم العثور على أي سجلات\nلحضورك في هذه الفئة',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        margin: const EdgeInsets.all(24.0),
        padding: const EdgeInsets.all(32.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, teal100.withValues(alpha: 0.3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: teal300.withValues(alpha: 0.2),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: teal100,
                shape: BoxShape.circle,
                border: Border.all(color: teal300, width: 3),
              ),
              child: Icon(Icons.people_outline, size: 50, color: teal700),
            ),
            const SizedBox(height: 24),
            Text(
              'لا يوجد مستخدمين',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: teal900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'لم يتم العثور على أي ��ستخدمين\nفي هذه الفئة',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildServiceOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Colors.white, color.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: teal900,
                      fontFamily: 'Alexandria',
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: color, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
