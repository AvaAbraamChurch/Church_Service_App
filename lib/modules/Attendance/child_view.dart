import 'package:church/core/styles/colors.dart';
import 'package:church/core/utils/attendance_enum.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/blocs/attendance/attendance_cubit.dart';
import '../../core/constants/strings.dart';
import '../../core/models/attendance/attendance_model.dart';

class ChildView extends StatelessWidget {
  final AttendanceCubit cubit;
  final int pageIndex;

  const ChildView(this.cubit, {super.key, required this.pageIndex});

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

  String _getAttendanceTypeText(String? type) {
    if (type == null || type.isEmpty) return 'نشاط';
    return type;
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
    // Filter attendance history by the selected tab's attendance type
    final attendanceType = _getAttendanceTypeFromIndex(pageIndex);
    final filteredHistory = cubit.attendanceHistory
        ?.where((record) => record.attendanceType == attendanceType)
        .toList();

    if (filteredHistory == null || filteredHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'لا يوجد سجل حضور',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'سيظهر سجل الحضور لـ $attendanceType هنا',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final groupedRecords = _groupByMonth(filteredHistory);
    final monthKeys = groupedRecords.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: monthKeys.length,
      itemBuilder: (context, monthIndex) {
        final monthKey = monthKeys[monthIndex];
        final records = groupedRecords[monthKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month header
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
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Attendance records for this month
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
                      color: _getStatusColor(
                        record.status,
                      ).withValues(alpha: 0.15),
                      blurRadius: 8,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      // Handle tap if needed
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          // Status icon with decorative circle
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: _getStatusColor(
                                record.status,
                              ).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _getStatusColor(
                                  record.status,
                                ).withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              _getStatusIcon(record.status),
                              color: _getStatusColor(record.status),
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Date and event info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat(
                                    'EEEE، d MMMM',
                                    'ar',
                                  ).format(record.date),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: teal900,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.event,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _getAttendanceTypeText(
                                        record.attendanceType,
                                      ),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                if (record.checkInTime != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        DateFormat(
                                          'h:mm a',
                                          'ar',
                                        ).format(record.checkInTime!),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(record.status),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: _getStatusColor(
                                    record.status,
                                  ).withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              _getStatusText(record.status),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
