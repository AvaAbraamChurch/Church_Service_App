import 'package:flutter/material.dart';
import 'package:church/core/models/class_mapping/class_mapping_model.dart';
import 'package:church/core/utils/classes_mapping.dart';
import 'package:church/core/styles/themeScaffold.dart';
import 'package:church/core/styles/colors.dart';

class ManageClassMappingsScreen extends StatefulWidget {
  const ManageClassMappingsScreen({super.key});

  @override
  State<ManageClassMappingsScreen> createState() => _ManageClassMappingsScreenState();
}

class _ManageClassMappingsScreenState extends State<ManageClassMappingsScreen> {
  String _filterClassCode = 'all';

  void _showAddEditDialog({ClassMapping? mapping}) {
    final isEditing = mapping != null;
    String? selectedClassCode = mapping?.classCode ?? '1&2';
    final classNameController = TextEditingController(text: mapping?.className ?? '');
    final descriptionController = TextEditingController(text: mapping?.description ?? '');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: teal500.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isEditing ? Icons.edit : Icons.add,
                  color: teal700,
                ),
              ),
              const SizedBox(width: 12),
              Text(isEditing ? 'تعديل الصف' : 'إضافة صف جديد'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Class Code Dropdown
                DropdownButtonFormField<String>(
                  value: selectedClassCode,
                  decoration: InputDecoration(
                    labelText: 'رمز الصف *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.tag),
                  ),
                  items: CompetitionClassMapping.getAllClassCodes()
                      .where((code) => code != 'all')
                      .map((code) => DropdownMenuItem(
                            value: code,
                            child: Text('${CompetitionClassMapping.getClassName(code)} ($code)'),
                          ))
                      .toList(),
                  onChanged: (value) => setDialogState(() => selectedClassCode = value),
                ),
                const SizedBox(height: 16),
                // Class Name
                TextField(
                  controller: classNameController,
                  decoration: InputDecoration(
                    labelText: 'اسم الصف *',
                    hintText: 'مثال: اسرة القديس استفانوس',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.class_),
                  ),
                ),
                const SizedBox(height: 16),
                // Description
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'الوصف (اختياري)',
                    hintText: 'وصف اختياري للصف',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.description),
                  ),
                  maxLines: 3,
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
              onPressed: () async {
                if (selectedClassCode == null || classNameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('يرجى ملء الحقول المطلوبة'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  final newMapping = ClassMapping(
                    id: mapping?.id ?? '',
                    classCode: selectedClassCode!,
                    className: classNameController.text.trim(),
                    description: descriptionController.text.trim(),
                    isActive: mapping?.isActive ?? true,
                    createdAt: mapping?.createdAt,
                  );

                  if (isEditing) {
                    await ClassMappingService.updateClassMapping(mapping.id, newMapping);
                  } else {
                    await ClassMappingService.createClassMapping(newMapping);
                  }

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEditing ? 'تم تحديث الصف بنجاح' : 'تم إضافة الصف بنجاح'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('خطأ: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: teal500,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(isEditing ? 'حفظ' : 'إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(ClassMapping mapping) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 12),
            Text('تأكيد الحذف'),
          ],
        ),
        content: Text('هل أنت متأكد من حذف "${mapping.className}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ClassMappingService.deleteClassMapping(mapping.id);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم حذف الصف بنجاح'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('خطأ في الحذف: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('حذف'),
          ),
        ],
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
                                    Icons.settings_applications,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'إدارة تعيينات الصفوف',
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
                              'إضافة وتعديل أسماء الصفوف',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.add, color: Colors.white),
                          onPressed: () => _showAddEditDialog(),
                          tooltip: 'إضافة صف جديد',
                        ),
                      ),
                    ],
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
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'الكل'),
                  ...CompetitionClassMapping.getAllClassCodes()
                      .where((code) => code != 'all')
                      .map((code) => _buildFilterChip(
                            code,
                            CompetitionClassMapping.getClassName(code),
                          )),
                ],
              ),
            ),
          ),
          // Mappings list
          Expanded(
            child: StreamBuilder<List<ClassMapping>>(
              stream: ClassMappingService.getClassMappings(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('خطأ: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allMappings = snapshot.data ?? [];
                final filteredMappings = _filterClassCode == 'all'
                    ? allMappings
                    : allMappings.where((m) => m.classCode == _filterClassCode).toList();

                if (filteredMappings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.class_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'لا توجد صفوف',
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () => _showAddEditDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('إضافة صف جديد'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: teal500,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredMappings.length,
                  itemBuilder: (context, index) {
                    final mapping = filteredMappings[index];
                    return _buildMappingCard(mapping);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: teal500,
        icon: const Icon(Icons.add, color: Colors.white,),
        label: const Text('إضافة صف', style: TextStyle(color: Colors.white),),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _filterClassCode == value;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _filterClassCode = value);
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

  Widget _buildMappingCard(ClassMapping mapping) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: teal50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: teal300, width: 1),
                  ),
                  child: Text(
                    mapping.classCode,
                    style: TextStyle(
                      color: teal700,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: sage50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sage300, width: 1),
                  ),
                  child: Text(
                    CompetitionClassMapping.getClassName(mapping.classCode),
                    style: TextStyle(
                      color: sage700,
                      fontSize: 11,
                    ),
                  ),
                ),
                const Spacer(),
                Switch(
                  value: mapping.isActive,
                  onChanged: (value) {
                    ClassMappingService.toggleClassMappingStatus(mapping.id, value);
                  },
                  activeColor: teal500,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              mapping.className,
              style: const TextStyle(
                color: teal700,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (mapping.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                mapping.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showAddEditDialog(mapping: mapping),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('تعديل'),
                  style: TextButton.styleFrom(
                    foregroundColor: teal700,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _showDeleteConfirmation(mapping),
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('حذف'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
