import 'package:church/core/constants/strings.dart';
import 'package:church/core/models/attendance/attendance_model.dart';
import 'package:church/core/styles/colors.dart';
import 'package:church/core/utils/attendance_enum.dart';
import 'package:church/shared/widgets.dart';
import 'package:flutter/material.dart';

import '../../core/blocs/attendance/attendance_cubit.dart';
import '../../core/models/user/user_model.dart';

class ServantView extends StatefulWidget {
  final AttendanceCubit cubit;
  final pageIndex;

  const ServantView({Key? key, required this.cubit, required this.pageIndex}) : super(key: key);

  @override
  State<ServantView> createState() => _ServantViewState();
}

class _ServantViewState extends State<ServantView> {
  final searchController = TextEditingController();
  final Map<String, AttendanceStatus> attendanceMap = {};
  List<UserModel> filteredUsers = [];
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initializeAttendance();
    searchController.addListener(_filterUsers);
  }

  void _initializeAttendance() {
    if (widget.cubit.users != null) {
      for (var user in widget.cubit.users!) {
        attendanceMap[user.id] = AttendanceStatus.absent;
      }
      filteredUsers = List.from(widget.cubit.users!);
    }
  }

  void _filterUsers() {
    final query = searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredUsers = List.from(widget.cubit.users!);
      } else {
        filteredUsers = widget.cubit.users!
            .where((user) => user.fullName.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  void _toggleAttendanceStatus(String userId) {
    setState(() {
      final current = attendanceMap[userId]!;
      attendanceMap[userId] = current == AttendanceStatus.absent
          ? AttendanceStatus.present
          : AttendanceStatus.absent;
    });
  }

  void _clearAllAttendance() {
    setState(() {
      for (var userId in attendanceMap.keys) {
        attendanceMap[userId] = AttendanceStatus.absent;
      }
    });
  }

  Future<void> _submitBulkAttendance() async {
    setState(() {
      isSubmitting = true;
    });

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final attendanceList = attendanceMap.entries.map((entry) {
        final user = widget.cubit.users!.firstWhere((u) => u.id == entry.key);

        return AttendanceModel(
          id: '',
          userId: user.id,
          userName: user.fullName,
          userType: user.userType,
          date: today,
          attendanceType: widget.pageIndex == 0 ? holyMass : widget.pageIndex == 1 ? sunday : widget.pageIndex == 2 ? hymns : widget.pageIndex == 3 ? bibleClass : '',
          status: entry.value,
          checkInTime: entry.value == AttendanceStatus.present ? now : null,
          createdAt: now,
        );
      }).toList();

      await widget.cubit.batchTakeAttendance(attendanceList);

      if (mounted) {
        // Clear all checked items after successful submission
        setState(() {
          _clearAllAttendance();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Attendance submitted successfully for ${attendanceList.length} users'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting attendance: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: coloredTextField(
              controller: searchController,
              hintColor: Colors.grey,
              labelColor: Colors.black,
              hintText: search,
              prefixIcon: Icons.search,
              prefixIconColor: Colors.grey,
              label: search,
            ),
          ),
          // Separator
          SizedBox(height: MediaQuery.of(context).size.height * 0.03,),
          // Children list
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * 0.5,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: filteredUsers.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10.0),
              itemBuilder: (context, index) {
                final user = filteredUsers[index];
                final userId = user.id;
                final isPresent = attendanceMap[userId] == AttendanceStatus.absent;
                return ListTile(
                  onTap: () {
                    setState(() {
                      _toggleAttendanceStatus(userId);
                    });
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50.0),
                  ),
                  tileColor: teal300,
                  title: Text(
                    user.fullName,
                    style: TextStyle(color: teal900),
                  ),
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
                          offset: const Offset(0, 3),
                        ),
                      ],
                      image: const DecorationImage(
                        image: AssetImage('assets/images/man.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  trailing: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.15,
                    child: Icon(
                      Icons.check_circle,
                      color: isPresent ? Colors.white : teal900,
                    ),
                  ),
                );
              },
            ),
          ),
          // Submit button
          ElevatedButton(
            onPressed: isSubmitting ? null : _submitBulkAttendance,
            style: ElevatedButton.styleFrom(
              backgroundColor: teal500,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    submit,
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }
}
