import 'package:church/core/constants/strings.dart';
import 'package:church/core/models/attendance/attendance_model.dart';
import 'package:church/core/models/user/user_model.dart';
import 'package:church/core/repositories/attendance_repository.dart';
import 'package:church/core/repositories/classes_repository.dart';
import 'package:church/core/repositories/users_reopsitory.dart';
import 'package:church/core/styles/colors.dart';
import 'package:church/core/styles/themeScaffold.dart';
import 'package:flutter/material.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final AttendanceRepository _attendanceRepo = AttendanceRepository();
  final UsersRepository _usersRepo = UsersRepository();
  final ClassesRepository _classesRepo = ClassesRepository();

  List<UserModel> _allUsers = [];
  List<AttendanceModel> _allAttendance = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedClass;
  List<String> _allClasses = [];
  int? _selectedMonth = DateTime.now().month; // 1-12 for January-December
  int? _selectedYear = DateTime.now().year;
  List<int> _availableYears = [];
  final List<int> _months = List.generate(12, (index) => index + 1);

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
          .where((a) => a.attendanceType == holyMass)
          .length;
      final sundayCount = userAttendanceList
          .where((a) => a.attendanceType == sunday)
          .length;
      final bibleCount = userAttendanceList
          .where((a) => a.attendanceType == bibleClass)
          .length;
      final hymnsCount = userAttendanceList
          .where((a) => a.attendanceType == hymns)
          .length;

      final stats = UserAttendanceStats(
        username: user.username,
        holyMass: holyMassCount,
        sunday: sundayCount,
        bible: bibleCount,
        hymns: hymnsCount,
      );

      if (!groupedData.containsKey(user.userClass)) {
        groupedData[user.userClass] = [];
      }
      groupedData[user.userClass]!.add(stats);
    }

    return groupedData;
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
                  const SizedBox(width: 48),
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
                    _buildClassDropdown(),
                    _buildMonthYearDropdowns(),
                    Expanded(child: _buildStatisticsContent()),
                  ],
                ),
    );
  }

  Widget _buildClassDropdown() {
    return Container(
      padding: const EdgeInsets.all(16),
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
          const Icon(Icons.filter_list, color: teal700, size: 24),
          const SizedBox(width: 12),
          const Text(
            'تصفية حسب الفصل:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: teal900,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
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
                        child: Text(className, style: TextStyle(fontSize: 14),),
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

  String _getMonthName(int month) {
    const monthNames = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return monthNames[month - 1];
  }

  Widget _buildMonthYearDropdowns() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month, color: teal700, size: 24),
              const SizedBox(width: 12),
              const Text(
                'تصفية حسب التاريخ:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: teal900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
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
                Text(
                  className,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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

  UserAttendanceStats({
    required this.username,
    required this.holyMass,
    required this.sunday,
    required this.bible,
    required this.hymns,
  });
}

