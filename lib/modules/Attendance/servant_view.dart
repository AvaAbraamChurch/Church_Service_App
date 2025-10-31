import 'package:church/core/constants/functions.dart';
import 'package:church/core/constants/strings.dart';
import 'package:church/core/models/attendance/attendance_model.dart';
import 'package:church/core/styles/colors.dart';
import 'package:church/core/utils/attendance_enum.dart';
import 'package:church/core/utils/userType_enum.dart';
import 'package:church/shared/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/blocs/attendance/attendance_cubit.dart';
import '../../core/models/user/user_model.dart';
import '../../core/services/coupon_points_service.dart';

class ServantView extends StatefulWidget {
  final AttendanceCubit cubit;
  final pageIndex;

  const ServantView({super.key, required this.cubit, required this.pageIndex});

  @override
  State<ServantView> createState() => _ServantViewState();
}

class _ServantViewState extends State<ServantView> with SingleTickerProviderStateMixin {
  final searchController = TextEditingController();
  final Map<String, AttendanceStatus> attendanceMap = {};
  final Map<String, int> userPointsMap = {};
  List<UserModel> filteredUsers = [];
  bool isSubmitting = false;
  final CouponPointsService _pointsService = CouponPointsService();

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
        userPointsMap[user.id] = user.couponPoints;
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

