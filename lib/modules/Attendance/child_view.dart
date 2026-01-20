import 'package:church/core/repositories/attendance_defaults_repository.dart';
import 'package:church/core/styles/colors.dart';
import 'package:church/core/utils/attendance_enum.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/blocs/attendance/attendance_cubit.dart';
import '../../core/constants/strings.dart';
import '../../core/models/attendance/attendance_model.dart';
import '../../core/models/attendance/attendance_request_model.dart';

class ChildView extends StatefulWidget {
  final AttendanceCubit cubit;
  final int pageIndex;

  const ChildView(this.cubit, {super.key, required this.pageIndex});

  @override
  State<ChildView> createState() => _ChildViewState();
}

class _ChildViewState extends State<ChildView> {
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

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Colors.green;
      case AttendanceStatus.absent:
        return Colors.red;
      case AttendanceStatus.late:
        return Colors.orange;
      case AttendanceStatus.excused:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Icons.check_circle;
      case AttendanceStatus.absent:
        return Icons.cancel;
      case AttendanceStatus.late:
        return Icons.access_time;
      case AttendanceStatus.excused:
        return Icons.info;
    }
  }

  String _getStatusText(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return 'حاضر';
      case AttendanceStatus.absent:
        return 'غائب';
      case AttendanceStatus.late:
        return 'متأخر';
      case AttendanceStatus.excused:
        return 'معذور';
    }
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

  String _attendanceKeyFromIndex(int index) {
    switch (index) {
      case 0:
        return 'holy_mass';
      case 1:
        return 'sunday_school';
      case 2:
        return 'hymns';
      case 3:
        return 'bible';
      default:
        return '';
    }
  }

  String _requestStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'قيد المراجعة';
      case 'accepted':
        return 'تم القبول';
      case 'declined':
        return 'تم الرفض';
      default:
        return status;
    }
  }

  Map<String, List<AttendanceModel>> _groupByMonth(
    List<AttendanceModel> records,
  ) {
    final Map<String, List<AttendanceModel>> grouped = {};

    for (var record in records) {
      final monthKey = DateFormat('MMMM yyyy', 'ar').format(record.date);
      if (!grouped.containsKey(monthKey)) {
        grouped[monthKey] = [];
      }
      grouped[monthKey]!.add(record);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final attendanceType = _getAttendanceTypeFromIndex(widget.pageIndex);
    final attendanceKey = _attendanceKeyFromIndex(widget.pageIndex);

    final filteredHistory = widget.cubit.attendanceHistory
        ?.where((record) => record.attendanceType == attendanceType)
        .toList();

    return StreamBuilder<List<AttendanceRequestModel>>(
      stream: widget.cubit.streamAttendanceRequestsForChild(widget.cubit.currentUser?.id ?? ''),
      builder: (context, reqSnapshot) {
        final requests = (reqSnapshot.data ?? const <AttendanceRequestModel>[])
            .where((r) => r.attendanceKey == attendanceKey)
            .toList();

        final pendingRequests = requests.where((r) => r.status == 'pending').toList();

        if ((filteredHistory == null || filteredHistory.isEmpty) && pendingRequests.isEmpty) {
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
                  child: Icon(Icons.history, size: 64, color: teal300),
                ),
                const SizedBox(height: 24),
                Text(
                  'لا يوجد سجل حضور',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: teal900,
                    fontFamily: 'Alexandria',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'سيظهر سجل الحضور لـ $attendanceType هنا',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontFamily: 'Alexandria',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final groupedRecords = _groupByMonth(filteredHistory ?? const []);
        final monthKeys = groupedRecords.keys.toList();

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          children: [
            if (pendingRequests.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.pending_actions, color: Colors.orange.shade700, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'طلبات قيد المراجعة',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: teal900,
                        fontFamily: 'Alexandria',
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${pendingRequests.length}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                          fontFamily: 'Alexandria',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ...pendingRequests.map((r) {
                final dateStr = DateFormat('yyyy-MM-dd', 'ar').format(r.requestedDate);
                final points = _getPointsForKey(r.attendanceKey);
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white, Colors.orange.shade50],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(color: Colors.orange.shade400, width: 4),
                        ),
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.hourglass_bottom,
                                  color: Colors.orange.shade700,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      dateStr,
                                      style: TextStyle(
                                        color: teal900,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Alexandria',
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _requestStatusText(r.status),
                                        style: TextStyle(
                                          color: Colors.orange.shade700,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                          fontFamily: 'Alexandria',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.green.shade50, Colors.green.shade100],
                                  ),
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
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'سيتم إضافة $points نقطة عند الموافقة على الطلب',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                      fontFamily: 'Alexandria',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              if (filteredHistory != null && filteredHistory.isNotEmpty)
                Divider(color: Colors.grey.shade300, height: 1),
              const SizedBox(height: 16),
            ],
            ...List.generate(monthKeys.length, (monthIndex) {
              final monthKey = monthKeys[monthIndex];
              final records = groupedRecords[monthKey]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 16.0,
                      bottom: 12.0,
                      right: 4.0,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 24,
                          decoration: BoxDecoration(
                            color: teal500,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          monthKey,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: teal500,
                            fontFamily: 'Alexandria',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: teal100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${records.length} ${records.length == 1 ? 'يوم' : 'أيام'}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: teal700,
                              fontFamily: 'Alexandria',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...records.asMap().entries.map((entry) {
                    final index = entry.key;
                    final record = entry.value;
                    final isLast = index == records.length - 1;

                    return AnimatedContainer(
                      duration: Duration(milliseconds: 300 + (index * 50)),
                      curve: Curves.easeOut,
                      margin: EdgeInsets.only(bottom: isLast ? 0 : 12.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            Colors.white,
                            _getStatusColor(record.status).withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _getStatusColor(record.status).withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(
                                color: _getStatusColor(record.status),
                                width: 4,
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: _getStatusColor(record.status)
                                      .withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _getStatusIcon(record.status),
                                  color: _getStatusColor(record.status),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      DateFormat('EEEE، d MMMM', 'ar')
                                          .format(record.date),
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: teal900,
                                        fontFamily: 'Alexandria',
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(record.status)
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _getStatusText(record.status),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: _getStatusColor(record.status),
                                          fontFamily: 'Alexandria',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (record.checkInTime != null)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 16,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('h:mm a', 'ar')
                                          .format(record.checkInTime!),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontFamily: 'Alexandria',
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              );
            }),
          ],
        );
      },
    );
  }
}

