import 'package:church/core/constants/strings.dart';
import 'package:church/core/models/attendance/attendance_model.dart';
import 'package:church/core/models/attendance/visit_model.dart';
import 'package:church/core/models/user/user_model.dart';
import 'package:church/core/repositories/attendance_repository.dart';
import 'package:church/core/repositories/classes_repository.dart';
import 'package:church/core/repositories/users_reopsitory.dart';
import 'package:church/core/repositories/visit_repository.dart';
import 'package:church/core/styles/colors.dart';
import 'package:church/core/styles/themeScaffold.dart';
import 'package:church/core/utils/userType_enum.dart';
import 'package:church/core/utils/gender_enum.dart';
import 'package:church/core/utils/attendance_enum.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final AttendanceRepository _attendanceRepo = AttendanceRepository();
  final UsersRepository _usersRepo = UsersRepository();
  final ClassesRepository _classesRepo = ClassesRepository();
  final VisitRepository _visitRepo = VisitRepository();

  List<UserModel> _allUsers = [];
  List<AttendanceModel> _allAttendance = [];
  List<VisitModel> _allVisits = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedClass;
  List<String> _allClasses = [];
  int? _selectedMonth = DateTime.now().month; // 1-12 for January-December
  int? _selectedYear = DateTime.now().year;
  List<int> _availableYears = [];
  final List<int> _months = List.generate(12, (index) => index + 1);
  String? _selectedUserType;
  String? _selectedGender;

  // Expansion states
  bool _isClassFilterExpanded = false;
  bool _isUserTypeGenderFilterExpanded = false;
  bool _isDateFilterExpanded = true; // Default expanded
  bool _showFilters = false; // Toggle to show/hide all filters

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load all users
      final usersStream = _usersRepo.getUsers();
      final usersSnapshot = await usersStream.first;
      _allUsers = usersSnapshot
          .map((userData) => UserModel.fromJson(userData))
          .toList();

      // Load all attendance records
      _allAttendance = await _attendanceRepo.getAttendanceFuture();

      // Load all visits
      _allVisits = await _visitRepo.getAllVisitsFuture();

      // Fetch class names from Firestore
      final classesStream = _classesRepo.getAllClasses();
      final classesSnapshot = await classesStream.first;
      _allClasses = classesSnapshot
          .map((classModel) => classModel.name ?? '')
          .where((name) => name.isNotEmpty)
          .toList()
        ..sort();

      // Generate available years (current year and past 5 years)
      _availableYears = _generateYearsList();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'خطأ في تحميل البيانات: $e';
        _isLoading = false;
      });
    }
  }

  List<int> _generateYearsList() {
    final currentYear = DateTime.now().year;
    final List<int> years = [];

    // Generate current year and past 5 years
    for (int i = 0; i <= 5; i++) {
      years.add(currentYear - i);
    }

    return years;
  }

  Map<String, List<UserAttendanceStats>> _groupUsersByClass() {
    final Map<String, List<UserAttendanceStats>> groupedData = {};

    for (final user in _allUsers) {
      // Filter by userType if selected
      if (_selectedUserType != null && user.userType.code != _selectedUserType) {
        continue;
      }

      // Filter by gender if selected
      if (_selectedGender != null && user.gender.code != _selectedGender) {
        continue;
      }

      // Filter attendance by selected month and/or year if applicable
      var userAttendance = _allAttendance.where((a) => a.userId == user.id);

      if (_selectedMonth != null || _selectedYear != null) {
        userAttendance = userAttendance.where((a) {
          final attendanceDate = a.date;
          bool matchesMonth = _selectedMonth == null || attendanceDate.month == _selectedMonth;
          bool matchesYear = _selectedYear == null || attendanceDate.year == _selectedYear;
          return matchesMonth && matchesYear;
        });
      }

      final userAttendanceList = userAttendance.toList();

      final holyMassCount = userAttendanceList
          .where((a) => a.attendanceType == holyMass && a.status == AttendanceStatus.present)
          .length;
      final sundayCount = userAttendanceList
          .where((a) => a.attendanceType == sunday && a.status == AttendanceStatus.present)
          .length;
      final bibleCount = userAttendanceList
          .where((a) => a.attendanceType == bibleClass && a.status == AttendanceStatus.present)
          .length;
      final hymnsCount = userAttendanceList
          .where((a) => a.attendanceType == hymns && a.status == AttendanceStatus.present)
          .length;

      // Calculate visit count for servants and super servants
      int visitCount = 0;
      if (user.userType == UserType.servant || user.userType == UserType.superServant) {
        // Get all visits where this user is a servant
        var userVisits = _allVisits.where((v) => v.servantsId.contains(user.id));

        // Filter by month/year if selected
        if (_selectedMonth != null || _selectedYear != null) {
          userVisits = userVisits.where((v) {
            final visitDate = v.date;
            bool matchesMonth = _selectedMonth == null || visitDate.month == _selectedMonth;
            bool matchesYear = _selectedYear == null || visitDate.year == _selectedYear;
            return matchesMonth && matchesYear;
          });
        }

        // Count unique weeks
        final Set<String> uniqueWeeks = {};
        for (final visit in userVisits) {
          // Calculate week identifier as "year-week"
          final weekOfYear = _getWeekOfYear(visit.date);
          final weekId = '${visit.date.year}-$weekOfYear';
          uniqueWeeks.add(weekId);
        }
        visitCount = uniqueWeeks.length;
      }

      final stats = UserAttendanceStats(
        username: user.username,
        holyMass: holyMassCount,
        sunday: sundayCount,
        bible: bibleCount,
        hymns: hymnsCount,
        visits: visitCount,
      );

      if (!groupedData.containsKey(user.userClass)) {
        groupedData[user.userClass] = [];
      }
      groupedData[user.userClass]!.add(stats);
    }

    return groupedData;
  }

  /// Helper method to get the week number of the year for a given date
  int _getWeekOfYear(DateTime date) {
    // ISO 8601 week date: Week 1 is the first week with a Thursday
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    final weekNumber = ((daysSinceFirstDay + firstDayOfYear.weekday) / 7).ceil();
    return weekNumber;
  }

  Future<void> _exportToPdf() async {
    final groupedData = _groupUsersByClass();

    if (groupedData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا توجد بيانات للتصدير'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Filter by selected class or show all
    final sortedClasses = _selectedClass != null
        ? [_selectedClass!]
        : (groupedData.keys.toList()..sort());

    final pdf = pw.Document();

    // Load Alexandria Arabic font
    final arabicFont = await PdfGoogleFonts.alexandriaRegular();
    final arabicFontBold = await PdfGoogleFonts.alexandriaBold();

    // Build filter info text
    String filterInfo = _buildFilterInfoText();

    // Add pages for each class
    for (final className in sortedClasses) {
      final users = groupedData[className];
      if (users == null || users.isEmpty) continue;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          textDirection: pw.TextDirection.rtl,
          theme: pw.ThemeData.withFont(
            base: arabicFont,
            bold: arabicFontBold,
          ),
          build: (pw.Context context) {
            return [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.teal700,
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'إحصائيات الحضور',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                        font: arabicFontBold,
                      ),
                      textDirection: pw.TextDirection.rtl,
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'الاسرة: $className',
                      style: pw.TextStyle(
                        fontSize: 18,
                        color: PdfColors.white,
                        font: arabicFont,
                      ),
                      textDirection: pw.TextDirection.rtl,
                    ),
                    if (filterInfo.isNotEmpty) ...[
                      pw.SizedBox(height: 5),
                      pw.Text(
                        filterInfo,
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.white,
                          font: arabicFont,
                        ),
                        textDirection: pw.TextDirection.rtl,
                      ),
                    ],
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // User count info
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Text(
                  'عدد المستخدمين: ${users.length}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    font: arabicFontBold,
                  ),
                  textDirection: pw.TextDirection.rtl,
                ),
              ),
              pw.SizedBox(height: 15),

              // Table
              pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                child: pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400, width: 1),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3),
                    1: const pw.FlexColumnWidth(1.5),
                    2: const pw.FlexColumnWidth(1.5),
                    3: const pw.FlexColumnWidth(1.5),
                    4: const pw.FlexColumnWidth(1.5),
                    5: const pw.FlexColumnWidth(1.5),
                  },
                  children: [
                    // Header row
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey300,
                      ),
                      children: [
                        _buildPdfTableHeader('اسم المستخدم', arabicFontBold),
                        _buildPdfTableHeader('القداس', arabicFontBold),
                        _buildPdfTableHeader('مدارس الأحد', arabicFontBold),
                        _buildPdfTableHeader('درس الكتاب', arabicFontBold),
                        _buildPdfTableHeader('الحان', arabicFontBold),
                        _buildPdfTableHeader('الإفتقاد', arabicFontBold),
                      ],
                    ),
                    // Data rows
                    ...users.map((user) {
                      return pw.TableRow(
                        children: [
                          _buildPdfTableCell(user.username, arabicFont),
                          _buildPdfTableCellWithColor(user.holyMass, arabicFont),
                          _buildPdfTableCellWithColor(user.sunday, arabicFont),
                          _buildPdfTableCellWithColor(user.bible, arabicFont),
                          _buildPdfTableCellWithColor(user.hymns, arabicFont),
                          _buildPdfTableCellWithColor(user.visits, arabicFont),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ];
          },
        ),
      );
    }

    // Show print preview
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'إحصائيات_الحضور_${DateTime.now().toString().split(' ')[0]}.pdf',
    );
  }

  String _buildFilterInfoText() {
    List<String> filters = [];

    if (_selectedMonth != null) {
      filters.add('الشهر: ${_getMonthName(_selectedMonth!)}');
    }

    if (_selectedYear != null) {
      filters.add('السنة: $_selectedYear');
    }

    return filters.isEmpty ? '' : ' ${filters.join(' - ')}';
  }

  pw.Widget _buildPdfTableHeader(String text, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
          font: font,
        ),
        textAlign: pw.TextAlign.center,
        textDirection: pw.TextDirection.rtl,
      ),
    );
  }

  pw.Widget _buildPdfTableCell(String text, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 10, font: font),
        textDirection: pw.TextDirection.rtl,
      ),
    );
  }

  pw.Widget _buildPdfTableCellWithColor(int count, pw.Font font) {
    PdfColor backgroundColor;
    PdfColor textColor;

    if (count == 0) {
      backgroundColor = PdfColors.red50;
      textColor = PdfColors.red700;
    } else if (count <= 5) {
      backgroundColor = PdfColors.orange50;
      textColor = PdfColors.orange700;
    } else {
      backgroundColor = PdfColors.green50;
      textColor = PdfColors.green700;
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      alignment: pw.Alignment.center,
      color: backgroundColor,
      child: pw.Text(
        count.toString(),
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: textColor,
          font: font,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ThemedScaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade700, Colors.green.shade500, Colors.green.shade300],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.green.shade700.withValues(alpha: 0.3),
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
                                Icons.bar_chart_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'إحصائيات الحضور',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'حضور المستخدمين حسب الفصول',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 28),
                    onPressed: _exportToPdf,
                    tooltip: 'تصدير إلى PDF',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Filter toggle button
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade300,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _showFilters = !_showFilters;
                                  // If showing filters, expand date filter by default
                                  if (_showFilters && !_isDateFilterExpanded) {
                                    _isDateFilterExpanded = true;
                                  }
                                });
                              },
                              icon: Icon(_showFilters ? Icons.filter_alt_off : Icons.filter_alt),
                              label: Text(_showFilters ? 'إخفاء التصفية' : 'إظهار خيارات التصفية'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _showFilters ? brown500 : teal500,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          if (_showFilters && (_selectedClass != null || _selectedUserType != null || _selectedGender != null || _selectedMonth != null || _selectedYear != null)) ...[
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _selectedClass = null;
                                  _selectedUserType = null;
                                  _selectedGender = null;
                                  _selectedMonth = DateTime.now().month;
                                  _selectedYear = DateTime.now().year;
                                });
                              },
                              icon: const Icon(Icons.clear_all),
                              label: const Text('مسح الفلاتر'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: red500,
                                side: BorderSide(color: red500),
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Filter sections (conditionally shown)
                    if (_showFilters)
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              _buildClassDropdown(),
                              _buildUserTypeAndGenderDropdowns(),
                              _buildMonthYearDropdowns(),
                            ],
                          ),
                        ),
                      ),
                    // Statistics content
                    Expanded(
                      flex: _showFilters ? 2 : 3,
                      child: _buildStatisticsContent(),
                    ),
                  ],
                ),
    );
  }

  Widget _buildClassDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        initiallyExpanded: _isClassFilterExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _isClassFilterExpanded = expanded;
          });
        },
        leading: const Icon(Icons.filter_list, color: teal700, size: 24),
        title: const Text(
          'تصفية حسب الاسرة',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: teal900,
          ),
        ),
        subtitle: _selectedClass != null
            ? Text(
                'الاسرة المحدد: $_selectedClass',
                style: TextStyle(fontSize: 12, color: teal700),
              )
            : const Text(
                'جميع الفصول',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: teal500),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade50,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: _selectedClass,
                  isExpanded: true,
                  hint: const Text('جميع الفصول'),
                  icon: const Icon(Icons.arrow_drop_down, color: teal700),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text(
                        'جميع الفصول',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    ..._allClasses.map((className) {
                      return DropdownMenuItem<String?>(
                        value: className,
                        child: Text(className, style: const TextStyle(fontSize: 14)),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedClass = value;
                    });
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTypeAndGenderDropdowns() {
    String subtitle = '';
    if (_selectedUserType != null || _selectedGender != null) {
      List<String> parts = [];
      if (_selectedUserType != null) {
        final userType = UserType.values.firstWhere((t) => t.code == _selectedUserType);
        parts.add('النوع: ${userType.label}');
      }
      if (_selectedGender != null) {
        final gender = Gender.values.firstWhere((g) => g.code == _selectedGender);
        parts.add('الجنس: ${gender.label}');
      }
      subtitle = parts.join(' - ');
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        initiallyExpanded: _isUserTypeGenderFilterExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _isUserTypeGenderFilterExpanded = expanded;
          });
        },
        leading: const Icon(Icons.person_search, color: teal700, size: 24),
        title: const Text(
          'تصفية حسب نوع المستخدم والجنس',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: teal900,
          ),
        ),
        subtitle: subtitle.isNotEmpty
            ? Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: teal700),
              )
            : const Text(
                'الكل',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                // UserType Dropdown
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'نوع المستخدم',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: teal500),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade50,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            value: _selectedUserType,
                            isExpanded: true,
                            hint: const Text('الكل'),
                            icon: const Icon(Icons.arrow_drop_down, color: teal700),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text(
                                  'الكل',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              ...UserType.values.map((type) {
                                return DropdownMenuItem<String?>(
                                  value: type.code,
                                  child: Text(
                                    type.label,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                );
                              }),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedUserType = value;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Gender Dropdown
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الجنس',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: teal500),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade50,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            value: _selectedGender,
                            isExpanded: true,
                            hint: const Text('الكل'),
                            icon: const Icon(Icons.arrow_drop_down, color: teal700),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text(
                                  'الكل',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              ...Gender.values.map((gender) {
                                return DropdownMenuItem<String?>(
                                  value: gender.code,
                                  child: Text(
                                    gender.label,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                );
                              }),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedGender = value;
                              });
                            },
                          ),
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
    );
  }

  String _getMonthName(int month) {
    const monthNames = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return monthNames[month - 1];
  }

  Widget _buildMonthYearDropdowns() {
    String subtitle = '';
    if (_selectedMonth != null || _selectedYear != null) {
      List<String> parts = [];
      if (_selectedMonth != null) {
        parts.add('الشهر: ${_getMonthName(_selectedMonth!)}');
      }
      if (_selectedYear != null) {
        parts.add('السنة: $_selectedYear');
      }
      subtitle = parts.join(' - ');
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        initiallyExpanded: _isDateFilterExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _isDateFilterExpanded = expanded;
          });
        },
        leading: const Icon(Icons.calendar_month, color: teal700, size: 24),
        title: const Text(
          'تصفية حسب التاريخ',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: teal900,
          ),
        ),
        subtitle: subtitle.isNotEmpty
            ? Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: teal700),
              )
            : const Text(
                'كل الأوقات',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                // Month Dropdown
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الشهر',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: teal500),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade50,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int?>(
                            value: _selectedMonth,
                            isExpanded: true,
                            hint: const Text('كل الشهور'),
                            icon: const Icon(Icons.arrow_drop_down, color: teal700),
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text(
                                  'كل الشهور',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              ..._months.map((month) {
                                return DropdownMenuItem<int?>(
                                  value: month,
                                  child: Text(
                                    _getMonthName(month),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                );
                              }),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedMonth = value;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Year Dropdown
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'السنة',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: teal500),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade50,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int?>(
                            value: _selectedYear,
                            isExpanded: true,
                            hint: const Text('كل السنوات'),
                            icon: const Icon(Icons.arrow_drop_down, color: teal700),
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text(
                                  'كل السنوات',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              ..._availableYears.map((year) {
                                return DropdownMenuItem<int?>(
                                  value: year,
                                  child: Text(
                                    year.toString(),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                );
                              }),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedYear = value;
                              });
                            },
                          ),
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
    );
  }

  Widget _buildStatisticsContent() {
    final groupedData = _groupUsersByClass();

    if (groupedData.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد بيانات حضور',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    // Filter by selected class or show all
    final sortedClasses = _selectedClass != null
        ? [_selectedClass!]
        : (groupedData.keys.toList()..sort());

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedClasses.length,
      itemBuilder: (context, index) {
        final className = sortedClasses[index];
        final users = groupedData[className];

        // Skip if class doesn't have data
        if (users == null || users.isEmpty) {
          return const SizedBox.shrink();
        }

        return _buildClassSection(className, users);
      },
    );
  }

  Widget _buildClassSection(String className, List<UserAttendanceStats> users) {
    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Class header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [teal700, teal500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.class_rounded, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    className,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 3,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${users.length} مستخدم',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Table
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                Colors.grey.shade100,
              ),
              columns: const [
                DataColumn(
                  label: Text(
                    'اسم المستخدم',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'القداس',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'مدارس الأحد',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'درس الكتاب',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'الحان',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'الإفتقاد',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
              rows: users.map((user) {
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        user.username,
                        style: const TextStyle(fontSize: 13, color: teal900),
                      ),
                    ),
                    DataCell(
                      _buildCountCell(user.holyMass),
                    ),
                    DataCell(
                      _buildCountCell(user.sunday),
                    ),
                    DataCell(
                      _buildCountCell(user.bible),
                    ),
                    DataCell(
                      _buildCountCell(user.hymns),
                    ),
                    DataCell(
                      _buildCountCell(user.visits),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),

          // Summary footer
          // Container(
          //   padding: const EdgeInsets.all(16),
          //   decoration: BoxDecoration(
          //     color: Colors.grey.shade50,
          //     borderRadius: const BorderRadius.only(
          //       bottomLeft: Radius.circular(16),
          //       bottomRight: Radius.circular(16),
          //     ),
          //   ),
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.spaceAround,
          //     children: [
          //       _buildSummaryItem(
          //         'القداس',
          //         users.fold(0, (sum, user) => sum + user.holyMass),
          //         Colors.blue,
          //       ),
          //       _buildSummaryItem(
          //         'الأحد',
          //         users.fold(0, (sum, user) => sum + user.sunday),
          //         Colors.green,
          //       ),
          //       _buildSummaryItem(
          //         'الكتاب',
          //         users.fold(0, (sum, user) => sum + user.bible),
          //         Colors.orange,
          //       ),
          //       _buildSummaryItem(
          //         'الحان',
          //         users.fold(0, (sum, user) => sum + user.hymns),
          //         Colors.purple,
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildCountCell(int count) {
    Color backgroundColor;
    Color textColor;

    if (count == 0) {
      backgroundColor = Colors.red.shade50;
      textColor = Colors.red.shade700;
    } else if (count <= 5) {
      backgroundColor = Colors.orange.shade50;
      textColor = Colors.orange.shade700;
    } else {
      backgroundColor = Colors.green.shade50;
      textColor = Colors.green.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        count.toString(),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}

class UserAttendanceStats {
  final String username;
  final int holyMass;
  final int sunday;
  final int bible;
  final int hymns;
  final int visits;

  UserAttendanceStats({
    required this.username,
    required this.holyMass,
    required this.sunday,
    required this.bible,
    required this.hymns,
    required this.visits,
  });
}

