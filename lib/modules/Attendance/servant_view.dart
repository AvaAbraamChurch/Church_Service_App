import 'package:church/core/constants/functions.dart';
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

class _ServantViewState extends State<ServantView> with SingleTickerProviderStateMixin {
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
            .where((user) => normalizeArabic(user.fullName.toLowerCase()).contains(query))
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
    return Column(
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
        const SizedBox(height: 8),
        // Children list
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: filteredUsers.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12.0),
            itemBuilder: (context, index) {
              final user = filteredUsers[index];
              final userId = user.id;
              final isPresent = attendanceMap[userId] == AttendanceStatus.present;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.0),
                  gradient: LinearGradient(
                    colors: isPresent
                        ? [teal500, teal300]
                        : [Colors.white, teal300.withValues(alpha: 0.3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isPresent
                          ? teal500.withValues(alpha: 0.4)
                          : Colors.black.withValues(alpha: 0.1),
                      spreadRadius: isPresent ? 2 : 0,
                      blurRadius: isPresent ? 12 : 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _toggleAttendanceStatus(userId);
                      });
                    },
                    borderRadius: BorderRadius.circular(16.0),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          // Avatar with animated border
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isPresent ? Colors.white : brown300,
                                width: isPresent ? 3 : 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isPresent
                                      ? Colors.white.withValues(alpha: 0.5)
                                      : Colors.black.withValues(alpha: 0.2),
                                  spreadRadius: isPresent ? 3 : 1,
                                  blurRadius: 8,
                                ),
                              ],
                              image: const DecorationImage(
                                image: AssetImage('assets/images/man.png'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Name and info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.fullName,
                                  style: TextStyle(
                                    color: isPresent ? Colors.white : teal900,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                AnimatedOpacity(
                                  duration: const Duration(milliseconds: 300),
                                  opacity: isPresent ? 1.0 : 0.6,
                                  child: Text(
                                    isPresent ? 'Present' : 'Tap to mark present',
                                    style: TextStyle(
                                      color: isPresent
                                          ? Colors.white.withValues(alpha: 0.9)
                                          : Colors.grey[600],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Animated check icon
                          AnimatedScale(
                            duration: const Duration(milliseconds: 300),
                            scale: isPresent ? 1.0 : 0.8,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isPresent
                                    ? Colors.white
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isPresent ? Colors.white : teal500,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                isPresent ? Icons.check_circle : Icons.circle_outlined,
                                color: isPresent ? teal700 : teal500,
                                size: 28,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Submit button with modern design
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: isSubmitting
                      ? [Colors.grey, Colors.grey[400]!]
                      : [teal700, teal300],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSubmitting
                        ? Colors.black.withValues(alpha: 0.2)
                        : teal500.withValues(alpha: 0.5),
                    spreadRadius: 1,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isSubmitting ? null : _submitBulkAttendance,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 56,
                    alignment: Alignment.center,
                    child: isSubmitting
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                submit,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
