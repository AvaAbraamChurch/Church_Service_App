import 'package:church/core/blocs/attendance/attendance_cubit.dart';
import 'package:church/core/constants/functions.dart';
import 'package:church/core/constants/strings.dart';
import 'package:church/core/models/attendance/attendance_model.dart';
import 'package:church/core/models/user/user_model.dart';
import 'package:church/core/styles/colors.dart';
import 'package:church/core/utils/attendance_enum.dart';
import 'package:church/core/utils/userType_enum.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/coupon_points_service.dart';

class SuperServantView extends StatefulWidget {
  final AttendanceCubit cubit;
  final int pageIndex;
  final String gender;

  const SuperServantView(
    this.cubit, {
    super.key,
    required this.gender,
    required this.pageIndex,
  });

  @override
  State<SuperServantView> createState() => _SuperServantViewState();
}

class _SuperServantViewState extends State<SuperServantView> {
  // Step 1: User type selection
  String? selectedUserType;

  // Step 2: User attendance tracking
  final Map<String, AttendanceStatus> attendanceMap = {};
  final Map<String, int> userPointsMap = {};

  // Local copy of loaded users based on selected type and gender
  List<UserModel> _loadedUsers = [];
  List<UserModel> filteredUsers = [];
  List<UserModel> servantsList = [];
  List<UserModel> chidrenList = [];
  final searchController = TextEditingController();
  bool isSubmitting = false;
  final CouponPointsService _pointsService = CouponPointsService();

  // Loading indicator for fetching users based on selected type and gender
  bool isLoadingUsers = false;

