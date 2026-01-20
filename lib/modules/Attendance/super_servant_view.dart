import 'package:church/core/blocs/attendance/attendance_cubit.dart';
import 'package:church/core/constants/functions.dart';
import 'package:church/core/constants/strings.dart';
import 'package:church/core/models/attendance/attendance_model.dart';
import 'package:church/core/models/user/user_model.dart';
import 'package:church/core/styles/colors.dart';
import 'package:church/core/utils/attendance_enum.dart';
import 'package:church/core/utils/userType_enum.dart';
import 'package:church/core/utils/gender_enum.dart';
import 'package:church/shared/avatar_display_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/coupon_points_service.dart';
import '../../core/repositories/attendance_defaults_repository.dart';
import '../../shared/points_sync_widget.dart';

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
  String? selectedUserType;
  final Map<String, AttendanceStatus> attendanceMap = {};
  final Map<String, int> userPointsMap = {};

  List<UserModel> _loadedUsers = [];
  List<UserModel> filteredUsers = [];
  List<UserModel> servantsList = [];
  List<UserModel> chidrenList = [];
  final searchController = TextEditingController();
  bool isSubmitting = false;
  final CouponPointsService _pointsService = CouponPointsService();
  final AttendanceDefaultsRepository _defaultsRepo = AttendanceDefaultsRepository();

  bool isLoadingUsers = false;

  String? selectedClass;
  String? selectedGender;
  List<String> availableClasses = [];

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

    final classes = users.map((u) => u.userClass).toSet().toList();
    classes.sort();
    availableClasses = ['الكل', ...classes];

    selectedClass = 'الكل';
    selectedGender = 'الكل';

    filteredUsers = List<UserModel>.from(users);
  }

  void _filterUsers() {
    final query = normalizeArabic(searchController.text.toLowerCase());
    setState(() {
      final sourceList = selectedUserType == UserType.servant.code
          ? servantsList
          : chidrenList;

      List<UserModel> tempFiltered = List.from(sourceList);

      if (selectedClass != null && selectedClass != 'الكل') {
        tempFiltered = tempFiltered.where((user) => user.userClass == selectedClass).toList();
      }

      if (selectedGender != null && selectedGender != 'الكل') {
        final genderCode = selectedGender == 'ذكر' ? 'M' : 'F';
        tempFiltered = tempFiltered.where((user) => user.gender.code == genderCode).toList();
      }

      if (query.isEmpty) {
        filteredUsers = tempFiltered;
      } else {
        filteredUsers = tempFiltered
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

  String _getAttendanceTypeName() {
    switch (widget.pageIndex) {
      case 0:
        return 'القداس';
      case 1:
        return 'مدارس الأحد';
      case 2:
        return 'الالحان';
      case 3:
        return 'درس الكتاب';
      case 4:
        return 'الافتقاد';
      default:
        return '';
    }
  }

  int _getDefaultPointsForType(Map<String, int> defaults) {
    switch (widget.pageIndex) {
      case 0:
        return defaults['holy_mass'] ?? 1;
      case 1:
        return defaults['sunday_school'] ?? 1;
      case 2:
        return defaults['hymns'] ?? 1;
      case 3:
        return defaults['bible'] ?? 1;
      case 4:
        return 1;
      default:
        return 1;
    }
  }

  Future<void> _submitAttendance() async {
    debugPrint('🟢 [SuperServantView] _submitAttendance called');

    if (isSubmitting) {
      debugPrint('⚠️ [SuperServantView] Already submitting, ignoring duplicate call');
      return;
    }

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

      debugPrint('🟢 [SuperServantView] Calling cubit.batchTakeAttendance with ${attendanceList.length} items');
      await widget.cubit.batchTakeAttendance(attendanceList);
      debugPrint('🟢 [SuperServantView] batchTakeAttendance completed');

      // Add points automatically for present children
      final defaults = await _defaultsRepo.getDefaults();
      final defaultPoints = _getDefaultPointsForType(defaults);

      final presentChildren = attendanceMap.entries
          .where((entry) => entry.value == AttendanceStatus.present)
          .map((entry) => entry.key)
          .where((userId) {
        final user = _loadedUsers.firstWhere((u) => u.id == userId);
        return user.userType.code == UserType.child.code;
      })
          .toList();

      if (presentChildren.isNotEmpty) {
        debugPrint('🟢 [SuperServantView] Adding points to ${presentChildren.length} present children');

        final result = await _pointsService.bulkSetPoints(
          presentChildren,
          defaultPoints,
          'حضور - ${_getAttendanceTypeName()}',
          widget.cubit.currentUser?.id ?? 'system',
        );

        debugPrint('🟢 [SuperServantView] Points added successfully to ${result['successCount']} children');
      }

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
              presentChildren.isNotEmpty
                  ? 'تم تسجيل الحضور وإضافة $defaultPoints نقطة لـ ${presentChildren.length} مخدوم'
                  : 'تم تسجيل الحضور بنجاح',
              style: const TextStyle(fontFamily: 'Alexandria'),
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
      debugPrint('❌ [SuperServantView] Error in _submitAttendance: $e');
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
        debugPrint('🟢 [SuperServantView] Setting isSubmitting = false');
        setState(() {
          isSubmitting = false;
        });
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
    if (selectedUserType == null) {
      return _buildUserTypeSelection();
    }

    return _buildAttendanceTaking(
      selectedUserType == UserType.servant.code
          ? UserType.servant
          : UserType.child,
    );
  }

  Widget _buildUserTypeSelection() {
    return Column(
      children: [
        const PointsSyncStatusWidget(),
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
                    content: Text('تعذر تحميل المستخدمين: $e'),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

        return Column(
          children: [
            const PointsSyncStatusWidget(),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: teal100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  if (!keyboardVisible)
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
                          selectedClass = null;
                          selectedGender = null;
                          availableClasses = [];
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
                      searchController.text.isEmpty
                          ? '${selectedUserType == UserType.servant.code ? servantsList.length : chidrenList.length} مستخدم'
                          : '${filteredUsers.length} من ${selectedUserType == UserType.servant.code ? servantsList.length : chidrenList.length}',
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
            const SizedBox(height: 12),

            if (!isLoadingUsers && availableClasses.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (availableClasses.length > 1) ...[
                      Row(
                        children: [
                          Icon(Icons.class_, color: teal700, size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'الفصل:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: availableClasses.length,
                          separatorBuilder: (context, index) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final className = availableClasses[index];
                            final isSelected = selectedClass == className;
                            return FilterChip(
                              label: Text(className),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  selectedClass = className;
                                  _filterUsers();
                                });
                              },
                              backgroundColor: Colors.white,
                              selectedColor: teal300,
                              checkmarkColor: Colors.white,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : teal900,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              side: BorderSide(
                                color: isSelected ? teal500 : Colors.grey[300]!,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (widget.cubit.currentUser?.userType.code == UserType.priest.code) ...[
                      Row(
                        children: [
                          Icon(Icons.wc, color: teal700, size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'النوع:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            for (final gender in ['الكل', 'ذكر', 'أنثى']) ...[
                              FilterChip(
                                label: Text(gender),
                                selected: selectedGender == gender,
                                onSelected: (selected) {
                                  setState(() {
                                    selectedGender = gender;
                                    _filterUsers();
                                  });
                                },
                                backgroundColor: Colors.white,
                                selectedColor: teal300,
                                checkmarkColor: Colors.white,
                                labelStyle: TextStyle(
                                  color: selectedGender == gender ? Colors.white : teal900,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                side: BorderSide(
                                  color: selectedGender == gender ? teal500 : Colors.grey[300]!,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 8),

            Flexible(
              child: isLoadingUsers
                  ? const Center(
                child: SizedBox(
                  height: 32,
                  width: 32,
                  child: CircularProgressIndicator(),
                ),
              )
                  : filteredUsers.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'لا توجد نتائج',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredUsers.length,
                separatorBuilder: (context, index) =>
                const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final user = filteredUsers[index];
                  final userId = user.id;
                  final status =
                      attendanceMap[userId] ?? AttendanceStatus.absent;

                  return _buildUserAttendanceCard(user, status);
                },
              ),
            ),

            if (!keyboardVisible)
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
                              'حفظ الحضور وإضافة النقاط',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 1,
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
          ],
        );
      },
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
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: statusColor, width: 2),
                    ),
                    child: AvatarDisplayWidget(
                      user: user,
                      size: 56,
                      showBorder: false,
                      borderWidth: 0,
                    ),
                  ),
                  const SizedBox(width: 16),

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
                  if (user.userType.code == UserType.child.code)
                    IconButton(
                      onPressed: () => _showIndividualPointsDialog(user),
                      icon: Icon(Icons.edit, color: teal500, size: 20),
                      tooltip: 'تعديل النقاط',
                    ),
                ],
              ),
              const SizedBox(height: 16),

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
      )
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



