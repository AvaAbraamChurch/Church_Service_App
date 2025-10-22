// filepath: c:\Users\Andrew\Desktop\Church_Apps\Github\church\lib\modules\Profile\profile_screen.dart
import 'package:church/core/utils/gender_enum.dart';
import 'package:church/core/utils/userType_enum.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../core/models/user/user_model.dart';
import '../../core/repositories/users_reopsitory.dart';
import '../../core/services/image_upload_service.dart';
import '../../core/styles/colors.dart';
import '../../core/constants/strings.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UsersRepository _usersRepository = UsersRepository();
  final ImageUploadService _imageUploadService = ImageUploadService();
  final _formKey = GlobalKey<FormState>();

  bool isEditing = false;
  bool isLoading = false;
  File? _selectedImage;

  // Controllers
  late TextEditingController nameController;
  late TextEditingController usernameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController addressController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    usernameController = TextEditingController();
    emailController = TextEditingController();
    phoneController = TextEditingController();
    addressController = TextEditingController();
  }

  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _saveProfile(UserModel currentUser) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      String? newImageUrl = currentUser.profileImageUrl;

      // Upload new image if selected
      if (_selectedImage != null) {
        newImageUrl = await _imageUploadService.uploadProfileImage(
          _selectedImage!,
          currentUser.id,
        );
      }

      // Update user data
      final updatedData = {
        'fullName': nameController.text.trim(),
        'username': usernameController.text.trim(),
        'email': emailController.text.trim(),
        'phoneNumber': phoneController.text.trim(),
        'address': addressController.text.trim(),
        if (newImageUrl != null) 'profileImageUrl': newImageUrl,
      };

      await _usersRepository.updateUser(currentUser.id, updatedData);

      if (mounted) {
        setState(() {
          isEditing = false;
          _selectedImage = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم تحديث البيانات بنجاح'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحديث البيانات: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _cancelEdit(UserModel user) {
    setState(() {
      isEditing = false;
      _selectedImage = null;
      // Reset controllers to current user data
      nameController.text = user.fullName;
      usernameController.text = user.username;
      emailController.text = user.email;
      phoneController.text = user.phoneNumber ?? '';
      addressController.text = user.address ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      return const Scaffold(
        body: Center(child: Text('الرجاء تسجيل الدخول')),
      );
    }

    return StreamBuilder<UserModel?>(
      stream: _usersRepository.getUserByIdStream(currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: CircularProgressIndicator(color: teal500),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: Text(
                'حدث خطأ: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: Text('لم يتم العثور على بيانات المستخدم'),
            ),
          );
        }

        // Initialize controllers with user data when not editing
        if (!isEditing) {
          nameController.text = user.fullName;
          usernameController.text = user.username;
          emailController.text = user.email;
          phoneController.text = user.phoneNumber ?? '';
          addressController.text = user.address ?? '';
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: MediaQuery.of(context).padding.top),

                  // User info header
                  Text(
                    '${user.userType.label} - ${user.userClass}',
                    style: TextStyle(color: brown300, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'الملف الشخصي',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Coupon Points Card
                  _buildCouponPointsCard(user.couponPoints),
                  const SizedBox(height: 30),

                  // Profile Image
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: teal300, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: teal500.withValues(alpha: 0.3),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundImage: _selectedImage != null
                                ? FileImage(_selectedImage!)
                                : (user.profileImageUrl != null
                                    ? NetworkImage(user.profileImageUrl!)
                                    : const AssetImage('assets/images/man.png'))
                                    as ImageProvider,
                          ),
                        ),
                        if (isEditing)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: teal500,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Profile Form
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildProfileField(
                          controller: nameController,
                          label: fullName,
                          icon: Icons.person,
                          enabled: isEditing,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return enterName;
                            }
                            if (value.trim().length < 3) {
                              return nameValidation;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildProfileField(
                          controller: usernameController,
                          label: username,
                          icon: Icons.account_circle,
                          enabled: isEditing,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'الرجاء إدخال اسم المستخدم';
                            }
                            if (value.trim().length < 3) {
                              return usernameValidation;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildProfileField(
                          controller: emailController,
                          label: email,
                          icon: Icons.email,
                          enabled: false, // Email shouldn't be editable
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        _buildProfileField(
                          controller: phoneController,
                          label: phone,
                          icon: Icons.phone,
                          enabled: isEditing,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              if (value.length < 10 || value.length > 15) {
                                return phoneValidation;
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildProfileField(
                          controller: addressController,
                          label: address,
                          icon: Icons.location_on,
                          enabled: isEditing,
                          maxLines: 2,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              if (value.length < 5 || value.length > 100) {
                                return addressValidation;
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Non-editable fields
                        _buildInfoTile(
                          label: userType,
                          value: user.userType.label,
                          icon: Icons.work,
                        ),
                        const SizedBox(height: 16),
                        _buildInfoTile(
                          label: gender,
                          value: user.gender.label,
                          icon: Icons.wc,
                        ),
                        const SizedBox(height: 16),
                        _buildInfoTile(
                          label: classroom,
                          value: user.userClass,
                          icon: Icons.class_,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Action Buttons
                  if (!isEditing)
                    _buildActionButton(
                      label: edit,
                      icon: Icons.edit,
                      color: teal500,
                      onPressed: () {
                        setState(() => isEditing = true);
                      },
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            label: cancel,
                            icon: Icons.close,
                            color: Colors.grey,
                            onPressed: () => _cancelEdit(user),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildActionButton(
                            label: save,
                            icon: Icons.check,
                            color: Colors.green,
                            onPressed: isLoading ? null : () => _saveProfile(user),
                            isLoading: isLoading,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCouponPointsCard(int points) {
    return GestureDetector(
      onTap: () {
        debugPrint('Coupon Points Card Tapped');
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [teal700, teal300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: teal500.withValues(alpha: 0.4),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.star,
                color: Colors.amber,
                size: 35,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'نقاط الكوبونات',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$points نقطة',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Subtitle prompt click to view store
                  Text(
                    'اضغط لزيارة معرض الكوبونات',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withValues(alpha: 0.7),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool enabled,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: enabled
              ? teal300.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        style: TextStyle(
          color: enabled ? Colors.white : Colors.white.withValues(alpha: 0.7),
          fontSize: 16,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: enabled
                ? teal300
                : Colors.white.withValues(alpha: 0.5),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            color: enabled ? teal300 : Colors.white.withValues(alpha: 0.5),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: teal300.withValues(alpha: 0.7),
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          colors: onPressed == null
              ? [Colors.grey, Colors.grey[400]!]
              : [color, color.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: (onPressed == null ? Colors.grey : color)
                .withValues(alpha: 0.3),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            height: 56,
            alignment: Alignment.center,
            child: isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: Colors.white, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