  @override
  void initState() {
    super.initState();
    searchController.addListener(_filterUsers);

    servantsList =
        widget.cubit.users
            ?.where((u) => u.userType.code == UserType.servant.code)
            .toList() ??
        [];
    chidrenList =
        widget.cubit.users
            ?.where((u) => u.userType.code == UserType.child.code)
            .toList() ??
        [];
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _initializeAttendanceFrom(List<UserModel> users) {
    attendanceMap.clear();
    userPointsMap.clear();
    for (var user in users) {
      attendanceMap[user.id] = AttendanceStatus.absent;
      userPointsMap[user.id] = user.couponPoints;
    }
    _loadedUsers = List<UserModel>.from(users);
    filteredUsers = List.from(widget.cubit.users!);

    servantsList =
        widget.cubit.users
            ?.where((u) => u.userType.code == UserType.servant.code)
            .toList() ??
        [];
    chidrenList =
        widget.cubit.users
            ?.where((u) => u.userType.code == UserType.child.code)
            .toList() ??
        [];
  }

  void _filterUsers() {
    final query = normalizeArabic(searchController.text.toLowerCase());
    setState(() {
      if (query.isEmpty) {
        filteredUsers = List.from(widget.cubit.users ?? []);
      } else {
        filteredUsers = widget.cubit.users!
            .where(
              (user) =>
                  normalizeArabic(user.fullName.toLowerCase()).contains(query),
            )
            .toList();
      }
    });
  }

  String _getAttendanceTypeFromIndex(int index) {
    switch (index) {
      case 0:
        return holyMass;
      case 1:
        return sunday;
      case 2:
        return hymns;
      case 3:
        return bibleClass;
      case 4:
        return visit;
      default:
        return '';
    }
  }

  Future<void> _submitAttendance() async {
    setState(() {
      isSubmitting = true;
    });

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final attendanceList = attendanceMap.entries.map((entry) {
        final user = _loadedUsers.firstWhere((u) => u.id == entry.key);

        return AttendanceModel(
          id: '',
          userId: user.id,
          userName: user.fullName,
          userType: user.userType,
          date: today,
          attendanceType: _getAttendanceTypeFromIndex(widget.pageIndex),
          status: entry.value,
          checkInTime: entry.value == AttendanceStatus.present
              ? now
              : entry.value == AttendanceStatus.late
              ? now
              : null,
          createdAt: now,
        );
      }).toList();

      await widget.cubit.batchTakeAttendance(attendanceList);

      if (mounted) {
        setState(() {
          attendanceMap.clear();
          selectedUserType = null;
          _loadedUsers = [];
          filteredUsers = [];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم تسجيل الحضور بنجاح لـ ${attendanceList.length} مستخدم',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تسجيل الحضور: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
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

  void _showBulkPointsDialog() {
    final TextEditingController pointsController = TextEditingController();
    final TextEditingController reasonController = TextEditingController(text: 'حضور - ${_getAttendanceTypeFromIndex(widget.pageIndex)}');

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

  Future<void> _applyBulkPoints(int points, String reason) async {
    try {
      setState(() => isSubmitting = true);

      // Get only present children
      final presentChildren = attendanceMap.entries
          .where((entry) => entry.value == AttendanceStatus.present)
          .map((entry) => entry.key)
          .where((userId) {
            final user = _loadedUsers.firstWhere((u) => u.id == userId);
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

  @override
  Widget build(BuildContext context) {
    // Step 1: User type selection
    if (selectedUserType == null) {
      return _buildUserTypeSelection();
    }

    // Step 2: Attendance taking
    return _buildAttendanceTaking(
      selectedUserType == UserType.servant.code
          ? UserType.servant
          : UserType.child,
    );
  }

  Widget _buildUserTypeSelection() {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [teal500, teal300],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: teal500.withValues(alpha: 0.3),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.how_to_reg,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'تسجيل الحضور',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'اختر نوع المستخدمين',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),

        // User type cards
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildUserTypeCard(
                title: 'الخدام',
                subtitle: 'تسجيل حضور الخدام',
                icon: Icons.people,
                color: red500,
                userType: UserType.servant.code,
                count:
                    widget.cubit.users
                        ?.where((u) => u.userType.code == UserType.servant.code)
                        .length ??
                    0,
              ),
              const SizedBox(height: 16),
              _buildUserTypeCard(
                title: 'المخدومين',
                subtitle: 'تسجيل حضور المخدومين',
                icon: Icons.child_care,
                color: sage500,
                userType: UserType.child.code,
                count:
                    widget.cubit.users
                        ?.where((u) => u.userType.code == UserType.child.code)
                        .length ??
                    0,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserTypeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String userType,
    required int count,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [Colors.white, color.withValues(alpha: 0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            setState(() {
              selectedUserType = userType;
              servantsList =
                  widget.cubit.users
                      ?.where((u) => u.userType.code == UserType.servant.code)
                      .toList() ??
                  [];
              chidrenList =
                  widget.cubit.users
                      ?.where((u) => u.userType.code == UserType.child.code)
                      .toList() ??
                  [];
              isLoadingUsers = true;
            });

            try {
              if (!mounted) return;
              _initializeAttendanceFrom(
                selectedUserType == UserType.servant.code
                    ? servantsList
                    : chidrenList,
              );
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تمعتذر تحميل المستخدمين: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            } finally {
              if (mounted) {
                setState(() {
                  isLoadingUsers = false;
                });
              }
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(icon, color: color, size: 35),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: teal900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$count مستخدم',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: color, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceTaking(UserType userType) {
    return Column(
      children: [
        // Header with back button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: teal100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    selectedUserType = null;
                    attendanceMap.clear();
                    searchController.clear();
                    _loadedUsers = [];
                    filteredUsers = [];
                    servantsList = [];
                    chidrenList = [];
                  });
                },
                icon: const Icon(Icons.arrow_back, color: teal900),
              ),
              Expanded(
                child: Text(
                  selectedUserType == UserType.servant.code
                      ? 'الخدام'
                      : 'المخدومين',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: teal900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: teal300,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${userType.code == UserType.servant.code ? servantsList.length : chidrenList.length} مستخدم',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: searchController,
              enabled: !isLoadingUsers,
              decoration: InputDecoration(
                hintText: 'بحث...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.search, color: teal500),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Users list
        Expanded(
          child: isLoadingUsers
              ? const Center(
                  child: SizedBox(
                    height: 32,
                    width: 32,
                    child: CircularProgressIndicator(),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: userType.code == UserType.servant.code
                      ? servantsList.length
                      : chidrenList.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final user = userType.code == UserType.servant.code
                        ? servantsList[index]
                        : chidrenList[index];
                    final userId = user.id;
                    final status =
                        attendanceMap[userId] ?? AttendanceStatus.absent;

                    return _buildUserAttendanceCard(user, status);
                  },
                ),
        ),

        // Bulk points button (only for children)
        if (userType.code == UserType.child.code)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: (isSubmitting || isLoadingUsers) ? null : _showBulkPointsDialog,
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
        // Submit button
        Padding(
          padding: const EdgeInsets.all(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: (isSubmitting || isLoadingUsers)
                    ? [Colors.grey, Colors.grey[400]!]
                    : [teal700, teal300],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isSubmitting || isLoadingUsers)
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
                onTap: (isSubmitting || isLoadingUsers)
                    ? null
                    : _submitAttendance,
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
                              'حفظ الحضور',
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
      ],
    );
  }

  Widget _buildUserAttendanceCard(UserModel user, AttendanceStatus status) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case AttendanceStatus.present:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'حاضر';
        break;
      case AttendanceStatus.absent:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'غائب';
        break;
      case AttendanceStatus.late:
        statusColor = Colors.orange;
        statusIcon = Icons.access_time;
        statusText = 'متأخر';
        break;
      case AttendanceStatus.excused:
        statusColor = Colors.blue;
        statusIcon = Icons.info;
        statusText = 'معتذر';
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Colors.white, statusColor.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.15),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: statusColor, width: 2),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/man.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Name and current status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: teal900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, size: 14, color: statusColor),
                              const SizedBox(width: 4),
                              Text(
                                statusText,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Show points for children
                        if (user.userType.code == UserType.child.code) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.card_giftcard, size: 14, color: teal500),
                              const SizedBox(width: 4),
                              Text(
                                '${userPointsMap[user.id] ?? user.couponPoints} نقطة',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: teal700,
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
                      icon: Icon(Icons.edit, color: teal500, size: 20),
                      tooltip: 'تعديل النقاط',
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Status selection buttons
              Row(
                children: [
                  Expanded(
                    child: _buildStatusButton(
                      label: 'حاضر',
                      icon: Icons.check_circle,
                      color: Colors.green,
                      isSelected: status == AttendanceStatus.present,
                      onTap: () {
                        setState(() {
                          attendanceMap[user.id] = AttendanceStatus.present;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatusButton(
                      label: 'غائب',
                      icon: Icons.cancel,
                      color: Colors.red,
                      isSelected: status == AttendanceStatus.absent,
                      onTap: () {
                        setState(() {
                          attendanceMap[user.id] = AttendanceStatus.absent;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatusButton(
                      label: 'متأخر',
                      icon: Icons.access_time,
                      color: Colors.orange,
                      isSelected: status == AttendanceStatus.late,
                      onTap: () {
                        setState(() {
                          attendanceMap[user.id] = AttendanceStatus.late;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatusButton(
                      label: 'معتذر',
                      icon: Icons.info,
                      color: Colors.blue,
                      isSelected: status == AttendanceStatus.excused,
                      onTap: () {
                        setState(() {
                          attendanceMap[user.id] = AttendanceStatus.excused;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: isSelected ? color : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? color : color.withValues(alpha: 0.3),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(icon, color: isSelected ? Colors.white : color, size: 20),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