  void _showBulkPointsDialog() {
    final TextEditingController pointsController = TextEditingController();
    final TextEditingController reasonController = TextEditingController(text: 'حضور - ${_getAttendanceTypeName()}');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: teal100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.card_giftcard, color: teal700, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'إضافة نقاط للمخدومين',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'سيتم إضافة النقاط فقط للمخدومين الحاضرين',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: pointsController,
                keyboardType: TextInputType.numberWithOptions(signed: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')),
                ],
                decoration: InputDecoration(
                  labelText: 'عدد النقاط',
                  hintText: 'أدخل عدد النقاط (موجب أو سالب)',
                  prefixIcon: Icon(Icons.add_circle_outline, color: teal500),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: teal500, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'السبب',
                  hintText: 'سبب إضافة النقاط',
                  prefixIcon: Icon(Icons.notes, color: teal500),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: teal500, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: teal50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: teal300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: teal700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'يمكنك إدخال قيم سالبة لخصم النقاط',
                        style: TextStyle(fontSize: 12, color: teal900),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final pointsText = pointsController.text.trim();
              final reason = reasonController.text.trim();

              if (pointsText.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('الرجاء إدخال عدد النقاط'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final points = int.tryParse(pointsText);
              if (points == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('الرجاء إدخال رقم صحيح'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('الرجاء إدخال السبب'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context);
              await _applyBulkPoints(points, reason);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: teal500,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('تطبيق', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _getAttendanceTypeName() {
    switch (widget.pageIndex) {
      case 0:
        return 'القداس';
      case 1:
        return 'مدارس الأحد';
      case 2:
        return 'الترانيم';
      case 3:
        return 'درس الكتاب';
      case 4:
        return 'الافتقاد';
      default:
        return '';
    }
  }

  Future<void> _applyBulkPoints(int points, String reason) async {
    try {
      setState(() => isSubmitting = true);

      // Get only present children
      final presentChildren = attendanceMap.entries
          .where((entry) => entry.value == AttendanceStatus.present)
          .map((entry) => entry.key)
          .where((userId) {
            final user = widget.cubit.users!.firstWhere((u) => u.id == userId);
            return user.userType.code == UserType.child.code;
          })
          .toList();

      if (presentChildren.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا يوجد مخدومين حاضرين لإضافة النقاط لهم'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final result = await _pointsService.bulkSetPoints(
        presentChildren,
        points,
        reason,
        widget.cubit.currentUser?.id ?? 'system',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم ${points >= 0 ? 'إضافة' : 'خصم'} ${points.abs()} نقطة لـ ${result['successCount']} مخدوم بنجاح',
              style: const TextStyle(fontFamily: 'Alexandria'),
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh user points
        for (var userId in presentChildren) {
          final currentPoints = await _pointsService.getUserPoints(userId);
          setState(() {
            userPointsMap[userId] = currentPoints;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تطبيق النقاط: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  void _showIndividualPointsDialog(UserModel user) {
    final TextEditingController pointsController = TextEditingController();
    final TextEditingController reasonController = TextEditingController(text: 'تعديل يدوي');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: teal100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.person, color: teal700, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'النقاط الحالية: ${userPointsMap[user.id] ?? user.couponPoints}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: pointsController,
                keyboardType: TextInputType.numberWithOptions(signed: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')),
                ],
                decoration: InputDecoration(
                  labelText: 'عدد النقاط',
                  hintText: 'أدخل عدد النقاط (موجب أو سالب)',
                  prefixIcon: Icon(Icons.add_circle_outline, color: teal500),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: teal500, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'السبب',
                  hintText: 'سبب التعديل',
                  prefixIcon: Icon(Icons.notes, color: teal500),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: teal500, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final pointsText = pointsController.text.trim();
              final reason = reasonController.text.trim();

              if (pointsText.isEmpty || reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('الرجاء ملء جميع الحقول'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final points = int.tryParse(pointsText);
              if (points == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('الرجاء إدخال رقم صحيح'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context);
              await _applyIndividualPoints(user.id, points, reason);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: teal500,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('تطبيق', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _applyIndividualPoints(String userId, int points, String reason) async {
    try {
      setState(() => isSubmitting = true);

      await _pointsService.setPoints(
        userId,
        points,
        reason,
        widget.cubit.currentUser?.id ?? 'system',
      );

      // Refresh user points
      final currentPoints = await _pointsService.getUserPoints(userId);
      setState(() {
        userPointsMap[userId] = currentPoints;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم ${points >= 0 ? 'إضافة' : 'خصم'} ${points.abs()} نقطة بنجاح',
              style: const TextStyle(fontFamily: 'Alexandria'),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تطبيق النقاط: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
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
          attendanceType: widget.pageIndex == 0 ? holyMass : widget.pageIndex == 1 ? sunday : widget.pageIndex == 2 ? hymns : widget.pageIndex == 3 ? bibleClass : widget.pageIndex == 4 ? visit : '',
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
            content: Text(
              'تم تسجيل الحضور بنجاح لـ ${attendanceList.length} مستخدم',
              style: TextStyle(fontFamily: 'Alexandria'),
            ),
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
                                    isPresent ? 'حاضر' : 'اضغط لتسجيل الحضور',
                                    style: TextStyle(
                                      color: isPresent
                                          ? Colors.white.withValues(alpha: 0.9)
                                          : Colors.grey[600],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      fontFamily: 'Alexandria',
                                    ),
                                  ),
                                ),
                                // Show points for children
                                if (user.userType.code == UserType.child.code) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.card_giftcard,
                                        size: 14,
                                        color: isPresent ? Colors.white.withValues(alpha: 0.8) : teal500,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${userPointsMap[user.id] ?? user.couponPoints} نقطة',
                                        style: TextStyle(
                                          color: isPresent ? Colors.white.withValues(alpha: 0.8) : teal700,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Points edit button for children
                          if (user.userType.code == UserType.child.code)
                            IconButton(
                              onPressed: () => _showIndividualPointsDialog(user),
                              icon: Icon(
                                Icons.edit,
                                color: isPresent ? Colors.white : teal500,
                                size: 20,
                              ),
                              tooltip: 'تعديل النقاط',
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
        // Bulk points button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isSubmitting ? null : _showBulkPointsDialog,
              style: OutlinedButton.styleFrom(
                foregroundColor: teal700,
                side: BorderSide(color: teal500, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: Icon(Icons.card_giftcard, color: teal700, size: 22),
              label: const Text(
                'إضافة نقاط للحاضرين',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Alexandria',
                ),
              ),
            ),
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
                                  fontFamily: 'Alexandria',
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
