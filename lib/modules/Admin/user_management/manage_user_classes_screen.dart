import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:church/core/models/user/user_model.dart';
import 'package:church/core/models/class_mapping/class_mapping_model.dart';
import 'package:church/core/utils/classes_mapping.dart';
import 'package:church/core/styles/themeScaffold.dart';
import 'package:church/core/styles/colors.dart';

class ManageUserClassesScreen extends StatefulWidget {
  const ManageUserClassesScreen({super.key});

  @override
  State<ManageUserClassesScreen> createState() => _ManageUserClassesScreenState();
}

class _ManageUserClassesScreenState extends State<ManageUserClassesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _filterClass = 'all';
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _updateUserClass(String userId, String userName, String newClass) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'userClass': newClass,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تحديث صف $userName إلى ${CompetitionClassMapping.getClassName(newClass)}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل تحديث الصف: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _bulkUpdateClasses(String targetClass, String newClass) async {
    setState(() => _isLoading = true);

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('userClass', isEqualTo: targetClass)
          .get();

      final batch = _firestore.batch();
      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {
          'userClass': newClass,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تحديث ${querySnapshot.docs.length} مستخدم من ${CompetitionClassMapping.getClassName(targetClass)} إلى ${CompetitionClassMapping.getClassName(newClass)}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل التحديث الجماعي: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showBulkUpdateDialog() {
    String? fromClass;
    String? toClass;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.update, color: Colors.blue),
              SizedBox(width: 12),
              Text('تحديث جماعي للصفوف'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'تحديث كل المستخدمين في صف معين إلى صف جديد',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: fromClass,
                  decoration: InputDecoration(
                    labelText: 'من الصف',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.class_),
                  ),
                  items: CompetitionClassMapping.getAllClassCodes()
                      .where((code) => code != 'all')
                      .map((code) => DropdownMenuItem(
                            value: code,
                            child: Text(CompetitionClassMapping.getClassName(code)),
                          ))
                      .toList(),
                  onChanged: (value) => setDialogState(() => fromClass = value),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: toClass,
                  decoration: InputDecoration(
                    labelText: 'إلى الصف',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.class_),
                  ),
                  items: CompetitionClassMapping.getAllClassCodes()
                      .where((code) => code != 'all')
                      .map((code) => DropdownMenuItem(
                            value: code,
                            child: Text(CompetitionClassMapping.getClassName(code)),
                          ))
                      .toList(),
                  onChanged: (value) => setDialogState(() => toClass = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: (fromClass != null && toClass != null && fromClass != toClass)
                  ? () {
                      Navigator.pop(context);
                      _bulkUpdateClasses(fromClass!, toClass!);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('تحديث'),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateClassDialog(UserModel user) {
    String? selectedClass = user.userClass;

    showDialog(
      context: context,
      builder: (context) => StreamBuilder<List<ClassMapping>>(
        stream: ClassMappingService.getActiveClassMappings(),
        builder: (context, snapshot) {
          final classMappings = snapshot.data ?? [];

          return StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: teal500,
                    child: Text(
                      user.fullName.isNotEmpty ? user.fullName[0] : 'U',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: const TextStyle(fontSize: 18),
                        ),
                        Text(
                          'تحديث الصف',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: sage50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: sage700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FutureBuilder<ClassMapping?>(
                              future: ClassMappingService.getClassMappingById(user.userClass),
                              builder: (context, classSnapshot) {
                                final currentClassName = classSnapshot.data?.className ??
                                    CompetitionClassMapping.getClassName(user.userClass);
                                return Text(
                                  'الصف الحالي: $currentClassName',
                                  style: TextStyle(color: sage700, fontSize: 13),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const Center(child: CircularProgressIndicator())
                    else if (classMappings.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'لا توجد صفوف متاحة',
                                style: TextStyle(color: Colors.orange),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      DropdownButtonFormField<String>(
                        value: classMappings.any((m) => m.id == selectedClass) ? selectedClass : null,
                        decoration: InputDecoration(
                          labelText: 'الصف الجديد',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.class_),
                        ),
                        items: _buildClassDropdownItemsFromMappings(classMappings),
                        onChanged: (value) => setDialogState(() => selectedClass = value),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: (selectedClass != null && selectedClass != user.userClass)
                      ? () {
                          Navigator.pop(context);
                          _updateUserClass(user.id, user.fullName, selectedClass!);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: teal500,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('حفظ'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<DropdownMenuItem<String>> _buildClassDropdownItemsFromMappings(List<ClassMapping> classMappings) {
    List<DropdownMenuItem<String>> items = [];

    // Group by classCode
    final groupedMappings = <String, List<ClassMapping>>{};
    for (var mapping in classMappings) {
      groupedMappings.putIfAbsent(mapping.classCode, () => []).add(mapping);
    }

    groupedMappings.forEach((classCode, mappings) {
      // Add group header
      items.add(
        DropdownMenuItem<String>(
          value: null,
          enabled: false,
          child: Text(
            '${CompetitionClassMapping.getClassName(classCode)} ($classCode)',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ),
      );

      // Add class options
      for (var mapping in mappings) {
        items.add(
          DropdownMenuItem<String>(
            value: mapping.id,
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(mapping.className),
            ),
          ),
        );
      }
    });

    return items;
  }

  List<DropdownMenuItem<String>> _buildClassDropdownItems() {
    List<DropdownMenuItem<String>> items = [];
    final groupedOptions = CompetitionClassMapping.getGroupedClassOptions();

    groupedOptions.forEach((groupName, options) {
      // Skip "all" for individual user assignment
      if (groupName == 'عام') return;

      // Add group header
      items.add(
        DropdownMenuItem<String>(
          value: null,
          enabled: false,
          child: Text(
            groupName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ),
      );

      // Add options
      for (var option in options) {
        items.add(
          DropdownMenuItem<String>(
            value: option.key,
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(option.value),
            ),
          ),
        );
      }
    });

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return ThemedScaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(160),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [teal900, teal700, teal500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: teal900.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Column(
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
                                    Icons.school,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'إدارة صفوف المستخدمين',
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
                              'تعيين المستخدمين للصفوف الدراسية',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.update, color: Colors.white),
                        onPressed: _showBulkUpdateDialog,
                        tooltip: 'تحديث جماعي',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Search bar
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'بحث بالاسم أو البريد الإلكتروني...',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                      prefixIcon: const Icon(Icons.search, color: Colors.white),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.white),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'الكل'),
                  ...CompetitionClassMapping.getAllClassCodes()
                      .where((code) => code != 'all')
                      .map((code) => _buildFilterChip(code, CompetitionClassMapping.getClassName(code))),
                ],
              ),
            ),
          ),
          // Users list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('users')
                        .orderBy('fullName')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text('خطأ: ${snapshot.error}'),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final users = snapshot.data!.docs
                          .map((doc) {
                            try {
                              return UserModel.fromMap(
                                doc.data() as Map<String, dynamic>,
                                id: doc.id,
                              );
                            } catch (e) {
                              return null;
                            }
                          })
                          .whereType<UserModel>()
                          .where((user) {
                            // Search filter
                            if (_searchQuery.isNotEmpty) {
                              return user.fullName.toLowerCase().contains(_searchQuery) ||
                                  user.email.toLowerCase().contains(_searchQuery) ||
                                  user.username.toLowerCase().contains(_searchQuery);
                            }
                            return true;
                          })
                          .where((user) {
                            // Class filter
                            if (_filterClass != 'all') {
                              return user.userClass == _filterClass;
                            }
                            return true;
                          })
                          .toList();

                      if (users.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'لا يوجد مستخدمين',
                                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          return _buildUserCard(user);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _filterClass == value;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _filterClass = value);
        },
        backgroundColor: Colors.grey[200],
        selectedColor: teal500,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showUpdateClassDialog(user),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: teal500,
                backgroundImage: user.profileImageUrl != null
                    ? NetworkImage(user.profileImageUrl!)
                    : null,
                child: user.profileImageUrl == null
                    ? Text(
                        user.fullName.isNotEmpty ? user.fullName[0] : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: teal700
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<ClassMapping?>(
                      future: ClassMappingService.getClassMappingById(user.userClass),
                      builder: (context, classSnapshot) {
                        final className = classSnapshot.data?.className ??
                            CompetitionClassMapping.getClassName(user.userClass);

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: teal50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: teal300, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.class_, size: 16, color: teal700),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  className,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: teal700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Edit button
              Container(
                decoration: BoxDecoration(
                  color: teal50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(Icons.edit, color: teal700),
                  onPressed: () => _showUpdateClassDialog(user),
                  tooltip: 'تعديل الصف',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

