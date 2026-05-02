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
    if (mounted) setState(() => _defaultPoints = defaults);
  }

  int _getPointsForKey(String key) => _defaultPoints[key] ?? 1;

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present: return Colors.green;
      case AttendanceStatus.absent: return Colors.red;
      case AttendanceStatus.late: return Colors.orange;
      case AttendanceStatus.excused: return Colors.blue;
    }
  }

  IconData _getStatusIcon(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present: return Icons.check_circle;
      case AttendanceStatus.absent: return Icons.cancel;
      case AttendanceStatus.late: return Icons.access_time;
      case AttendanceStatus.excused: return Icons.info;
    }
  }

  String _getStatusText(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present: return 'حاضر';
      case AttendanceStatus.absent: return 'غائب';
      case AttendanceStatus.late: return 'متأخر';
      case AttendanceStatus.excused: return 'معذور';
    }
  }

  String _getAttendanceTypeFromIndex(int index) {
    switch (index) {
      case 0: return holyMass;
      case 1: return sunday;
      case 2: return hymns;
      case 3: return bibleClass;
      case 4: return visit;
      default: return '';
    }
  }

  String _attendanceKeyFromIndex(int index) {
    switch (index) {
      case 0: return 'holy_mass';
      case 1: return 'sunday_school';
      case 2: return 'hymns';
      case 3: return 'bible';
      default: return '';
    }
  }

  String _requestStatusText(String status) {
    switch (status) {
      case 'pending': return 'قيد المراجعة';
      case 'accepted': return 'تم القبول';
      case 'declined': return 'تم الرفض';
      default: return status;
    }
  }

  Map<String, List<AttendanceModel>> _groupByMonth(List<AttendanceModel> records) {
    final Map<String, List<AttendanceModel>> grouped = {};
    for (var record in records) {
      final monthKey = DateFormat('MMMM yyyy', 'ar').format(record.date);
      grouped.putIfAbsent(monthKey, () => []);
      grouped[monthKey]!.add(record);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final attendanceType = _getAttendanceTypeFromIndex(widget.pageIndex);
    final attendanceKey = _attendanceKeyFromIndex(widget.pageIndex);

    return StreamBuilder<List<AttendanceRequestModel>>(
      stream: widget.cubit.streamAttendanceRequestsForChild(widget.cubit.currentUser?.id ?? ''),
      builder: (context, reqSnapshot) {
        final requests = (reqSnapshot.data ?? const <AttendanceRequestModel>[])
            .where((r) => r.attendanceKey == attendanceKey)
            .toList();
        final pendingRequests = requests.where((r) => r.status == 'pending').toList();

        final filteredHistory = widget.cubit.attendanceHistory
            ?.where((record) => record.attendanceType == attendanceType)
            .toList();

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
                    boxShadow: [
                      BoxShadow(color: teal200, blurRadius: 20, spreadRadius: 5),
                    ],
                  ),
                  child: Icon(Icons.history, size: 64, color: teal400),
                ),
                const SizedBox(height: 24),
                const Text(
                  'لا يوجد سجل حضور',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: teal900, fontFamily: 'Alexandria'),
                ),
                const SizedBox(height: 8),
                Text(
                  'سيظهر سجل الحضور لـ $attendanceType هنا',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600], fontFamily: 'Alexandria'),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final groupedRecords = _groupByMonth(filteredHistory ?? const []);
        final monthKeys = groupedRecords.keys.toList();

        return LayoutBuilder(
          builder: (context, constraints) {
            return ListView(
              padding: EdgeInsets.only(
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 16,
                right: 16,
              ),
              children: [
                if (pendingRequests.isNotEmpty) ...[
                  _buildSectionHeader('طلبات قيد المراجعة', pendingRequests.length.toString(), Colors.orange.shade600, Icons.pending_actions),
                  const SizedBox(height: 12),
                  ...pendingRequests.map((r) => _buildRequestCard(r)).toList(),
                  const SizedBox(height: 16),
                ],
                ...monthKeys.map((monthKey) {
                  final records = groupedRecords[monthKey]!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(monthKey, '${records.length} أيام', teal500, Icons.calendar_month),
                      const SizedBox(height: 12),
                      ...records.asMap().entries.map((entry) => _buildTimelineCard(entry.value, entry.key == records.length - 1)),
                    ],
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, String count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: teal900, fontFamily: 'Alexandria')),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(count, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color, fontFamily: 'Alexandria')),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(AttendanceRequestModel r) {
    final dateStr = DateFormat('yyyy-MM-dd', 'ar').format(r.requestedDate);
    final points = _getPointsForKey(r.attendanceKey);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.orange.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(width: 6, decoration: BoxDecoration(color: Colors.orange, borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)))),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(dateStr, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: teal900, fontFamily: 'Alexandria')),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(6)),
                          child: Text(_requestStatusText(r.status), style: TextStyle(color: Colors.orange.shade800, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Alexandria')),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.stars, size: 16, color: Colors.green.shade600),
                        const SizedBox(width: 4),
                        Text('+$points نقطة', style: TextStyle(color: Colors.green.shade700, fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Alexandria')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineCard(AttendanceModel record, bool isLast) {
    final statusColor = _getStatusColor(record.status);
    final statusIcon = _getStatusIcon(record.status);
    final dateText = DateFormat('EEEE، d MMMM', 'ar').format(record.date);
    final timeText = record.checkInTime != null ? DateFormat('h:mm a', 'ar').format(record.checkInTime!) : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline Line
            Column(
              children: [
                if (!isLast) ...[
                  Container(
                    width: 3,
                    height: 24,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 4),
                ],
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: statusColor, width: 2),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 20),
                ),
                if (!isLast) ...[
                  const SizedBox(height: 4),
                  Container(
                    width: 3,
                    height: 24,
                    color: Colors.grey[300],
                  ),
                ],
              ],
            ),
            const SizedBox(width: 16),
            // Card Content
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: statusColor.withValues(alpha: 0.1), blurRadius: 6, offset: const Offset(0, 3))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dateText, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: teal900, fontFamily: 'Alexandria')),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                          child: Text(_getStatusText(record.status), style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'Alexandria')),
                        ),
                        const Spacer(),
                        if (timeText.isNotEmpty)
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text(timeText, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontFamily: 'Alexandria')),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}