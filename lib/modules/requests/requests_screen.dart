import 'package:church/core/blocs/attendance/attendance_cubit.dart';
import 'package:church/core/constants/strings.dart';
import 'package:church/core/models/attendance/attendance_request_model.dart';
import 'package:church/core/repositories/attendance_defaults_repository.dart';
import 'package:church/core/styles/colors.dart';
import 'package:church/core/styles/themeScaffold.dart';
import 'package:church/core/utils/userType_enum.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RequestsScreen extends StatefulWidget {
  final AttendanceCubit cubit;

  const RequestsScreen({super.key, required this.cubit});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  final AttendanceDefaultsRepository _defaultsRepo = AttendanceDefaultsRepository();
  Map<String, int> _defaultPoints = {};

  @override
  void initState() {
    super.initState();
    _loadDefaults();
  }

  Future<void> _loadDefaults() async {
    final defaults = await _defaultsRepo.getDefaults();
    if (mounted) {
      setState(() {
        _defaultPoints = defaults;
      });
    }
  }

  int _getPointsForKey(String key) {
    return _defaultPoints[key] ?? 1;
  }

  Future<void> _showSubmitRequestDialog(BuildContext context) async {
    final now = DateTime.now();
    DateTime selectedDate = DateTime(now.year, now.month, now.day);
    String selectedKey = 'holy_mass';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            Future<void> pickDate() async {
              final picked = await showDatePicker(
                context: ctx,
                initialDate: selectedDate,
                firstDate: DateTime(now.year - 1),
                lastDate: now,
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
              if (picked != null) {
                setState(() {
                  selectedDate = DateTime(picked.year, picked.month, picked.day);
                });
              }
            }

            final points = _getPointsForKey(selectedKey);

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: teal100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.add_task, color: teal700, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'طلب حضور جديد',
                      style: TextStyle(fontFamily: 'Alexandria', fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: teal300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: selectedKey,
                      decoration: InputDecoration(
                        labelText: 'نوع الخدمة',
                        labelStyle: TextStyle(color: teal700, fontFamily: 'Alexandria'),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        prefixIcon: Icon(Icons.church, color: teal500),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'holy_mass', child: Text(holyMass, style: TextStyle(fontFamily: 'Alexandria'))),
                        DropdownMenuItem(value: 'sunday_school', child: Text(sunday, style: TextStyle(fontFamily: 'Alexandria'))),
                        DropdownMenuItem(value: 'hymns', child: Text(hymns, style: TextStyle(fontFamily: 'Alexandria'))),
                        DropdownMenuItem(value: 'bible', child: Text(bibleClass, style: TextStyle(fontFamily: 'Alexandria'))),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => selectedKey = v);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: teal300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: teal500, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'التاريخ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: teal700,
                                  fontFamily: 'Alexandria',
                                ),
                              ),
                              Text(
                                DateFormat('yyyy-MM-dd', 'ar').format(selectedDate),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Alexandria',
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: pickDate,
                          icon: Icon(Icons.edit, size: 18, color: teal500),
                          label: Text('تغيير', style: TextStyle(color: teal500, fontFamily: 'Alexandria')),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [teal50, Colors.green.shade50],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.stars, color: Colors.green.shade700, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'النقاط المكتسبة عند القبول',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade700,
                                  fontFamily: 'Alexandria',
                                ),
                              ),
                              Text(
                                '$points نقطة',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade900,
                                  fontFamily: 'Alexandria',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text('إلغاء', style: TextStyle(color: Colors.grey.shade600, fontFamily: 'Alexandria')),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(ctx, true),
                  icon: const Icon(Icons.send, size: 18),
                  label: const Text('إرسال الطلب', style: TextStyle(fontFamily: 'Alexandria', fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: teal500,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true) return;

    await widget.cubit.submitAttendanceRequest(attendanceKey: selectedKey, date: selectedDate);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('تم إرسال الطلب بنجاح ✨', style: TextStyle(fontFamily: 'Alexandria', fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  String _typeLabel(String key) {
    switch (key) {
      case 'holy_mass':
        return holyMass;
      case 'sunday_school':
        return sunday;
      case 'hymns':
        return hymns;
      case 'bible':
        return bibleClass;
      default:
        return key;
    }
  }

  IconData _typeIcon(String key) {
    switch (key) {
      case 'holy_mass':
        return Icons.church;
      case 'sunday_school':
        return Icons.school;
      case 'hymns':
        return Icons.music_note;
      case 'bible':
        return Icons.menu_book;
      default:
        return Icons.event;
    }
  }

  Color _typeColor(String key) {
    switch (key) {
      case 'holy_mass':
        return Colors.purple;
      case 'sunday_school':
        return Colors.blue;
      case 'hymns':
        return Colors.orange;
      case 'bible':
        return Colors.green;
      default:
        return teal500;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = widget.cubit.currentUser;
    final isChild = currentUser?.userType == UserType.child;

    final Stream<List<AttendanceRequestModel>> stream;
    if (currentUser?.userType == UserType.priest) {
      stream = widget.cubit.streamPendingAttendanceRequestsForPriest();
    } else if (currentUser?.userType == UserType.superServant) {
      stream = widget.cubit.streamPendingAttendanceRequestsForSuperServant();
    } else {
      stream = widget.cubit.streamPendingAttendanceRequestsForServant();
    }

    return ThemedScaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [teal700, teal500, teal300],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: teal500.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.receipt_long,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'طلبات الحضور',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                fontFamily: 'Alexandria',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isChild ? 'طلباتي' : 'الطلبات المعلقة',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                            fontFamily: 'Alexandria',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: isChild
          ? FloatingActionButton.extended(
              backgroundColor: teal500,
              foregroundColor: Colors.white,
              onPressed: () => _showSubmitRequestDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('طلب جديد', style: TextStyle(fontFamily: 'Alexandria', fontWeight: FontWeight.bold)),
              elevation: 4,
            )
          : null,
      body: StreamBuilder<List<AttendanceRequestModel>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: teal500),
                  const SizedBox(height: 16),
                  Text(
                    'جاري تحميل الطلبات...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontFamily: 'Alexandria',
                    ),
                  ),
                ],
              ),
            );
          }

          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: teal50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.inbox,
                      size: 64,
                      color: teal300,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'لا يوجد طلبات',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: teal900,
                      fontFamily: 'Alexandria',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isChild ? 'لم تقم بإرسال أي طلبات بعد' : 'لا توجد طلبات معلقة حالياً',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontFamily: 'Alexandria',
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final r = items[index];
              final dateStr = DateFormat('yyyy-MM-dd', 'ar').format(r.requestedDate);
              final typeColor = _typeColor(r.attendanceKey);
              final typeIcon = _typeIcon(r.attendanceKey);
              final points = _getPointsForKey(r.attendanceKey);

              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white, typeColor.withValues(alpha: 0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: typeColor.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: typeColor, width: 4),
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: typeColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(typeIcon, color: typeColor, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r.childName,
                                    style: TextStyle(
                                      color: teal900,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Alexandria',
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _typeLabel(r.attendanceKey),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: typeColor,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Alexandria',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.green.shade300),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.stars, size: 16, color: Colors.green.shade700),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$points',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                      fontFamily: 'Alexandria',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 8),
                              Text(
                                dateStr,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                  fontFamily: 'Alexandria',
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isChild) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    await widget.cubit.acceptAttendanceRequest(r);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            children: [
                                              const Icon(Icons.check_circle, color: Colors.white),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  'تم قبول الطلب وإضافة $points نقطة ✨',
                                                  style: const TextStyle(fontFamily: 'Alexandria', fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ],
                                          ),
                                          backgroundColor: Colors.green,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          margin: const EdgeInsets.all(16),
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.check_circle, size: 20),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  label: const Text(
                                    'قبول',
                                    style: TextStyle(fontFamily: 'Alexandria', fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final reason = await _askDeclineReason(context);
                                    if (reason == null) return;
                                    await widget.cubit.declineAttendanceRequest(r, reason: reason);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Row(
                                            children: [
                                              Icon(Icons.info, color: Colors.white),
                                              SizedBox(width: 12),
                                              Text('تم رفض الطلب', style: TextStyle(fontFamily: 'Alexandria')),
                                            ],
                                          ),
                                          backgroundColor: Colors.red,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          margin: const EdgeInsets.all(16),
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.cancel, size: 20),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  label: const Text(
                                    'رفض',
                                    style: TextStyle(fontFamily: 'Alexandria', fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<String?> _askDeclineReason(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.info_outline, color: Colors.red.shade700, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('سبب الرفض', style: TextStyle(fontFamily: 'Alexandria', fontSize: 18)),
              ),
            ],
          ),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'اختياري - اكتب سبب الرفض',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontFamily: 'Alexandria'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: teal500, width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: Text('إلغاء', style: TextStyle(color: Colors.grey.shade600, fontFamily: 'Alexandria')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('تأكيد الرفض', style: TextStyle(fontFamily: 'Alexandria', fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}

