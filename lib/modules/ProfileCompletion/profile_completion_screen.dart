import 'package:church/core/constants/strings.dart';
import 'package:church/core/models/user/user_model.dart';
import 'package:church/core/repositories/users_reopsitory.dart';
import 'package:church/core/repositories/auth_repository.dart';
import 'package:church/core/repositories/classes_repository.dart';
import 'package:church/core/models/Classes/classes_model.dart';
import 'package:church/core/services/profile_completion_service.dart';
import 'package:church/core/services/image_upload_service.dart';
import 'package:church/core/styles/colors.dart';
import 'package:church/core/styles/themeScaffold.dart';
import 'package:church/core/utils/gender_enum.dart';
import 'package:church/core/utils/service_enum.dart';
import 'package:church/layout/home_layout.dart';
import 'package:church/shared/widgets.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class ProfileCompletionScreen extends StatefulWidget {
  final UserModel user;

  const ProfileCompletionScreen({super.key, required this.user});

  @override
  State<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Current step (0 = Password, 1 = Personal Info, 2 = Church Info)
  int _currentStep = 0;

  // Controllers
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;
  late TextEditingController _fullNameController;
  late TextEditingController _usernameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;

  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  Gender? _selectedGender;
  Model? _selectedClass;
  ServiceType? _selectedServiceType;
  DateTime? _birthday;
  File? _selectedImage;
  final ImageUploadService _imageService = ImageUploadService();
  final UsersRepository _userRepository = UsersRepository();
  final AuthRepository _authRepository = AuthRepository();
  final ClassesRepository _classesRepository = ClassesRepository();

  @override
  void initState() {
    super.initState();

    // Initialize password controllers
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();

    // Initialize controllers with existing data
    _fullNameController = TextEditingController(text: widget.user.fullName);
    _usernameController = TextEditingController(text: widget.user.username);
    _addressController = TextEditingController(text: widget.user.address ?? '');
    _phoneController = TextEditingController(
      text: widget.user.phoneNumber ?? '',
    );

    // Initialize gender, birthday, and service type from user model
    _selectedGender = widget.user.gender;
    _birthday = widget.user.birthday;
    _selectedServiceType = widget.user.serviceType;

    // Add listeners to update button state when text changes
    _currentPasswordController.addListener(_updateButtonState);
    _newPasswordController.addListener(_updateButtonState);
    _confirmPasswordController.addListener(_updateButtonState);
    _fullNameController.addListener(_updateButtonState);
    _usernameController.addListener(_updateButtonState);
    _addressController.addListener(_updateButtonState);
    _phoneController.addListener(_updateButtonState);

    // Setup animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  // Update button state when text changes
  void _updateButtonState() {
    setState(() {
      // This will trigger a rebuild to update the button state
    });
  }

  @override
  void dispose() {
    // Remove listeners before disposing
    _currentPasswordController.removeListener(_updateButtonState);
    _newPasswordController.removeListener(_updateButtonState);
    _confirmPasswordController.removeListener(_updateButtonState);
    _fullNameController.removeListener(_updateButtonState);
    _usernameController.removeListener(_updateButtonState);
    _addressController.removeListener(_updateButtonState);
    _phoneController.removeListener(_updateButtonState);

    _animationController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _usernameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Validators
  String? _requiredValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'هذا الحقل مطلوب';
    return null;
  }

  String? _passwordValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'كلمة المرور مطلوبة';
    if (v.length < 6) return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    return null;
  }

  String? _confirmPasswordValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'تأكيد كلمة المرور مطلوب';
    if (v != _newPasswordController.text) return 'كلمة المرور غير متطابقة';
    return null;
  }

  String? _phoneValidator(String? v) {
    if (v == null || v.trim().isEmpty) return enterPhone;
    final digits = v.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 8) return 'رقم الهاتف غير صحيح';
    return null;
  }

  // Image picker methods
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectImage,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Alexandria',
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.photo_library, color: teal500),
              title: const Text(
                selectImageFromGallery,
                style: TextStyle(fontFamily: 'Alexandria'),
              ),
              onTap: () async {
                Navigator.pop(context);
                await _pickImageFromSource(isGallery: true);
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt, color: teal500),
              title: const Text(
                takePhoto,
                style: TextStyle(fontFamily: 'Alexandria'),
              ),
              onTap: () async {
                Navigator.pop(context);
                await _pickImageFromSource(isGallery: false);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageFromSource({required bool isGallery}) async {
    try {
      final File? imageFile;
      if (isGallery) {
        imageFile = await _imageService.pickImageFromGallery();
      } else {
        imageFile = await _imageService.pickImageFromCamera();
      }

      if (imageFile != null) {
        // Validate file size
        if (!_imageService.validateImageSize(imageFile)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'حجم الصورة يجب أن يكون أقل من 2 ميجابايت',
                  style: TextStyle(fontFamily: 'Alexandria'),
                ),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
          return;
        }

        setState(() {
          _selectedImage = imageFile;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'تم اختيار الصورة بنجاح',
                style: TextStyle(fontFamily: 'Alexandria'),
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'حدث خطأ في اختيار الصورة: $e',
              style: const TextStyle(fontFamily: 'Alexandria'),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<String?> _uploadProfileImage() async {
    if (_selectedImage == null) return null;

    try {
      final String fileName =
          'profile_${widget.user.fullName}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child(fileName);

      final UploadTask uploadTask = storageRef.putFile(_selectedImage!);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _selectBirthday() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime.now().subtract(const Duration(days: 365 * 10)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: teal500,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: teal900,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _birthday = picked;
      });
    }
  }

  // Step validation
  bool _validateCurrentStep() {
    if (_currentStep == 0) {
      // Password step
      return _currentPasswordController.text.trim().isNotEmpty &&
          _newPasswordController.text.trim().isNotEmpty &&
          _confirmPasswordController.text.trim().isNotEmpty &&
          _newPasswordController.text.length >= 6 &&
          _newPasswordController.text == _confirmPasswordController.text;
    } else if (_currentStep == 1) {
      // Personal info step - now requires profile image
      return _fullNameController.text.trim().isNotEmpty &&
          _usernameController.text.trim().isNotEmpty &&
          _selectedGender != null &&
          _selectedImage != null;
    } else {
      // Church info step
      return _addressController.text.trim().isNotEmpty &&
          _phoneController.text.trim().isNotEmpty &&
          _selectedClass != null &&
          _selectedServiceType != null;
    }
  }

  void _nextStep() {
    if (!_formKey.currentState!.validate()) return;

    if (_currentStep == 1 && _selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'يرجى اختيار الجنس',
            style: TextStyle(fontFamily: 'Alexandria'),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
        _animationController.reset();
        _animationController.forward();
      });
    } else {
      _saveProfile();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _animationController.reset();
        _animationController.forward();
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'يرجى اختيار الجنس',
            style: TextStyle(fontFamily: 'Alexandria'),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // First, change the password
      await _authRepository.changePassword(
        currentPassword: _currentPasswordController.text.trim(),
        newPassword: _newPasswordController.text.trim(),
      );

      // Mark password as changed
      await ProfileCompletionService.markPasswordAsChanged(widget.user.id);

      // Upload profile image if selected
      String? profileImageUrl;
      if (_selectedImage != null) {
        profileImageUrl = await _uploadProfileImage();
      }

      // Update user data
      final updatedData = {
        'fullName': _fullNameController.text.trim(),
        'username': _usernameController.text.trim(),
        'address': _addressController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'gender': _selectedGender!.code,
        'userClass': _selectedClass!.name ?? '',
        if (_selectedServiceType != null) 'serviceType': _selectedServiceType!.key,
        if (profileImageUrl != null) 'profileImage': profileImageUrl,
        if (_birthday != null) 'birthday': _birthday,
        'firstLogin': false,
      };

      await _userRepository.updateUser(widget.user.id, updatedData);

      // Mark profile as completed
      await ProfileCompletionService.markProfileAsCompleted(widget.user.id);

      if (mounted) {
        // Navigate to home
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomeLayout(
              userId: widget.user.id,
              userType: widget.user.userType,
              userClass: _selectedClass!.name ?? '',
              gender: _selectedGender!,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'حدث خطأ: $e',
              style: const TextStyle(fontFamily: 'Alexandria'),
            ),
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
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ThemedScaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Header with step indicator
                _buildModernHeader(),

                // Step Progress Indicator
                _buildStepIndicator(),

                // Content Area
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: _buildStepContent(),
                        ),
                      ),
                    ),
                  ),
                ),

                // Navigation Buttons
                _buildNavigationButtons(),
              ],
            ),
          ),

          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: teal500.withValues(alpha: 0.3),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(
                          color: teal500,
                          strokeWidth: 5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'جاري الحفظ...',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: teal900,
                          fontFamily: 'Alexandria',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'يرجى الانتظار',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontFamily: 'Alexandria',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModernHeader() {
    final stepTitles = [
      'تغيير كلمة المرور',
      'المعلومات الشخصية',
      'معلومات الكنيسة',
    ];

    final stepIcons = [Icons.lock_reset, Icons.person, Icons.church];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [teal500, teal300],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: teal500.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  stepIcons[_currentStep],
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الخطوة ${_currentStep + 1} من 3',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontFamily: 'Alexandria',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stepTitles[_currentStep],
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Alexandria',
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

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: List.generate(3, (index) {
          final isCompleted = index < _currentStep;
          final isCurrent = index == _currentStep;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      gradient: isCompleted || isCurrent
                          ? LinearGradient(colors: [teal500, teal300])
                          : null,
                      color: isCompleted || isCurrent ? null : Colors.grey[300],
                    ),
                  ),
                ),
                if (index < 2) const SizedBox(width: 8),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildPasswordStep();
      case 1:
        return _buildPersonalInfoStep();
      case 2:
        return _buildChurchInfoStep();
      default:
        return Container();
    }
  }

  Widget _buildPasswordStep() {
    return Column(
      children: [
        // Info Card
        Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: teal100.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: teal300, width: 1),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: teal700, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'لأسباب أمنية، يجب عليك تغيير كلمة المرور الافتراضية',
                  style: TextStyle(
                    fontSize: 14,
                    color: teal900,
                    fontFamily: 'Alexandria',
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Password Fields
        _buildModernFieldCard(
          title: 'كلمة المرور الحالية',
          icon: Icons.lock,
          color: Colors.redAccent,
          child: coloredTextField(
            enabledBorder: InputBorder.none,
            prefixIcon: Icons.lock,
            fillColor: Colors.redAccent,
            controller: _currentPasswordController,
            label: 'أدخل كلمة المرور الحالية',
            validator: _requiredValidator,
            isPassword: _obscureCurrentPassword,
            suffixIcon: _obscureCurrentPassword
                ? Icons.visibility_off
                : Icons.visibility,
            suffixIconColor: Colors.white,
            suffixFunction: () {
              setState(() {
                _obscureCurrentPassword = !_obscureCurrentPassword;
              });
            },
          ),
        ),

        const SizedBox(height: 20),

        _buildModernFieldCard(
          title: 'كلمة المرور الجديدة',
          icon: Icons.lock_outline,
          color: teal500,
          child: coloredTextField(
            enabledBorder: InputBorder.none,
            prefixIcon: Icons.lock_outline,
            fillColor: teal500,
            controller: _newPasswordController,
            label: 'أدخل كلمة المرور الجديدة',
            validator: _passwordValidator,
            isPassword: _obscureNewPassword,
            suffixIcon: _obscureNewPassword
                ? Icons.visibility_off
                : Icons.visibility,
            suffixIconColor: Colors.white,
            suffixFunction: () {
              setState(() {
                _obscureNewPassword = !_obscureNewPassword;
              });
            },
          ),
        ),

        const SizedBox(height: 20),

        _buildModernFieldCard(
          title: 'تأكيد كلمة المرور',
          icon: Icons.check_circle_outline,
          color: teal700,
          child: coloredTextField(
            enabledBorder: InputBorder.none,
            prefixIcon: Icons.check_circle_outline,
            fillColor: teal700,
            controller: _confirmPasswordController,
            label: 'أعد إدخال كلمة المرور',
            validator: _confirmPasswordValidator,
            isPassword: _obscureConfirmPassword,
            suffixIcon: _obscureConfirmPassword
                ? Icons.visibility_off
                : Icons.visibility,
            suffixIconColor: Colors.white,
            suffixFunction: () {
              setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoStep() {
    return Column(
      children: [
        // Info Card
        Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: brown300.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: brown300, width: 1),
          ),
          child: Row(
            children: [
              Icon(Icons.person_outline, color: brown300, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'أدخل معلوماتك الشخصية',
                  style: TextStyle(
                    fontSize: 14,
                    color: teal900,
                    fontFamily: 'Alexandria',
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),

        _buildModernFieldCard(
          title: 'الاسم الكامل',
          icon: Icons.person,
          color: brown300,
          child: coloredTextField(
            enabledBorder: InputBorder.none,
            prefixIcon: Icons.person,
            fillColor: brown300,
            controller: _fullNameController,
            label: fullName,
            validator: _requiredValidator,
          ),
        ),

        const SizedBox(height: 20),

        _buildModernFieldCard(
          title: 'اسم المستخدم',
          icon: Icons.badge,
          color: red500,
          child: coloredTextField(
            enabledBorder: InputBorder.none,
            prefixIcon: Icons.badge,
            fillColor: red500,
            controller: _usernameController,
            label: username,
            validator: _requiredValidator,
          ),
        ),

        const SizedBox(height: 20),

        // Gender Selection
        _buildModernFieldCard(
          title: 'الجنس',
          icon: Icons.transgender,
          color: Colors.pinkAccent,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildGenderOption(Gender.male, 'ذكر', Icons.male),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildGenderOption(
                    Gender.female,
                    'أنثى',
                    Icons.female,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Birthday field
        _buildModernFieldCard(
          title: 'تاريخ الميلاد',
          icon: Icons.cake,
          color: Colors.purple,
          child: GestureDetector(
            onTap: _selectBirthday,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.purple, Colors.deepPurple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.cake_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تاريخ الميلاد',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontFamily: 'Alexandria',
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _birthday != null
                              ? '${_birthday!.day}/${_birthday!.month}/${_birthday!.year}'
                              : 'اضغط لاختيار تاريخ الميلاد',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'Alexandria',
                            fontWeight: _birthday != null ? FontWeight.w500 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.calendar_today_rounded,
                    color: Colors.white.withValues(alpha: 0.7),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Profile Image Picker
        _buildModernFieldCard(
          title: 'صورة الملف الشخصي',
          icon: Icons.image,
          color: teal700,
          child: GestureDetector(
            onTap: _showImageSourceDialog,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: teal700, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: teal700.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipOval(
                    child: _selectedImage != null
                        ? Image.file(
                            _selectedImage!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              color: teal700,
                              size: 28,
                            ),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _selectedImage != null
                          ? 'تم اختيار صورة'
                          : 'اختر صورة للملف الشخصي',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderOption(Gender gender, String label, IconData icon) {
    final isSelected = _selectedGender == gender;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = gender;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white
              : Colors.white.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.pinkAccent : Colors.white,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.pinkAccent : Colors.white,
                fontFamily: 'Alexandria',
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Icon(Icons.check_circle, color: Colors.pinkAccent, size: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChurchInfoStep() {
    return Column(
      children: [
        // Info Card
        Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: sage500.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: sage500, width: 1),
          ),
          child: Row(
            children: [
              Icon(Icons.church, color: sage500, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'أدخل معلومات الكنيسة الخاصة بك',
                  style: TextStyle(
                    fontSize: 14,
                    color: teal900,
                    fontFamily: 'Alexandria',
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),

        _buildModernFieldCard(
          title: 'العنوان',
          icon: Icons.location_on,
          color: sage500,
          child: coloredTextField(
            enabledBorder: InputBorder.none,
            prefixIcon: Icons.location_on,
            fillColor: sage500,
            controller: _addressController,
            label: address,
            validator: _requiredValidator,
          ),
        ),

        const SizedBox(height: 20),

        _buildModernFieldCard(
          title: 'رقم الهاتف',
          icon: Icons.phone,
          color: tawny,
          child: coloredTextField(
            enabledBorder: InputBorder.none,
            prefixIcon: Icons.phone,
            fillColor: tawny,
            controller: _phoneController,
            label: phone,
            keyboardType: TextInputType.phone,
            validator: _phoneValidator,
          ),
        ),

        const SizedBox(height: 20),

        // Class Dropdown from Database
        _buildModernFieldCard(
          title: 'الفصل / الخدمة',
          icon: Icons.class_,
          color: teal500,
          child: StreamBuilder<List<Model>>(
            stream: _classesRepository.getAllClasses(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [teal500, Color(0xFF007D8A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        spreadRadius: 0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'جاري تحميل الأسر...',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Alexandria',
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (snapshot.hasError) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: red500.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: red500, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: red500.withValues(alpha: 0.2),
                        blurRadius: 10,
                        spreadRadius: 0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: red500, size: 24),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'خطأ في تحميل الأسر',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Alexandria',
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final classes = snapshot.data ?? [];

              if (classes.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.2),
                        blurRadius: 10,
                        spreadRadius: 0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_rounded, color: Colors.orange, size: 24),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'لا توجد أسر متاحة حالياً',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Alexandria',
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [teal500, Color(0xFF007D8A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: DropdownButtonFormField<Model>(
                    value: _selectedClass,
                    decoration: InputDecoration(
                      hintText: 'اختر الفصل / الخدمة',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontFamily: 'Alexandria',
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.group_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                    ),
                    dropdownColor: teal500,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'Alexandria',
                    ),
                    icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.white, size: 28),
                    items: classes.map((classItem) {
                      return DropdownMenuItem<Model>(
                        value: classItem,
                        child: Text(
                          classItem.name ?? '',
                          style: const TextStyle(
                            fontFamily: 'Alexandria',
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (Model? value) {
                      setState(() => _selectedClass = value);
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'الرجاء اختيار الفصل / الخدمة';
                      }
                      return null;
                    },
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 20),

        // Service Type Dropdown
        _buildModernFieldCard(
          title: 'نوع الخدمة',
          icon: Icons.church,
          color: brown300,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [brown300, Color(0xFFCDA86C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: DropdownButtonFormField<ServiceType>(
              value: _selectedServiceType,
              decoration: InputDecoration(
                hintText: 'اختر نوع الخدمة',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontFamily: 'Alexandria',
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.calendar_view_week_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
              ),
              dropdownColor: brown300,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'Alexandria',
              ),
              icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.white, size: 28),
              items: ServiceType.values.map((service) {
                return DropdownMenuItem<ServiceType>(
                  value: service,
                  child: Text(
                    service.displayName,
                    style: const TextStyle(
                      fontFamily: 'Alexandria',
                    ),
                  ),
                );
              }).toList(),
              onChanged: (ServiceType? value) {
                setState(() => _selectedServiceType = value);
              },
              validator: (value) {
                if (value == null) {
                  return 'الرجاء اختيار نوع الخدمة';
                }
                return null;
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernFieldCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 8),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: teal900,
                  fontFamily: 'Alexandria',
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    final canGoNext = _validateCurrentStep();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back Button
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: teal500, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_back, color: teal500),
                    const SizedBox(width: 8),
                    Text(
                      'السابق',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: teal500,
                        fontFamily: 'Alexandria',
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (_currentStep > 0) const SizedBox(width: 16),

          // Next/Finish Button
          Expanded(
            flex: _currentStep == 0 ? 1 : 1,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: canGoNext
                    ? LinearGradient(
                        colors: [teal700, teal300],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: canGoNext ? null : Colors.grey[400],
                boxShadow: canGoNext
                    ? [
                        BoxShadow(
                          color: teal500.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: canGoNext && !_isLoading ? _nextStep : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentStep == 2 ? 'إنهاء' : 'التالي',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Alexandria',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _currentStep == 2 ? Icons.check : Icons.arrow_forward,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
