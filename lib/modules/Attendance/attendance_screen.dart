import 'package:church/core/blocs/attendance/attendance_states.dart';
import 'package:church/core/constants/strings.dart';
import 'package:church/core/styles/colors.dart';
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
  final String userType;
  final String userClass;
  final String gender;

  AttendanceScreen({
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
    if (widget.userType == priest) {
      stream = cubit.getUsersByType(widget.userClass, [
        superServant,
        servant,
        child,
      ], widget.gender).asStream();
    } else if (widget.userType == superServant) {
      stream = cubit.getUsersByType(widget.userClass, [
        servant,
        child,
      ], widget.gender).asStream();
    } else if (widget.userType == servant) {
      stream = cubit.getUsersByType(widget.userClass, [child], widget.gender).asStream();
    } else {
      // Get attendance history for children
      stream = cubit.getUserAttendanceHistory(widget.userId).asStream();
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
                  condition: snapshot.hasData && cubit.users!.isNotEmpty,
                  builder: (BuildContext context) {
                    return TabBarView(
                      controller: _tabController,
                      children: [
                        // Holy Mass tab
                        SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (widget.userType == priest) ...[
                                    PriestView(cubit),
                                  ] else if (widget.userType ==
                                      superServant) ...[
                                    SuperServantView(cubit),
                                  ] else if (widget.userType == servant) ...[
                                    ServantView(cubit: cubit, pageIndex: _tabController.index,),
                                  ] else ...[
                                    ChildView(cubit),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Sunday tab
                        SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (widget.userType == priest) ...[
                                    PriestView(cubit),
                                  ] else if (widget.userType ==
                                      superServant) ...[
                                    SuperServantView(cubit),
                                  ] else if (widget.userType == servant) ...[
                                    ServantView(cubit: cubit, pageIndex: _tabController.index,),
                                  ] else ...[
                                    ChildView(cubit),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Hymns tab
                        SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (widget.userType == priest) ...[
                                    PriestView(cubit),
                                  ] else if (widget.userType ==
                                      superServant) ...[
                                    SuperServantView(cubit),
                                  ] else if (widget.userType == servant) ...[
                                    ServantView(cubit: cubit, pageIndex: _tabController.index,),
                                  ] else ...[
                                    ChildView(cubit),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Bible tab
                        SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (widget.userType == priest) ...[
                                    PriestView(cubit),
                                  ] else if (widget.userType ==
                                      superServant) ...[
                                    SuperServantView(cubit),
                                  ] else if (widget.userType == servant) ...[
                                    ServantView(cubit: cubit, pageIndex: _tabController.index,),
                                  ] else ...[
                                    ChildView(cubit),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                  fallback: (BuildContext context) => Center(
                    child: Text(
                      'No users found.',
                      style: TextStyle(fontSize: 18, color: brown900),
                    ),
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
}
