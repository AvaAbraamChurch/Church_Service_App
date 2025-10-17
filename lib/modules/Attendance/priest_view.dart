import 'package:church/core/blocs/attendance/attendance_cubit.dart';
import 'package:flutter/material.dart';

Widget PriestView(AttendanceCubit cubit) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisAlignment: MainAxisAlignment.start,
  children: [
    Text('Priest View', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
    SizedBox(height: 10),
    Text('This is the view for priests.'),
    // Add more widgets specific to the priest view here
  ],
);