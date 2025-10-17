import 'package:church/core/styles/colors.dart';
import 'package:flutter/material.dart';

import '../../core/blocs/attendance/attendance_cubit.dart';

Widget ServantView(context, AttendanceCubit cubit) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisAlignment: MainAxisAlignment.start,
  children: [
    SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: ListView.separated(
          itemCount: cubit.users!.length,
          itemBuilder: (context, index) {
            return SizedBox(
              width: MediaQuery.of(context).size.width,
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50.0),
                ),
                tileColor: teal300,
                style: ListTileStyle.list,
                title: Text(cubit.users!.elementAt(index).fullName, style: TextStyle(color: teal900),),
                leading: Container(
                    width: MediaQuery.of(context).size.width * 0.12,
                    height: MediaQuery.of(context).size.width * 0.12,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(color: brown300, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 3), // changes position of shadow
                        ),
                      ],
                      image: const DecorationImage(
                        image: AssetImage('assets/images/man.png'), // Replace with actual asset path
                        fit: BoxFit.cover,
                      ),
                    )),
                trailing: Icon(Icons.check_circle_outline_rounded, color: Colors.white,),
              ),
            );
          },
          separatorBuilder: (context, index) => SizedBox(height: 10.0,),
      ),
    ),
  ],
);