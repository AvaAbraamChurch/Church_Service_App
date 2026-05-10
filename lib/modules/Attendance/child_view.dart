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

  /// [pageIndex] retained for API compatibility — no longer used for filtering.
  final int pageIndex;

  const ChildView(this.cubit, {super.key, required this.pageIndex});

  @override
  State<ChildView> createState() => _ChildViewState();
}

class _ChildViewState extends State<ChildView> {
  final AttendanceDefaultsRepository _defaultsRepo = AttendanceDefaultsRepository();
  Map<String, int> _defaultPoints = {};

  /// Tracks which type sections are expanded. All open by default.
  final Map<String, bool> _expanded = {};

  // ─── Attendance type definitions ──────────────────────────────────────────

  static const List<_TypeDef> _types = [
    _TypeDef(key: 'holy_mass',     label: 'القداس',      attendanceType: holyMass,   icon: Icons.church_rounded,      gradient: [Color(0xFF0D9488), Color(0xFF0F766E)]),
    _TypeDef(key: 'sunday_school', label: 'مدارس الأحد', attendanceType: sunday,     icon: Icons.auto_stories_rounded, gradient: [Color(0xFF0EA5E9), Color(0xFF0284C7)]),
    _TypeDef(key: 'hymns',         label: 'الألحان',     attendanceType: hymns,      icon: Icons.music_note_rounded,   gradient: [Color(0xFF8B5CF6), Color(0xFF7C3AED)]),
    _TypeDef(key: 'bible',         label: 'درس الكتاب',  attendanceType: bibleClass, icon: Icons.menu_book_rounded,    gradient: [Color(0xFFF59E0B), Color(0xFFD97706)]),
    _TypeDef(key: 'visit',         label: 'الافتقاد',    attendanceType: visit,      icon: Icons.home_rounded,         gradient: [Color(0xFF10B981), Color(0xFF059669)]),
  ];

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadDefaults();
    // Start all sections expanded
    for (final t in _types) {
      _expanded[t.key] = true;
    }
  }

  Future<void> _loadDefaults() async {
    final defaults = await _defaultsRepo.getDefaults();
    if (mounted) setState(() => _defaultPoints = defaults);
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  int _pointsForKey(String key) => _defaultPoints[key] ?? 1;

  Color _statusColor(AttendanceStatus s) {
    switch (s) {
      case AttendanceStatus.present: return Colors.green;
      case AttendanceStatus.absent:  return Colors.red;
      case AttendanceStatus.late:    return Colors.orange;
      case AttendanceStatus.excused: return Colors.blue;
    }
  }

  IconData _statusIcon(AttendanceStatus s) {
    switch (s) {
      case AttendanceStatus.present: return Icons.check_circle_rounded;
      case AttendanceStatus.absent:  return Icons.cancel_rounded;
      case AttendanceStatus.late:    return Icons.access_time_rounded;
      case AttendanceStatus.excused: return Icons.info_rounded;
    }
  }

  String _statusText(AttendanceStatus s) {
    switch (s) {
      case AttendanceStatus.present: return 'حاضر';
      case AttendanceStatus.absent:  return 'غائب';
      case AttendanceStatus.late:    return 'متأخر';
      case AttendanceStatus.excused: return 'معذور';
    }
  }

  String _requestStatusText(String s) {
    switch (s) {
      case 'pending':  return 'قيد المراجعة';
      case 'accepted': return 'تم القبول';
      case 'declined': return 'تم الرفض';
      default:         return s;
    }
  }

  Color _requestStatusColor(String s) {
    switch (s) {
      case 'accepted': return Colors.green;
      case 'declined': return Colors.red;
      default:         return Colors.orange;
    }
  }

  // ─── Stats helpers ────────────────────────────────────────────────────

  Map<AttendanceStatus, int> _statsFor(List<AttendanceModel> records) {
    final Map<AttendanceStatus, int> m = {};
    for (final r in records) {
      m[r.status] = (m[r.status] ?? 0) + 1;
    }
    return m;
  }

  /// Get attendance stats for the current month only
  Map<String, int> _currentMonthStats(List<AttendanceModel> records) {
    final now = DateTime.now();
    final currentMonthRecords = records.where((r) {
      return r.date.year == now.year && r.date.month == now.month;
    }).toList();

    final presentCount = currentMonthRecords
        .where((r) => r.status == AttendanceStatus.present)
        .length;
    final totalCount = currentMonthRecords.length;

    return {
      'present': presentCount,
      'total': totalCount,
    };
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AttendanceRequestModel>>(
      stream: widget.cubit.streamAttendanceRequestsForChild(
        widget.cubit.currentUser?.id ?? '',
      ),
      builder: (context, reqSnapshot) {
        final allRequests = reqSnapshot.data ?? const <AttendanceRequestModel>[];
        final history     = widget.cubit.attendanceHistory ?? const <AttendanceModel>[];

        // Check if there's any data at all
        final hasAnyData = history.isNotEmpty ||
            allRequests.any((r) => r.status == 'pending');

        if (!hasAnyData) {
          return _buildEmptyState();
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            // ── Summary stat cards ────────────────────────────────────────
            if (history.isNotEmpty) ...[
              _buildOverallStats(history),
              const SizedBox(height: 20),
            ],

            // ── One section per attendance type ───────────────────────────
            ..._types.map((type) {
              final typeRecords = history
                  .where((r) => r.attendanceType == type.attendanceType)
                  .toList()
                ..sort((a, b) => b.date.compareTo(a.date));

              final typeRequests = allRequests
                  .where((r) => r.attendanceKey == type.key && r.status == 'pending')
                  .toList();

              // Skip types with zero data
              if (typeRecords.isEmpty && typeRequests.isEmpty) {
                return const SizedBox.shrink();
              }

              return _buildTypeSection(type, typeRecords, typeRequests);
            }),
          ],
        );
      },
    );
  }

  // ─── Overall stats row ────────────────────────────────────────────────────

  Widget _buildOverallStats(List<AttendanceModel> history) {
    final total   = history.length;
    final present = history.where((r) => r.status == AttendanceStatus.present).length;
    final absent  = history.where((r) => r.status == AttendanceStatus.absent).length;
    final pct     = total > 0 ? (present / total * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [teal700, teal500], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: teal600.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('إجمالي الحضور', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Alexandria')),
                  Text('$total سجل · نسبة $pct%', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8), fontFamily: 'Alexandria')),
                ]),
              ),
              // Big percentage badge
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                child: Center(
                  child: Text('$pct%', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Alexandria')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatChip(count: present, label: 'حاضر',  color: Colors.green,  icon: Icons.check_circle_rounded),
              const SizedBox(width: 8),
              _StatChip(count: absent,  label: 'غائب',   color: Colors.red,    icon: Icons.cancel_rounded),

            ],
          ),
        ],
      ),
    );
  }

  // ─── Type section ─────────────────────────────────────────────────────────

  Widget _buildTypeSection(
      _TypeDef type,
      List<AttendanceModel> records,
      List<AttendanceRequestModel> pendingRequests,
      ) {
    final isExpanded = _expanded[type.key] ?? true;
    final monthStats = _currentMonthStats(records);
    final monthPresent = monthStats['present'] ?? 0;
    final monthTotal = monthStats['total'] ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 14, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            // ── Section header / toggle ───────────────────────────────────
            InkWell(
              onTap: () => setState(() => _expanded[type.key] = !isExpanded),
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(22),
                bottom: isExpanded ? Radius.zero : const Radius.circular(22),
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: type.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.vertical(
                    top: const Radius.circular(22),
                    bottom: isExpanded ? Radius.zero : const Radius.circular(22),
                  ),
                ),
                child: Row(
                  children: [
                    // Icon bubble
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                      child: Icon(type.icon, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    // Label + sub-count
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(type.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Alexandria')),
                        if (monthTotal > 0)
                          Text(
                            '$monthPresent من $monthTotal في الشهر الحالي',
                            style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8), fontFamily: 'Alexandria'),
                          ),
                      ]),
                    ),
                    // Pending badge
                    if (pendingRequests.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(20)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.pending_actions, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text('${pendingRequests.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'Alexandria')),
                        ]),
                      ),
                    const SizedBox(width: 4),
                    // Expand arrow
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 24),
                    ),
                  ],
                ),
              ),
            ),

            // ── Collapsible body ──────────────────────────────────────────
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 280),
              crossFadeState: isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
              firstChild: _buildSectionBody(type, records, pendingRequests),
              secondChild: const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Section body: pending requests + timeline ────────────────────────────

  Widget _buildSectionBody(
      _TypeDef type,
      List<AttendanceModel> records,
      List<AttendanceRequestModel> pendingRequests,
      ) {
    if (records.isEmpty && pendingRequests.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mini stat chips
          if (records.isNotEmpty) ...[
            _buildMiniStats(records, type.gradient[0]),
            const SizedBox(height: 14),
          ],

          // Pending requests
          if (pendingRequests.isNotEmpty) ...[
            _buildSubHeader('طلبات قيد المراجعة', Icons.pending_actions_rounded, Colors.orange),
            const SizedBox(height: 8),
            ...pendingRequests.map((r) => _buildRequestCard(r, type)),
            const SizedBox(height: 12),
          ],

          // Timeline records
          if (records.isNotEmpty) ...[
            _buildSubHeader('سجل الحضور', Icons.history_rounded, type.gradient[0]),
            const SizedBox(height: 8),
            ...records.asMap().entries.map((e) =>
                _buildTimelineCard(e.value, e.key == records.length - 1, type.gradient[0]),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Mini stat chips row ──────────────────────────────────────────────────

  Widget _buildMiniStats(List<AttendanceModel> records, Color accent) {
    final stats   = _statsFor(records);
    final present = stats[AttendanceStatus.present] ?? 0;
    final absent  = stats[AttendanceStatus.absent]  ?? 0;
    final late    = stats[AttendanceStatus.late]    ?? 0;
    final excused = stats[AttendanceStatus.excused] ?? 0;

    return Row(
      children: [
        if (present > 0) ...[_MiniChip(count: present, label: 'حاضر',  color: Colors.green),  const SizedBox(width: 6)],
        if (absent  > 0) ...[_MiniChip(count: absent,  label: 'غائب',  color: Colors.red),    const SizedBox(width: 6)],
        if (late    > 0) ...[_MiniChip(count: late,    label: 'متأخر', color: Colors.orange), const SizedBox(width: 6)],
        if (excused > 0)   _MiniChip(count: excused, label: 'معذور', color: Colors.blue),
      ],
    );
  }

  // ─── Sub-header ───────────────────────────────────────────────────────────

  Widget _buildSubHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color, fontFamily: 'Alexandria')),
      ],
    );
  }

  // ─── Request card ─────────────────────────────────────────────────────────

  Widget _buildRequestCard(AttendanceRequestModel r, _TypeDef type) {
    final dateStr  = DateFormat('EEEE، d MMMM yyyy', 'ar').format(r.requestedDate);
    final points   = _pointsForKey(r.attendanceKey);
    final sColor   = _requestStatusColor(r.status);
    final sText    = _requestStatusText(r.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: Colors.orange.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(width: 5, decoration: BoxDecoration(color: sColor, borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)))),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(dateStr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontFamily: 'Alexandria')),
                        const SizedBox(height: 6),
                        Row(children: [
                          Icon(Icons.stars_rounded, size: 14, color: Colors.green[600]),
                          const SizedBox(width: 4),
                          Text('+$points نقطة متوقعة',
                              style: TextStyle(color: Colors.green[700], fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'Alexandria')),
                        ]),
                      ]),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: sColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: sColor.withValues(alpha: 0.4))),
                      child: Text(sText, style: TextStyle(color: sColor, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Alexandria')),
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

  // ─── Timeline card ────────────────────────────────────────────────────────

  Widget _buildTimelineCard(AttendanceModel record, bool isLast, Color accent) {
    final sColor   = _statusColor(record.status);
    final sIcon    = _statusIcon(record.status);
    final dateText = DateFormat('EEEE، d MMMM', 'ar').format(record.date);
    final timeText = record.checkInTime != null
        ? DateFormat('h:mm a', 'ar').format(record.checkInTime!)
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Timeline rail ─────────────────────────────────────────────
            SizedBox(
              width: 44,
              child: Column(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: sColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: sColor, width: 2),
                    ),
                    child: Icon(sIcon, color: sColor, size: 20),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: Colors.grey[200],
                        margin: const EdgeInsets.symmetric(vertical: 3),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // ── Card ──────────────────────────────────────────────────────
            Expanded(
              child: Container(
                margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: sColor.withValues(alpha: 0.2)),
                  boxShadow: [BoxShadow(color: sColor.withValues(alpha: 0.07), blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(dateText, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontFamily: 'Alexandria')),
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: sColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                          child: Text(_statusText(record.status),
                              style: TextStyle(color: sColor, fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'Alexandria')),
                        ),
                      ]),
                    ),
                    if (timeText.isNotEmpty)
                      Row(children: [
                        Icon(Icons.access_time_rounded, size: 13, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Text(timeText, style: TextStyle(fontSize: 11, color: Colors.grey[500], fontFamily: 'Alexandria')),
                      ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Empty state ──────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: teal50,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: teal200, blurRadius: 24, spreadRadius: 6)],
            ),
            child: Icon(Icons.history_edu_rounded, size: 64, color: teal400),
          ),
          const SizedBox(height: 24),
          const Text('لا يوجد سجل حضور', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: teal900, fontFamily: 'Alexandria')),
          const SizedBox(height: 8),
          Text('سيظهر سجل حضورك في جميع الأنشطة هنا', style: TextStyle(fontSize: 14, color: Colors.grey[500], fontFamily: 'Alexandria'), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Data class
// ════════════════════════════════════════════════════════════════════════════

class _TypeDef {
  final String key;
  final String label;
  final String attendanceType; // matches AttendanceModel.attendanceType
  final IconData icon;
  final List<Color> gradient;

  const _TypeDef({
    required this.key,
    required this.label,
    required this.attendanceType,
    required this.icon,
    required this.gradient,
  });
}

// ════════════════════════════════════════════════════════════════════════════
// Small reusable widgets
// ════════════════════════════════════════════════════════════════════════════

class _StatChip extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  final IconData icon;

  const _StatChip({required this.count, required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(14)),
        child: Column(children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(height: 4),
          Text('$count', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Alexandria')),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.85), fontFamily: 'Alexandria')),
        ]),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _MiniChip({required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text('$count $label', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color, fontFamily: 'Alexandria')),
    );
  }
}