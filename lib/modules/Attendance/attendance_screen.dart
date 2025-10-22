import 'package:church/core/blocs/attendance/attendance_states.dart';
import 'package:church/core/constants/strings.dart';
import 'package:church/core/styles/colors.dart';
import 'package:church/core/utils/userType_enum.dart';
import 'package:church/core/utils/gender_enum.dart';
import 'package:church/modules/Attendance/child_view.dart';
import 'package:church/modules/Attendance/priest_view.dart';
import 'package:church/modules/Attendance/servant_view.dart';
import 'package:church/modules/Attendance/super_servant_view.dart';
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

  @override
  void initState() {
    super.initState();
    cubit = AttendanceCubit();


    final userTypeEnum = widget.userType;
    final genderEnum = widget.gender;

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
      stream = cubit.getUsersByType(
        widget.userClass,
        [userTypeToJson(UserType.child)],
        genderToJson(genderEnum)
      );
    } else if (userTypeEnum == UserType.child) {
      // Get attendance history for children
      stream = cubit.getUserAttendanceHistory(widget.userId);
    }
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
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
                appBar: AppBar(
                  title: Text(
                    attendance,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: teal300,
                  toolbarHeight: MediaQuery.of(context).size.height * 0.1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(60),
                    ),
                  ),
                  bottom: TabBar(
                    onTap: (val){

                    },
                    dividerColor: Colors.transparent,
                    controller: _tabController,
                    indicatorColor: Colors.transparent,
                    indicatorWeight: 3,
                    indicatorAnimation: TabIndicatorAnimation.elastic,
                    indicatorPadding: EdgeInsets.all(5),
                    isScrollable: true,
                    labelColor: teal900,
                    unselectedLabelColor: Colors.white70,
                    tabAlignment: TabAlignment.center,
                    tabs: [
                      Tab(text: holyMass),
                      Tab(text: sunday),
                      Tab(text: hymns),
                      Tab(text: bibleClass),
                    ],
                  ),
                ),
                backgroundColor: Colors.transparent,
                body: ConditionalBuilder(
                  condition: snapshot.hasData &&
                             ((userTypeEnum != UserType.child && cubit.users != null && cubit.users!.isNotEmpty) ||
                              (userTypeEnum == UserType.child && cubit.attendanceHistory != null && cubit.attendanceHistory!.isNotEmpty)),
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
                                Expanded(child: PriestView(cubit, pageIndex: 0)),
                              ] else if (userTypeEnum == UserType.superServant) ...[
                                Expanded(child: SuperServantView(cubit, gender: genderToJson(genderEnum), pageIndex: 0)),
                              ] else if (userTypeEnum == UserType.servant) ...[
                                Expanded(child: ServantView(cubit: cubit, pageIndex: 0)),
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
                                Expanded(child: PriestView(cubit, pageIndex: 1)),
                              ] else if (userTypeEnum == UserType.superServant) ...[
                                Expanded(child: SuperServantView(cubit, pageIndex: 1, gender: genderToJson(genderEnum),)),
                              ] else if (userTypeEnum == UserType.servant) ...[
                                Expanded(child: ServantView(cubit: cubit, pageIndex: 1)),
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
                                Expanded(child: PriestView(cubit, pageIndex: 2)),
                              ] else if (userTypeEnum == UserType.superServant) ...[
                                Expanded(child: SuperServantView(cubit, pageIndex: 2, gender: genderToJson(genderEnum),)),
                              ] else if (userTypeEnum == UserType.servant) ...[
                                Expanded(child: ServantView(cubit: cubit, pageIndex: 2)),
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
                                Expanded(child: PriestView(cubit, pageIndex: 3)),
                              ] else if (userTypeEnum == UserType.superServant) ...[
                                Expanded(child: SuperServantView(cubit, pageIndex: 3, gender: genderToJson(genderEnum))),
                              ] else if (userTypeEnum == UserType.servant) ...[
                                Expanded(child: ServantView(cubit: cubit, pageIndex: 3)),
                              ] else ...[
                                Expanded(child: ChildView(cubit, pageIndex: 3)),
                              ],
                            ],
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
                                      icon: const Icon(Icons.refresh, color: Colors.white),
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
              );
            },
          );
        },
        listener: (BuildContext context, state) {},
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
            colors: [
              Colors.white,
              teal100.withValues(alpha: 0.3),
            ],
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
                border: Border.all(
                  color: teal300,
                  width: 3,
                ),
              ),
              child: Icon(
                Icons.history_edu_outlined,
                size: 50,
                color: teal700,
              ),
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
            colors: [
              Colors.white,
              teal100.withValues(alpha: 0.3),
            ],
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
                border: Border.all(
                  color: teal300,
                  width: 3,
                ),
              ),
              child: Icon(
                Icons.people_outline,
                size: 50,
                color: teal700,
              ),
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
              'لم يتم العثور على أي مستخدمين\nفي هذه الفئة',
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
}
