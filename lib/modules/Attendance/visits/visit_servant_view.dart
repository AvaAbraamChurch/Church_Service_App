import 'package:church/core/blocs/attendance/attendance_cubit.dart';
import 'package:church/core/models/attendance/visit_model.dart';
import 'package:church/core/models/user/user_model.dart';
import 'package:church/core/utils/userType_enum.dart';
import 'package:church/core/utils/visit_enum.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/styles/colors.dart';

/// Servant can only create visits for children in their class and same gender
class VisitServantView extends StatefulWidget {
  final List<UserModel> users;
  final UserModel currentUser;
  final AttendanceCubit attendanceCubit;

  const VisitServantView({
    super.key,
    required this.users,
    required this.currentUser,
    required this.attendanceCubit,
  });

  @override
  State<VisitServantView> createState() => _VisitServantViewState();
}

class _VisitServantViewState extends State<VisitServantView> {
  UserModel? selectedChild;
  VisitType selectedVisitType = VisitType.home;
  List<UserModel> selectedServants = [];
  final TextEditingController notesController = TextEditingController();
  final TextEditingController childSearchController = TextEditingController();
  final TextEditingController servantSearchController = TextEditingController();
  String childSearchQuery = '';
  String servantSearchQuery = '';

  @override
  void initState() {
    super.initState();
    // Auto-select current user as a servant
    selectedServants.add(widget.currentUser);
  }

  @override
  void dispose() {
    notesController.dispose();
    childSearchController.dispose();
    servantSearchController.dispose();
    super.dispose();
  }

  List<UserModel> get children {
    // Only children of same class and gender
    final allChildren = widget.users
        .where((u) =>
            u.userType == UserType.child &&
            u.userClass == widget.currentUser.userClass &&
            u.gender == widget.currentUser.gender)
        .toList()
      ..sort((a, b) => a.fullName.compareTo(b.fullName));

    if (childSearchQuery.isEmpty) {
      return allChildren;
    }

    return allChildren.where((child) =>
      child.fullName.toLowerCase().contains(childSearchQuery.toLowerCase())
    ).toList();
  }

  List<UserModel> get servants {
    // Only servants of same class and gender
    final allServants = widget.users
        .where((u) =>
            u.userType == UserType.servant &&
            u.userClass == widget.currentUser.userClass &&
            u.gender == widget.currentUser.gender)
        .toList()
      ..sort((a, b) => a.fullName.compareTo(b.fullName));

    if (servantSearchQuery.isEmpty) {
      return allServants;
    }

    return allServants.where((servant) =>
      servant.fullName.toLowerCase().contains(servantSearchQuery.toLowerCase())
    ).toList();
  }

