import 'package:church/core/constants/strings.dart';
import 'package:church/core/models/user/user_model.dart';
import 'package:church/core/repositories/users_reopsitory.dart';
import 'package:church/core/services/profile_completion_service.dart';
import 'package:church/core/styles/colors.dart';
import 'package:church/core/styles/themeScaffold.dart';
import 'package:church/layout/home_layout.dart';
import 'package:church/shared/modern_loading_indicator.dart';
import 'package:church/shared/widgets.dart';
import 'package:flutter/material.dart';

class ProfileCompletionScreen extends StatefulWidget {
  final UserModel user;

  const ProfileCompletionScreen({
    super.key,
    required this.user,
  });

  @override
  State<ProfileCompletionScreen> createState() => _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Controllers
  late TextEditingController _fullNameController;
  late TextEditingController _usernameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _userClassController;

  bool _isLoading = false;
  final UsersRepository _userRepository = UsersRepository();

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing data
    _fullNameController = TextEditingController(text: widget.user.fullName);
    _usernameController = TextEditingController(text: widget.user.username);
    _addressController = TextEditingController(text: widget.user.address ?? '');
    _phoneController = TextEditingController(text: widget.user.phoneNumber ?? '');
    _userClassController = TextEditingController(text: widget.user.userClass);

    // Add listeners to update button state when text changes
    _fullNameController.addListener(_updateFormState);
    _usernameController.addListener(_updateFormState);
    _addressController.addListener(_updateFormState);
    _phoneController.addListener(_updateFormState);
    _userClassController.addListener(_updateFormState);

    // Setup animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
  }

  void _updateFormState() {
    setState(() {
      // This will trigger a rebuild to update the button state
    });
  }

  @override
  void dispose() {
    // Remove listeners before disposing
    _fullNameController.removeListener(_updateFormState);
    _usernameController.removeListener(_updateFormState);
    _addressController.removeListener(_updateFormState);
    _phoneController.removeListener(_updateFormState);
    _userClassController.removeListener(_updateFormState);

    _animationController.dispose();
    _fullNameController.dispose();
    _usernameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _userClassController.dispose();
    super.dispose();
  }

  String? _requiredValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'هذا الحقل مطلوب';
    return null;
  }

  String? _phoneValidator(String? v) {
    if (v == null || v.trim().isEmpty) return enterPhone;
    final digits = v.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 8) return 'رقم الهاتف غير صحيح';
    return null;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Update user data
      final updatedData = {
        'fullName': _fullNameController.text.trim(),
        'username': _usernameController.text.trim(),
        'address': _addressController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'userClass': _userClassController.text.trim(),
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
              userType: widget.user.userType.name,
              userClass: _userClassController.text.trim(),
              gender: widget.user.gender.name,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'حدث خطأ أثناء حفظ البيانات: $e',
              style: const TextStyle(fontFamily: 'Alexandria'),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),

                        // Welcome Header
                        _buildHeader(),

                        const SizedBox(height: 40),

                        // Progress Indicator
                        _buildProgressIndicator(),

                        const SizedBox(height: 40),

                        // Form Fields
                        _buildFormFields(),

                        const SizedBox(height: 40),

                        // Save Button
                        _buildSaveButton(),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Loading Overlay
          if (_isLoading)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Modern loading indicator with decorative container
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: teal100,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: teal300.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: CircularProgressIndicator(
                          color: teal500,
                          strokeWidth: 4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'جاري التحميل...',
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
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [teal500, teal300],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: teal500.withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_add_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'مرحباً بك!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Alexandria',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'أهلاً ${widget.user.email}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontFamily: 'Alexandria',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'يرجى إكمال بياناتك الشخصية للمتابعة',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.95),
                      fontFamily: 'Alexandria',
                      height: 1.4,
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

  Widget _buildProgressIndicator() {
    int filledFields = 0;
    int totalFields = 5;

    if (_fullNameController.text.trim().isNotEmpty) filledFields++;
    if (_usernameController.text.trim().isNotEmpty) filledFields++;
    if (_addressController.text.trim().isNotEmpty) filledFields++;
    if (_phoneController.text.trim().isNotEmpty) filledFields++;
    if (_userClassController.text.trim().isNotEmpty) filledFields++;

    double progress = filledFields / totalFields;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'إكمال الملف الشخصي',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Alexandria',
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: teal100,
                fontFamily: 'Alexandria',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 12,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(teal300),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$filledFields من $totalFields حقول مكتملة',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.7),
            fontFamily: 'Alexandria',
          ),
        ),
      ],
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        _buildFieldCard(
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
        const SizedBox(height: 16),
        _buildFieldCard(
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
        const SizedBox(height: 16),
        _buildFieldCard(
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
        const SizedBox(height: 16),
        _buildFieldCard(
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
        const SizedBox(height: 16),
        _buildFieldCard(
          icon: Icons.class_,
          color: teal500,
          child: coloredTextField(
            enabledBorder: InputBorder.none,
            prefixIcon: Icons.class_,
            fillColor: teal500,
            controller: _userClassController,
            label: 'الفصل / الخدمة',
            validator: _requiredValidator,
          ),
        ),
      ],
    );
  }

  Widget _buildFieldCard({
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSaveButton() {
    final isFormValid = _fullNameController.text.trim().isNotEmpty &&
        _usernameController.text.trim().isNotEmpty &&
        _addressController.text.trim().isNotEmpty &&
        _phoneController.text.trim().isNotEmpty &&
        _userClassController.text.trim().isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: isFormValid
              ? [teal700, teal300]
              : [Colors.grey[600]!, Colors.grey[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: (isFormValid ? teal500 : Colors.grey)
                .withValues(alpha: 0.4),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isFormValid && !_isLoading ? _saveProfile : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 60,
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'حفظ ومتابعة',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Alexandria',
                    letterSpacing: 0.5,
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
