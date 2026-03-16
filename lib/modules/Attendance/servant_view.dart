import 'package:church/core/constants/functions.dart';
import 'package:church/core/constants/strings.dart';
import 'package:church/core/models/attendance/attendance_model.dart';
import 'package:church/core/styles/colors.dart';
import 'package:church/core/utils/attendance_enum.dart';
import 'package:church/core/utils/userType_enum.dart';
import 'package:church/shared/avatar_display_widget.dart';
import 'package:church/shared/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/blocs/attendance/attendance_cubit.dart';
import '../../core/models/user/user_model.dart';
import '../../core/repositories/attendance_defaults_repository.dart';
import '../../core/services/coupon_points_service.dart';
import '../../shared/points_sync_widget.dart';

class ServantView extends StatefulWidget {
  final AttendanceCubit cubit;
  final int pageIndex;

  const ServantView({super.key, required this.cubit, required this.pageIndex});

  @override
  State<ServantView> createState() => _ServantViewState();
}

class _ServantViewState extends State<ServantView>
    with SingleTickerProviderStateMixin {
  final searchController = TextEditingController();
  final Map<String, Map<String, bool>> attendanceMap =
      {}; // userId -> {attendanceType -> isPresent}
  final Map<String, int> userPointsMap = {};
  List<UserModel> filteredUsers = [];
  bool isSubmitting = false;
  final CouponPointsService _pointsService = CouponPointsService();
  final AttendanceDefaultsRepository _defaultsRepo =
      AttendanceDefaultsRepository();

  List<Map<String, dynamic>> get attendanceTypes => [
    {
      'key': 'holy_mass',
      'label': 'القداس',
      'icon': Icons.church,
      'color': teal500,
      'index': 0,
    },
    {
      'key': 'sunday_school',
      'label': 'مدارس الأحد',
      'icon': Icons.school,
      'color': teal500,
      'index': 1,
    },
    {
      'key': 'hymns',
      'label': 'الألحان',
      'icon': Icons.music_note,
      'color': teal500,
      'index': 2,
    },
    {
      'key': 'bible',
      'label': 'درس الكتاب',
      'icon': Icons.book,
      'color': teal500,
      'index': 3,
    },
    {
      'key': 'visit',
      'label': 'الافتقاد',
      'icon': Icons.home_outlined,
      'color': teal500,
      'index': 4,
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeAttendance();
    searchController.addListener(_filterUsers);
  }

  void _initializeAttendance() {
    if (widget.cubit.users != null) {
      for (var user in widget.cubit.users!) {
        attendanceMap[user.id] = {
          'holy_mass': false,
          'sunday_school': false,
          'hymns': false,
          'bible': false,
          'visit': false,
        };
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
            .where(
              (user) =>
                  normalizeArabic(user.fullName.toLowerCase()).contains(query),
            )
            .toList();
      }
    });
  }

  void _toggleAttendance(String userId, String attendanceKey) {
    setState(() {
      attendanceMap[userId]![attendanceKey] =
          !attendanceMap[userId]![attendanceKey]!;
    });
  }

  bool get _canAdjustCoupons {
    final currentTypeCode = widget.cubit.currentUser?.userType.code;
    return currentTypeCode == UserType.servant.code ||
        currentTypeCode == UserType.superServant.code ||
        currentTypeCode == UserType.priest.code;
  }

  void _showIndividualPointsDialog(UserModel user) {
    if (!_canAdjustCoupons || user.userType.code != UserType.child.code) {
      return;
    }

    final pointsController = TextEditingController();
    final reasonController = TextEditingController(text: 'تعديل يدوي');

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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                ),
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
              await _applyIndividualPoints(user, points, reason);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: teal500,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'تطبيق',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _applyIndividualPoints(
    UserModel user,
    int points,
    String reason,
  ) async {
    if (!_canAdjustCoupons || user.userType.code != UserType.child.code) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('غير مسموح بتعديل النقاط لهذا المستخدم'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      setState(() => isSubmitting = true);

      await _pointsService.setPoints(
        user.id,
        points,
        reason,
        widget.cubit.currentUser?.id ?? 'system',
      );

      final currentPoints = await _pointsService.getUserPoints(user.id);
      setState(() {
        userPointsMap[user.id] = currentPoints;
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

  Future<void> _submitAllAttendance() async {
    if (isSubmitting) return;

    // Show date picker first
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime.now(),
      helpText: 'اختر تاريخ الحضور',
      cancelText: 'إلغاء',
      confirmText: 'تأكيد',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: teal500,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: teal900,
            ),
          ),
          child: child!,
        );
      },
    );

    // If user cancelled date selection, return
    if (selectedDate == null) {
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final now = DateTime.now();
      final attendanceDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );

      // Load default points
      final defaults = await _defaultsRepo.getDefaults();

      List<AttendanceModel> allAttendanceList = [];
      Map<String, int> userPointsToAdd = {}; // userId -> total points

      // Process each user's attendance
      for (var entry in attendanceMap.entries) {
        final userId = entry.key;
        final user = widget.cubit.users!.firstWhere((u) => u.id == userId);
        final userAttendance = entry.value;

        int totalPoints = 0;

        // Check each attendance type
        for (var type in attendanceTypes) {
          final key = type['key'] as String;
          final isPresent = userAttendance[key] ?? false;

          if (isPresent) {
            // Add attendance record
            allAttendanceList.add(
              AttendanceModel(
                id: '',
                userId: user.id,
                userName: user.fullName,
                userType: user.userType,
                date: attendanceDate,
                attendanceType: _getAttendanceTypeString(key),
                status: AttendanceStatus.present,
                checkInTime: now,
                createdAt: now,
              ),
            );

            // Calculate points for children
            if (user.userType.code == UserType.child.code) {
              totalPoints += _getDefaultPointsForType(defaults, key);
            }
          }
        }

        // Store total points to add
        if (totalPoints > 0) {
          userPointsToAdd[userId] = totalPoints;
        }
      }

      // Submit attendance
      if (allAttendanceList.isNotEmpty) {
        await widget.cubit.batchTakeAttendance(allAttendanceList);
      }

      // Add points for all users
      for (var entry in userPointsToAdd.entries) {
        final userId = entry.key;
        final points = entry.value;

        await _pointsService.setPoints(
          userId,
          points,
          'حضور متعدد',
          widget.cubit.currentUser?.id ?? 'system',
        );

        // Update local points
        final currentPoints = await _pointsService.getUserPoints(userId);
        setState(() {
          userPointsMap[userId] = currentPoints;
        });
      }

      if (mounted) {
        // Clear all attendance
        setState(() {
          for (var userId in attendanceMap.keys) {
            attendanceMap[userId] = {
              'holy_mass': false,
              'sunday_school': false,
              'hymns': false,
              'bible': false,
              'visit': false,
            };
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم تسجيل الحضور وإضافة النقاط بنجاح',
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
            content: Text('خطأ في تسجيل الحضور: $e'),
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

  String _getAttendanceTypeString(String key) {
    switch (key) {
      case 'holy_mass':
        return holyMass;
      case 'sunday_school':
        return sunday;
      case 'hymns':
        return hymns;
      case 'bible':
        return bibleClass;
      case 'visit':
        return visit;
      default:
        return '';
    }
  }

  int _getDefaultPointsForType(Map<String, int> defaults, String key) {
    switch (key) {
      case 'holy_mass':
        return defaults['holy_mass'] ?? 1;
      case 'sunday_school':
        return defaults['sunday_school'] ?? 1;
      case 'hymns':
        return defaults['hymns'] ?? 1;
      case 'bible':
        return defaults['bible'] ?? 1;
      case 'visit':
        return 1;
      default:
        return 1;
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the current attendance type based on pageIndex
    final currentType = attendanceTypes.firstWhere(
      (type) => type['index'] == widget.pageIndex,
      orElse: () => attendanceTypes[0],
    );
    final currentKey = currentType['key'] as String;
    final currentLabel = currentType['label'] as String;
    final currentColor = currentType['color'] as Color;

    return Column(
      children: [
        // Points sync widget
        const PointsSyncStatusWidget(),

        // Current attendance type header
        // Container(
        //   margin: const EdgeInsets.all(16.0),
        //   padding: const EdgeInsets.all(16.0),
        //   decoration: BoxDecoration(
        //     gradient: LinearGradient(
        //       colors: [currentColor, currentColor.withValues(alpha: 0.7)],
        //       begin: Alignment.topLeft,
        //       end: Alignment.bottomRight,
        //     ),
        //     borderRadius: BorderRadius.circular(16),
        //     boxShadow: [
        //       BoxShadow(
        //         color: currentColor.withValues(alpha: 0.4),
        //         spreadRadius: 1,
        //         blurRadius: 8,
        //         offset: const Offset(0, 3),
        //       ),
        //     ],
        //   ),
        //   child: Row(
        //     mainAxisAlignment: MainAxisAlignment.center,
        //     children: [
        //       Icon(currentIcon, color: Colors.white, size: 28),
        //       const SizedBox(width: 12),
        //       Text(
        //         'تسجيل حضور $currentLabel',
        //         style: const TextStyle(
        //           color: Colors.white,
        //           fontSize: 20,
        //           fontWeight: FontWeight.bold,
        //           fontFamily: 'Alexandria',
        //         ),
        //       ),
        //     ],
        //   ),
        // ),

        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
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

        const SizedBox(height: 16),

        // Children cards list
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: filteredUsers.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final user = filteredUsers[index];
              final userId = user.id;
              final isPresent = attendanceMap[userId]?[currentKey] ?? false;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  gradient: isPresent
                      ? LinearGradient(
                          colors: [
                            currentColor,
                            currentColor.withValues(alpha: 0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isPresent ? null : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isPresent ? currentColor : Colors.grey[300]!,
                    width: isPresent ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isPresent
                          ? currentColor.withValues(alpha: 0.4)
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
                    onTap: () => _toggleAttendance(userId, currentKey),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          // Avatar
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isPresent
                                    ? Colors.white
                                    : currentColor.withValues(alpha: 0.5),
                                width: 3,
                              ),
                              boxShadow: isPresent
                                  ? [
                                      BoxShadow(
                                        color: Colors.white.withValues(
                                          alpha: 0.5,
                                        ),
                                        spreadRadius: 2,
                                        blurRadius: 8,
                                      ),
                                    ]
                                  : [],
                            ),
                            child: AvatarDisplayWidget(
                              user: user,
                              size: 60,
                              showBorder: false,
                              borderWidth: 0,
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Name and points
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.fullName,
                                  style: TextStyle(
                                    color: isPresent ? Colors.white : teal900,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Alexandria',
                                  ),
                                ),
                                const SizedBox(height: 6),
                                if (user.userType.code ==
                                    UserType.child.code) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isPresent
                                          ? Colors.white.withValues(alpha: 0.25)
                                          : currentColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isPresent
                                            ? Colors.white.withValues(
                                                alpha: 0.5,
                                              )
                                            : currentColor.withValues(
                                                alpha: 0.3,
                                              ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.card_giftcard,
                                          size: 16,
                                          color: isPresent
                                              ? Colors.white
                                              : currentColor,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${userPointsMap[user.id] ?? user.couponPoints} نقطة',
                                          style: TextStyle(
                                            color: isPresent
                                                ? Colors.white
                                                : currentColor,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'Alexandria',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else ...[
                                  Text(
                                    isPresent ? 'حاضر ✓' : 'اضغط للتسجيل',
                                    style: TextStyle(
                                      color: isPresent
                                          ? Colors.white.withValues(alpha: 0.9)
                                          : Colors.grey[600],
                                      fontSize: 13,
                                      fontFamily: 'Alexandria',
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          if (_canAdjustCoupons &&
                              user.userType.code == UserType.child.code)
                            IconButton(
                              onPressed: () =>
                                  _showIndividualPointsDialog(user),
                              icon: Icon(
                                Icons.edit,
                                color: isPresent ? Colors.white : currentColor,
                                size: 22,
                              ),
                              tooltip: 'تعديل النقاط',
                            ),

                          // Check icon
                          AnimatedScale(
                            duration: const Duration(milliseconds: 300),
                            scale: isPresent ? 1.1 : 0.9,
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
                                  color: isPresent
                                      ? Colors.white
                                      : currentColor,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                isPresent
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                color: currentColor,
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

        // Submit button
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
                      : [currentColor, currentColor.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSubmitting
                        ? Colors.black.withValues(alpha: 0.2)
                        : currentColor.withValues(alpha: 0.5),
                    spreadRadius: 1,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isSubmitting ? null : _submitAllAttendance,
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
                              Text(
                                'تسجيل حضور $currentLabel',
                                style: const TextStyle(
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

        // Requests button
        // Padding(
        //   padding: const EdgeInsets.only(top: 12.0),
        //   child: SizedBox(
        //     width: double.infinity,
        //     height: 52,
        //     child: ElevatedButton.icon(
        //       onPressed: () {
        //         Navigator.push(
        //           context,
        //           MaterialPageRoute(
        //             builder: (context) => RequestsScreen(cubit: widget.cubit),
        //           ),
        //         );
        //       },
        //       icon: const Icon(Icons.request_page),
        //       label: const Text(
        //         'الطلبات',
        //         style: TextStyle(fontFamily: 'Alexandria', fontWeight: FontWeight.w600),
        //       ),
        //       style: ElevatedButton.styleFrom(
        //         backgroundColor: teal500,
        //         foregroundColor: Colors.white,
        //         shape: RoundedRectangleBorder(
        //           borderRadius: BorderRadius.circular(14),
        //         ),
        //       ),
        //     ),
        //   ),
        // ),
      ],
    );
  }
}
