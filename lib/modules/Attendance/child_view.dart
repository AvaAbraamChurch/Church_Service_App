import 'package:flutter/material.dart';

import '../../core/blocs/attendance/attendance_cubit.dart';

Widget ChildView(AttendanceCubit cubit) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisAlignment: MainAxisAlignment.start,
  children: [
    Text('Child View', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
    SizedBox(height: 10),
    Text('This is the view for priests.'),
    // Add more widgets specific to the priest view here
  ],
);