  void _createVisit() async {
    if (selectedChild == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('الرجاء اختيار مخدوم'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    if (selectedServants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('الرجاء اختيار خادم واحد على الأقل'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final visit = VisitModel(
      id: '',
      childId: selectedChild!.id,
      childName: selectedChild!.fullName,
      servantsId: selectedServants.map((s) => s.id).toList(),
      servantsNames: selectedServants.map((s) => s.fullName).toList(),
      userType: selectedChild!.userType,
      date: DateTime.now(),
      visitType: selectedVisitType,
      notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
    );

    try {
      await widget.attendanceCubit.createOrMergeVisit(visit);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('تم إضافة الإفتقاد بنجاح'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );

        // Reset form
        setState(() {
          selectedChild = null;
          selectedServants.clear();
          selectedServants.add(widget.currentUser); // Keep current user selected
          notesController.clear();
          childSearchController.clear();
          servantSearchController.clear();
          childSearchQuery = '';
          servantSearchQuery = '';
          selectedVisitType = VisitType.home;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Modern Header with gradient
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: teal300, width: 1),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: teal500,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: teal500.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.home_outlined, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إفتقاد المخدومين',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: teal900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'سجل زيارات مخدومي اسرتك',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Create Visit Card with modern design
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.shade100.withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.add_circle_outline, color: teal900, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'إضافة إفتقاد جديد',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: teal900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Child Search Field
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      controller: childSearchController,
                      onChanged: (value) {
                        setState(() {
                          childSearchQuery = value;
                          if (selectedChild != null && !children.contains(selectedChild)) {
                            selectedChild = null;
                          }
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'ابحث عن مخدوم',
                        labelStyle: TextStyle(color: teal900),
                        hintText: 'اكتب اسم المخدوم للبحث...',
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        prefixIcon: Icon(Icons.search, color: teal900),
                        suffixIcon: childSearchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: Colors.grey[600]),
                                onPressed: () {
                                  setState(() {
                                    childSearchController.clear();
                                    childSearchQuery = '';
                                  });
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Child Dropdown with modern styling
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: DropdownButtonFormField<UserModel>(
                      value: selectedChild,
                      decoration: InputDecoration(
                        labelText: 'اختر المخدوم',
                        labelStyle: TextStyle(color: teal900),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        prefixIcon: Icon(Icons.person_outline, color: teal900),
                      ),
                      dropdownColor: Colors.white,
                      items: children.map((child) {
                        return DropdownMenuItem(
                          value: child,
                          child: Text(
                            child.fullName,
                            style: const TextStyle(fontSize: 15),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedChild = value;
                        });
                      },
                    ),
                  ),
                  if (childSearchQuery.isNotEmpty && children.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'لا توجد نتائج للبحث',
                        style: TextStyle(color: Colors.orange[700], fontSize: 13),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Visit Type with icon buttons
                  Text(
                    'نوع الإفتقاد',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: teal900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: VisitType.values.map((type) {
                      final isSelected = selectedVisitType == type;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedVisitType = type;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? LinearGradient(
                                      colors: [teal500, teal300],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: isSelected ? null : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? teal500 : teal300,
                                width: 2,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: teal500.withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  type == VisitType.home ? Icons.home : Icons.phone,
                                  color: isSelected ? Colors.white : teal700,
                                  size: 28,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  type.label,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : teal900,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Servants Multi-Select with chips
                  Text(
                    'الخدام المشاركين',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: teal900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Servant Search Field
                  if (servants.length > 1)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: TextField(
                        controller: servantSearchController,
                        onChanged: (value) {
                          setState(() {
                            servantSearchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'ابحث عن خادم',
                          labelStyle: TextStyle(color: teal900),
                          hintText: 'اكتب اسم الخادم للبحث...',
                          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          prefixIcon: Icon(Icons.search, color: teal500),
                          suffixIcon: servantSearchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, color: Colors.grey[600]),
                                  onPressed: () {
                                    setState(() {
                                      servantSearchController.clear();
                                      servantSearchQuery = '';
                                    });
                                  },
                                )
                              : null,
                        ),
                      ),
                    ),
                  if (servants.length > 1) const SizedBox(height: 12),
                  if (selectedServants.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: selectedServants.map((servant) {
                        final isCurrentUser = servant.id == widget.currentUser.id;
                        return Chip(
                          avatar: CircleAvatar(
                            backgroundColor: isCurrentUser ? Colors.green : teal500,
                            child: Text(
                              servant.fullName[0],
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(servant.fullName),
                              if (isCurrentUser) ...[
                                const SizedBox(width: 4),
                                Icon(Icons.check_circle, size: 14, color: Colors.green[700]),
                              ],
                            ],
                          ),
                          deleteIcon: isCurrentUser ? null : const Icon(Icons.close, size: 18),
                          onDeleted: isCurrentUser ? null : () {
                            setState(() {
                              selectedServants.remove(servant);
                            });
                          },
                          backgroundColor: isCurrentUser ? Colors.green[50] : Colors.blue.shade50,
                          labelStyle: TextStyle(color: isCurrentUser ? Colors.green[900] : teal900),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 12),
                  if (servants.length > 1)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 150),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: servants.length,
                        itemBuilder: (context, index) {
                          final servant = servants[index];
                          final isSelected = selectedServants.contains(servant);
                          final isCurrentUser = servant.id == widget.currentUser.id;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isCurrentUser ? Colors.green[50] : Colors.blue.shade50)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: isCurrentUser ? Border.all(color: Colors.green, width: 1.5) : null,
                          ),
                          child: CheckboxListTile(
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    servant.fullName,
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected
                                          ? (isCurrentUser ? Colors.green[900] : teal900)
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                                if (isCurrentUser)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'أنت',
                                      style: TextStyle(color: Colors.white, fontSize: 10),
                                    ),
                                  ),
                              ],
                            ),
                            value: isSelected,
                            onChanged: isCurrentUser ? null : (checked) {
                              setState(() {
                                if (checked == true) {
                                  selectedServants.add(servant);
                                } else {
                                  selectedServants.remove(servant);
                                }
                              });
                            },
                            activeColor: isCurrentUser ? Colors.green : teal500,
                            checkColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Notes Field with modern design
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      controller: notesController,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 15),
                      decoration: InputDecoration(
                        labelText: 'ملاحظات (اختياري)',
                        labelStyle: TextStyle(color: teal700),
                        hintText: 'أضف أي ملاحظات حول الزيارة...',
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(bottom: 40),
                          child: Icon(Icons.note_alt_outlined, color: teal500),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit Button with gradient
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [teal500, teal300],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: teal500.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _createVisit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.check_circle_outline, color: Colors.white, size: 24),
                          SizedBox(width: 12),
                          Text(
                            'إضافة الإفتقاد',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // My Class Visits History
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [teal100, teal50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.history, color: teal700, size: 24),
                const SizedBox(width: 12),
                Text(
                  'سجل إفتقادات فصلي',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: teal900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Show visits for children in the same class
          ...children.map((child) => _buildChildVisitsSection(child)),
        ],
      ),
    );
  }

  Widget _buildChildVisitsSection(UserModel child) {
    return StreamBuilder<List<VisitModel>>(
      stream: widget.attendanceCubit.getVisitsForChild(child.id),
      builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const SizedBox.shrink();
            }

            final visits = snapshot.data!;
            visits.sort((a, b) => b.date.compareTo(a.date));

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  childrenPadding: const EdgeInsets.only(bottom: 12),
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [teal500, teal300],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: teal500.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        child.fullName[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    child.fullName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: teal900,
                    ),
                  ),
                  subtitle: Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_note, size: 14, color: teal700),
                        const SizedBox(width: 6),
                        Text(
                          'عدد الإفتقادات: ${visits.length}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: teal700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.keyboard_arrow_down, color: teal700),
                  ),
                  children: visits.map((visit) => _buildVisitTile(visit)).toList(),
                ),
              ),
            );
          },
        );
  }

  Widget _buildVisitTile(VisitModel visit) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            visit.visitType == VisitType.home
                ? Colors.blue.shade50
                : Colors.green.shade50,
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: visit.visitType == VisitType.home
              ? teal300
              : Colors.green.shade200,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: visit.visitType == VisitType.home
                          ? [teal300,teal500]
                          : [Colors.green.shade400, Colors.green.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: (visit.visitType == VisitType.home
                                ? teal900
                                : Colors.green)
                            .withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    visit.visitType == VisitType.home
                        ? Icons.home_rounded
                        : Icons.phone_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visit.visitType.label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: visit.visitType == VisitType.home
                              ? teal700
                              : Colors.green.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('yyyy-MM-dd - hh:mm a', 'ar').format(visit.date),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.people_outline, size: 16, color: teal500),
                      const SizedBox(width: 8),
                      Text(
                        'الخدام المشاركين:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: teal900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: visit.servantsNames.map((name) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: teal300),
                        ),
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: teal900,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (visit.notes != null && visit.notes!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Divider(color: Colors.grey.shade200, height: 1),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.note_alt_outlined, size: 16, color: Colors.orange[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ملاحظات:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange[900],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                visit.notes!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

