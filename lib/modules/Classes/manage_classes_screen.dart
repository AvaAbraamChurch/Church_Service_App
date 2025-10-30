import 'package:church/core/blocs/classes/classes_cubit.dart';
import 'package:church/core/blocs/classes/classes_states.dart';
import 'package:church/core/models/Classes/classes_model.dart';
import 'package:church/core/models/user/user_model.dart';
import 'package:church/core/repositories/users_reopsitory.dart';
import 'package:church/core/styles/colors.dart';
import 'package:church/core/utils/userType_enum.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Screen for managing class names - Accessible only to Priests and Super Servants
class ManageClassesScreen extends StatefulWidget {
  const ManageClassesScreen({super.key});

  @override
  State<ManageClassesScreen> createState() => _ManageClassesScreenState();
}

class _ManageClassesScreenState extends State<ManageClassesScreen> {
  final UsersRepository _usersRepository = UsersRepository();
  late ClassesCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = ClassesCubit();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  // Check if user has permission (Priest or Super Servant)
  bool _hasPermission(UserModel user) {
    return user.userType == UserType.priest ||
        user.userType == UserType.superServant;
  }

  // Show add/edit dialog with modern design
  void _showClassDialog({Model? classToEdit}) {
    final TextEditingController nameController = TextEditingController(
      text: classToEdit?.name ?? '',
    );
    final TextEditingController descriptionController = TextEditingController(
      text: classToEdit?.description ?? '',
    );
    final isEditing = classToEdit != null;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, sage50],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon header
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [teal500, teal700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: teal500.withValues(alpha: 0.4),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    isEditing ? Icons.edit_rounded : Icons.add_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 20),
                // Title
                Text(
                  isEditing ? 'تعديل الأسرة' : 'إضافة أسرة جديدة',
                  style: const TextStyle(
                    color: teal700,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Name input field
                TextField(
                  controller: nameController,
                  textAlign: TextAlign.right,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'اسم الأسرة',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: const Icon(Icons.group_rounded, color: teal500),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: teal500, width: 2),
                    ),
                  ),
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                // Description input field
                TextField(
                  controller: descriptionController,
                  textAlign: TextAlign.right,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'الوصف (اختياري)',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 50),
                      child: Icon(Icons.description_rounded, color: teal500),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: teal500, width: 2),
                    ),
                  ),
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 28),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'إلغاء',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () async {
                          final name = nameController.text.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              _buildSnackBar('الرجاء إدخال اسم الأسرة', isError: true),
                            );
                            return;
                          }

                          final description = descriptionController.text.trim();
                          Navigator.pop(dialogContext);

                          if (isEditing) {
                            await _cubit.updateClass(
                              classToEdit.id!,
                              name,
                              description: description.isEmpty ? null : description,
                            );
                          } else {
                            await _cubit.addClass(
                              name,
                              description: description.isEmpty ? null : description,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: teal500,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          isEditing ? 'تحديث' : 'إضافة',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Show delete confirmation dialog with modern design
  void _showDeleteDialog(Model classToDelete) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Warning icon
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [red500, Color(0xFFFF6B7A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: red500.withValues(alpha: 0.4),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              // Title
              const Text(
                'تأكيد الحذف',
                style: TextStyle(
                  color: red500,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Content
              Text(
                'هل أنت متأكد من حذف "${classToDelete.name}"؟',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'لا يمكن التراجع عن هذا الإجراء',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'إلغاء',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(dialogContext);
                        await _cubit.deleteClass(classToDelete.id!);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: red500,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'حذف',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build custom snackbar
  SnackBar _buildSnackBar(String message, {bool isError = false}) {
    return SnackBar(
      content: Text(
        message,
        style: const TextStyle(fontSize: 16),
        textAlign: TextAlign.right,
      ),
      backgroundColor: isError ? red500 : Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      return Scaffold(
        backgroundColor: sage50,
        body: const Center(
          child: Text(
            'الرجاء تسجيل الدخول',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ),
      );
    }

    return StreamBuilder<UserModel?>(
      stream: _usersRepository.getUserByIdStream(currentUserId),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: sage50,
            body: const Center(
              child: CircularProgressIndicator(color: teal500),
            ),
          );
        }

        if (userSnapshot.hasError || !userSnapshot.hasData) {
          return Scaffold(
            backgroundColor: sage50,
            body: const Center(
              child: Text(
                'حدث خطأ في تحميل البيانات',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ),
          );
        }

        final currentUser = userSnapshot.data!;

        // Check permission
        if (!_hasPermission(currentUser)) {
          return Scaffold(
            backgroundColor: sage50,
            appBar: AppBar(
              title: const Text(
                'إدارة الأسر',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: teal500,
              centerTitle: true,
              elevation: 0,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'عذراً، ليس لديك صلاحية للوصول',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'هذه الصفحة متاحة فقط للكهنة وأمناء الخدمة',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        // User has permission, show the management screen
        return BlocProvider.value(
          value: _cubit,
          child: BlocConsumer<ClassesCubit, ClassesState>(
            listener: (context, state) {
              if (state is ClassAdded) {
                ScaffoldMessenger.of(context).showSnackBar(
                  _buildSnackBar('تمت إضافة الأسرة بنجاح'),
                );
              } else if (state is ClassUpdated) {
                ScaffoldMessenger.of(context).showSnackBar(
                  _buildSnackBar('تم تحديث الأسرة بنجاح'),
                );
              } else if (state is ClassDeleted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  _buildSnackBar('تم حذف الأسرة بنجاح'),
                );
              } else if (state is ClassValidationError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  _buildSnackBar(state.message, isError: true),
                );
              } else if (state is ClassesError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  _buildSnackBar(state.message, isError: true),
                );
              }
            },
            builder: (context, state) {
              return Scaffold(
                backgroundColor: sage50,
                appBar: AppBar(
                  title: const Text(
                    'إدارة الأسر',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  backgroundColor: teal500,
                  centerTitle: true,
                  elevation: 0,
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            currentUser.userType.label,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                body: StreamBuilder<List<Model>>(
                  stream: _cubit.getAllClassesStream(),
                  builder: (context, classesSnapshot) {
                    if (classesSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: teal500),
                      );
                    }

                    if (classesSnapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 60,
                              color: red500,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'حدث خطأ: ${classesSnapshot.error}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    final classes = classesSnapshot.data ?? [];

                    if (classes.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.folder_open,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'لا توجد أسر بعد',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'اضغط على زر + لإضافة أسرة جديدة',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: classes.length,
                      itemBuilder: (context, index) {
                        final classItem = classes[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.white, sage50.withValues(alpha: 0.3)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: teal500.withValues(alpha: 0.1),
                                blurRadius: 10,
                                spreadRadius: 0,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _showClassDialog(classToEdit: classItem),
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    // Icon with gradient background
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [teal500, teal700],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: teal500.withValues(alpha: 0.3),
                                            blurRadius: 8,
                                            spreadRadius: 0,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.group_rounded,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // Class name and description
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            classItem.name ?? '',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: teal700,
                                            ),
                                            textAlign: TextAlign.right,
                                          ),
                                          if (classItem.description != null &&
                                              classItem.description!.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              classItem.description!,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                              textAlign: TextAlign.right,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Action buttons
                                    Container(
                                      decoration: BoxDecoration(
                                        color: teal500.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit_rounded,
                                              color: teal500,
                                              size: 22,
                                            ),
                                            onPressed: () => _showClassDialog(
                                              classToEdit: classItem,
                                            ),
                                            tooltip: 'تعديل',
                                          ),
                                          Container(
                                            width: 1,
                                            height: 24,
                                            color: Colors.grey[300],
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_rounded,
                                              color: red500,
                                              size: 22,
                                            ),
                                            onPressed: () => _showDeleteDialog(classItem),
                                            tooltip: 'حذف',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                floatingActionButton: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: const LinearGradient(
                      colors: [teal500, teal700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: teal500.withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: FloatingActionButton.extended(
                    onPressed: () => _showClassDialog(),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    label: const Text(
                      'إضافة أسرة جديدة',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
              );
            },
          ),
        );
      },
    );
  }
}

