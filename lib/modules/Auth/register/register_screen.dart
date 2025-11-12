import 'package:church/core/blocs/auth/auth_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

import '../../../core/blocs/auth/auth_cubit.dart';
import '../../../core/constants/strings.dart';
import '../../../core/styles/colors.dart';
import '../../../core/styles/themeScaffold.dart';
import '../../../shared/widgets.dart';
import '../../../core/utils/gender_enum.dart';
import '../../../core/utils/userType_enum.dart';
import '../../../core/utils/service_enum.dart';
import '../../../core/services/image_upload_service.dart';
import '../../../core/repositories/classes_repository.dart';
import '../../../core/models/Classes/classes_model.dart';
import '../login/login_screen.dart';
import 'registration_status_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Dropdown selections
  Gender? _gender;
  UserType? _userType;
  Model? _selectedClass;
  ServiceType? _selectedServiceType;
  DateTime? _birthday;

  // Image selection
  File? _selectedImage;
  final ImageUploadService _imageService = ImageUploadService();
  final ClassesRepository _classesRepository = ClassesRepository();

  // Paging
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  String? _requiredValidator(String? v) {
    if (v == null || v.trim().isEmpty) return fillAllFields;
    return null;
  }

  String? _emailValidator(String? v) {
    if (v == null || v.trim().isEmpty) return enterEmail;
    final s = v.trim();
    if (!s.contains('@') || !s.contains('.')) return invalidEmail;
    return null;
  }

  String? _phoneValidator(String? v) {
    if (v == null || v.trim().isEmpty) return enterPhone;
    final digits = v.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 8) return enterPhone;
    return null;
  }

  String? _passwordValidator(String? v) {
    if (v == null || v.trim().isEmpty) return enterPassword;
    if (v.trim().length < 6) return weakPassword;
    return null;
  }

  String? _confirmValidator(String? v) {
    if (v == null || v.trim().isEmpty) return passwordsDoNotMatch;
    if (v != _passwordController.text) return passwordsDoNotMatch;
    return null;
  }

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
                await _pickImage(ImageSource.gallery);
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
                await _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final File? imageFile;
      if (source == ImageSource.gallery) {
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
                content: Text(imageTooLarge),
                backgroundColor: Colors.red,
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
              content: Text(imageSelected),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onSave(AuthCubit cubit) async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    if (_gender == null || _userType == null || _selectedClass == null || _selectedServiceType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(fillAllFields)),
      );
      return;
    }

    // Validate image is selected
    // if (_selectedImage == null) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text(imageRequired)),
    //   );
    //   return;
    // }

    // Show loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: teal100,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: teal300.withValues(alpha: 0.3),
                        blurRadius: 15,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        color: teal500,
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _selectedImage != null ? uploadingImage : submittingRegistrationRequest,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: teal900,
                    fontFamily: 'Alexandria',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  loading,
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
      );
    }

    try {
      // Create user account with profile image
      final data = {
        'fullName': _fullNameController.text.trim(),
        'username': _usernameController.text.trim(),
        'gender': _gender!.code, // String code 'M' or 'F'
        'address': _addressController.text.trim(),
        'email': _emailController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'userType': _userType!.code, // String code 'PR', 'SS', 'SV' or 'CH'
        'userClass': _selectedClass!.name ?? '', // Use selected class name
        'serviceType': _selectedServiceType!.key, // Service type key
        if (_birthday != null) 'birthday': _birthday,
      };

      await cubit.signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        extraData: data,
        profileImage: _selectedImage,
      );
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (BuildContext context) => AuthCubit(),
      child: BlocConsumer<AuthCubit, AuthState>(
        builder: (BuildContext context, state) {
          final cubit = AuthCubit.get(context);
          return ThemedScaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    // Header with gradient
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [teal500.withValues(alpha: 0.2), teal700.withValues(alpha: 0.1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            register,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Alexandria',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'املأ البيانات لإنشاء حسابك',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 16,
                              fontFamily: 'Alexandria',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Modern Step indicator
                    _buildStepIndicator(),
                    const SizedBox(height: 24),

                    // Form with horizontal paging
                    Expanded(
                      child: Form(
                        key: _formKey,
                        child: PageView(
                          controller: _pageController,
                          onPageChanged: (i) => setState(() => _currentPage = i),
                          children: [
                            _buildPersonalInfoPage(),
                            _buildAccountInfoPage(),
                            _buildChurchInfoPage(),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Navigation buttons
                    Row(
                      children: [
                        if (_currentPage > 0)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                _pageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                              icon: const Icon(Icons.arrow_back_rounded),
                              label: Text(back),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white, width: 2),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Alexandria',
                                ),
                              ),
                            ),
                          ),
                        if (_currentPage > 0) const SizedBox(width: 12),
                        Expanded(
                          flex: _currentPage > 0 ? 2 : 1,
                          child: ElevatedButton(
                            onPressed: () {
                              if (_currentPage < 2) {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              } else {
                                _onSave(cubit);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: teal100,
                              foregroundColor: teal900,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Alexandria',
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_currentPage < 2 ? next : save),
                                const SizedBox(width: 8),
                                Icon(
                                  _currentPage < 2 ? Icons.arrow_forward_rounded : Icons.check_rounded,
                                  size: 24,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Login redirect
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => LoginScreen()),
                          );
                        },
                        child: Text(
                          alreadyHaveAccount,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'Alexandria',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        listener: (BuildContext context, state) {
          if (state is AuthLoading) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => Center(
                child: Dialog(
                  backgroundColor: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: teal100,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: teal300.withValues(alpha: 0.3),
                                blurRadius: 15,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: Center(
                            child: SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                color: teal500,
                                strokeWidth: 3,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          submittingRegistrationRequest,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: teal900,
                            fontFamily: 'Alexandria',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          } else {
            Navigator.of(context, rootNavigator: true).pop(); // Close loading dialog if open
          }

          if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 4),
              ),
            );
          } else if (state is AuthRegistrationRequestSubmitted) {
            // Navigate to registration status screen
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(registrationRequestSubmitted),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
            navigateAndFinish(
              context,
              RegistrationStatusScreen(
                requestId: state.requestId,
                email: state.email,
              ),
            );
          } else if (state is AuthSuccess) {
            // This shouldn't happen with the new flow, but keep for backwards compatibility
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(registrationSuccessful)),
            );
            navigateAndFinish(context, LoginScreen());
          }
        },
      ),
    );
  }

  // Modern step indicator with circles
  Widget _buildStepIndicator() {
    return Row(
      children: List.generate(3, (index) {
        final isActive = index <= _currentPage;
        final isCompleted = index < _currentPage;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? teal300
                        : isActive
                            ? teal500.withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isActive
                      ? const LinearGradient(
                          colors: [teal500, teal700],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isActive ? null : Colors.white.withValues(alpha: 0.2),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: teal500.withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.5),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            fontFamily: 'Alexandria',
                          ),
                        ),
                ),
              ),
              if (index < 2) const SizedBox(width: 8),
            ],
          ),
        );
      }),
    );
  }

  // Page 1: Personal Information
  Widget _buildPersonalInfoPage() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'المعلومات الشخصية',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Alexandria',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'أدخل بياناتك الشخصية الأساسية',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
              fontFamily: 'Alexandria',
            ),
          ),
          const SizedBox(height: 24),

          // Profile Image Selection
          Center(
            child: GestureDetector(
              onTap: _showImageSourceDialog,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _selectedImage != null
                      ? null
                      : LinearGradient(
                          colors: [teal500.withValues(alpha: 0.3), teal700.withValues(alpha: 0.2)],
                        ),
                  border: Border.all(
                    color: teal300,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: teal500.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: _selectedImage != null
                    ? ClipOval(
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                          width: 130,
                          height: 130,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_rounded,
                            size: 48,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            selectImage,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                              fontFamily: 'Alexandria',
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '(اختياري)',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                              fontFamily: 'Alexandria',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'الحد الأقصى 2 ميجابايت',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
                fontFamily: 'Alexandria',
              ),
            ),
          ),
          const SizedBox(height: 32),

          _buildModernTextField(
            controller: _fullNameController,
            label: fullName,
            icon: Icons.person_rounded,
            validator: _requiredValidator,
            gradient: const LinearGradient(
              colors: [brown300, Color(0xFFCDA86C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          const SizedBox(height: 20),

          _buildModernTextField(
            controller: _usernameController,
            label: username,
            icon: Icons.account_circle_rounded,
            validator: _requiredValidator,
            gradient: const LinearGradient(
              colors: [sage100, sage500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          const SizedBox(height: 20),

          _buildModernGenderDropdown(),
          const SizedBox(height: 20),

          _buildModernTextField(
            controller: _addressController,
            label: address,
            icon: Icons.location_on_rounded,
            validator: _requiredValidator,
            gradient: const LinearGradient(
              colors: [tawny, Color(0xFFD0A377)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          const SizedBox(height: 20),

          _buildBirthdayField(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Page 2: Account Information
  Widget _buildAccountInfoPage() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'معلومات الحساب',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Alexandria',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'أدخل بيانات تسجيل الدخول الخاصة بك',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
              fontFamily: 'Alexandria',
            ),
          ),
          const SizedBox(height: 32),

          _buildModernTextField(
            controller: _emailController,
            label: email,
            icon: Icons.email_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: _emailValidator,
            gradient: const LinearGradient(
              colors: [brown300, Color(0xFFCDA86C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          const SizedBox(height: 20),

          _buildModernTextField(
            controller: _phoneController,
            label: phone,
            icon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
            validator: _phoneValidator,
            gradient: const LinearGradient(
              colors: [sage100, sage500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          const SizedBox(height: 20),

          _buildModernTextField(
            controller: _passwordController,
            label: password,
            icon: Icons.lock_rounded,
            isPassword: true,
            validator: _passwordValidator,
            gradient: const LinearGradient(
              colors: [tawny, Color(0xFFD0A377)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          const SizedBox(height: 20),

          _buildModernTextField(
            controller: _confirmPasswordController,
            label: confirmPassword,
            icon: Icons.lock_outline_rounded,
            isPassword: true,
            validator: _confirmValidator,
            gradient: const LinearGradient(
              colors: [teal500, teal700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Page 3: Church Information
  Widget _buildChurchInfoPage() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'معلومات الكنيسة',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Alexandria',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'أدخل معلومات خدمتك في الكنيسة',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
              fontFamily: 'Alexandria',
            ),
          ),
          const SizedBox(height: 32),

          _buildModernUserTypeDropdown(),

          const SizedBox(height: 20),
          // Service Type Dropdown
          _buildServiceTypeDropdown(),

          const SizedBox(height: 20),

          // Classes Dropdown from Database
          StreamBuilder<List<Model>>(
            stream: _classesRepository.getAllClasses(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [brown300, Color(0xFFCDA86C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
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
                    borderRadius: BorderRadius.circular(16),
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
                    borderRadius: BorderRadius.circular(16),
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
                    colors: [brown300, Color(0xFFCDA86C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
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
                      hintText: selectClassroom,
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontFamily: 'Alexandria',
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.group_rounded,
                        color: Colors.white,
                        size: 20,
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
                        return 'الرجاء اختيار الأسرة';
                      }
                      return null;
                    },
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  teal500.withValues(alpha: 0.2),
                  teal700.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: teal300.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_rounded,
                  color: teal300,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'تأكد من اختيار الأسرة الصحيحة التي تنتمي إليها',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                      fontFamily: 'Alexandria',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Modern text field with gradient background and shadow
  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Gradient gradient,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: isPassword,
        textAlign: TextAlign.right,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontFamily: 'Alexandria',
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontFamily: 'Alexandria',
            fontSize: 16,
          ),
          floatingLabelStyle: const TextStyle(
            color: Colors.white,
            fontFamily: 'Alexandria',
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          prefixIcon: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          errorStyle: const TextStyle(
            fontFamily: 'Alexandria',
            fontSize: 12,
          ),
        ),
        validator: validator,
      ),
    );
  }

  // Modern gender dropdown with gradient
  Widget _buildModernGenderDropdown() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [sage500, Color(0xFFB8BF9D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonFormField<Gender>(
        value: _gender,
        decoration: InputDecoration(
          hintText: gender,
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontFamily: 'Alexandria',
            fontSize: 16,
          ),
          prefixIcon: const Icon(
            Icons.wc_rounded,
            color: Colors.white,
            size: 24,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
        dropdownColor: sage500,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontFamily: 'Alexandria',
        ),
        icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.white, size: 28),
        items: const [
          DropdownMenuItem(
            value: Gender.male,
            child: Text(
              male,
              style: TextStyle(fontFamily: 'Alexandria'),
            ),
          ),
          DropdownMenuItem(
            value: Gender.female,
            child: Text(
              female,
              style: TextStyle(fontFamily: 'Alexandria'),
            ),
          ),
        ],
        onChanged: (Gender? value) {
          setState(() => _gender = value);
        },
        validator: (value) {
          if (value == null) {
            return 'الرجاء اختيار الجنس';
          }
          return null;
        },
      ),
    );
  }

  // Birthday field with date picker
  Widget _buildBirthdayField() {
    return GestureDetector(
      onTap: _selectBirthday,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [teal500, teal700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
    );
  }

  // Modern user type dropdown with gradient
  Widget _buildModernUserTypeDropdown() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [sage500, Color(0xFFB8BF9D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonFormField<UserType>(
        value: _userType,
        decoration: InputDecoration(
          hintText: userType,
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontFamily: 'Alexandria',
            fontSize: 16,
          ),
          prefixIcon: const Icon(
            Icons.badge_rounded,
            color: Colors.white,
            size: 24,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
        dropdownColor: sage500,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontFamily: 'Alexandria',
        ),
        icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.white, size: 28),
        items: const [
          DropdownMenuItem(
            value: UserType.priest,
            child: Text(
              priest,
              style: TextStyle(fontFamily: 'Alexandria'),
            ),
          ),
          DropdownMenuItem(
            value: UserType.superServant,
            child: Text(
              superServant,
              style: TextStyle(fontFamily: 'Alexandria'),
            ),
          ),
          DropdownMenuItem(
            value: UserType.servant,
            child: Text(
              servant,
              style: TextStyle(fontFamily: 'Alexandria'),
            ),
          ),
          DropdownMenuItem(
            value: UserType.child,
            child: Text(
              child,
              style: TextStyle(fontFamily: 'Alexandria'),
            ),
          ),
        ],
        onChanged: (UserType? value) {
          setState(() => _userType = value);
        },
        validator: (value) {
          if (value == null) {
            return 'الرجاء اختيار نوع المستخدم';
          }
          return null;
        },
      ),
    );
  }

  // Service type dropdown with gradient
  Widget _buildServiceTypeDropdown() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [teal500, teal700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
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
          hintText: 'الخدمة',
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontFamily: 'Alexandria',
            fontSize: 16,
          ),
          prefixIcon: const Icon(
            Icons.calendar_view_week_rounded,
            color: Colors.white,
            size: 24,
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
          fontSize: 16,
          fontFamily: 'Alexandria',
        ),
        icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.white, size: 28),
        items: ServiceType.values.map((service) {
          return DropdownMenuItem<ServiceType>(
            value: service,
            child: Text(
              service.displayName,
              style: const TextStyle(fontFamily: 'Alexandria'),
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
    );
  }
}
