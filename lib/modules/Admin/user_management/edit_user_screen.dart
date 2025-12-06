import 'package:church/core/blocs/admin_user/admin_user_cubit.dart';
import 'package:church/core/blocs/admin_user/admin_user_states.dart';
import 'package:church/core/models/user/user_model.dart';
import 'package:church/core/models/Classes/classes_model.dart';
import 'package:church/core/repositories/classes_repository.dart';
import 'package:church/core/styles/colors.dart';
import 'package:church/core/styles/themeScaffold.dart';
import 'package:church/core/utils/userType_enum.dart';
import 'package:church/core/utils/gender_enum.dart';
import 'package:church/core/utils/service_enum.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EditUserScreen extends StatefulWidget {
  final UserModel user;

  const EditUserScreen({super.key, required this.user});

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _couponPointsController;

  final ClassesRepository _classesRepository = ClassesRepository();

  late UserType _selectedUserType;
  late Gender _selectedGender;
  late ServiceType _selectedServiceType;
  late bool _firstLogin;
  late bool _isAdmin;
  late bool _storeAdmin;
  Model? _selectedClass;
  DateTime? _birthday;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.user.fullName);
    _usernameController = TextEditingController(text: widget.user.username);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phoneNumber ?? '');
    _addressController = TextEditingController(text: widget.user.address ?? '');
    _couponPointsController = TextEditingController(text: widget.user.couponPoints.toString());

    _selectedUserType = widget.user.userType;
    _selectedGender = widget.user.gender;
    _selectedServiceType = widget.user.serviceType;
    _firstLogin = widget.user.firstLogin;
    _isAdmin = widget.user.isAdmin;
    _storeAdmin = widget.user.storeAdmin;
    _birthday = widget.user.birthday;
    // _selectedClass will be set when classes are loaded from stream
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _couponPointsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdminUserCubit, AdminUserState>(
      listener: (context, state) {
        if (state is AdminPasswordReset) {
          // Show dialog with the temporary password
          _showPasswordResetSuccessDialog(context, state.temporaryPassword);
        } else if (state is AdminUserError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: ThemedScaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [teal700, teal500, teal300],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: teal700.withValues(alpha: 0.3),
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
                                  Icons.edit_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'تعديل المستخدم',
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
                            'تحديث بيانات المستخدم',
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
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'المعلومات الشخصية',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  color: teal900,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fullNameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'الاسم الكامل *',
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.person_outline, color: Colors.white70),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white70),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white70),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال الاسم الكامل';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'اسم المستخدم *',
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.alternate_email, color: Colors.white70),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white70),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white70),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال اسم المستخدم';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'البريد الإلكتروني *',
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.email_outlined, color: Colors.white70),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white70),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white70),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white, width: 2),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال البريد الإلكتروني';
                  }
                  if (!value.contains('@')) {
                    return 'البريد الإلكتروني غير صحيح';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'رقم الهاتف',
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.phone_outlined, color: Colors.white70),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white70),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white70),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white, width: 2),
                  ),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'العنوان',
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.location_on_outlined, color: Colors.white70),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white70),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white70),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white, width: 2),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              const Text(
                'معلومات الخدمة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: teal900,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<UserType>(
                value: _selectedUserType,
                style: const TextStyle(color: Colors.white, fontFamily: 'Alexandria'),
                dropdownColor: teal700,
                decoration: InputDecoration(
                  labelText: 'نوع المستخدم *',
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.person_pin_outlined, color: Colors.white70),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white70),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white70),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white, width: 2),
                  ),
                ),
                items: UserType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.label),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedUserType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Gender>(
                value: _selectedGender,
                style: const TextStyle(color: Colors.white, fontFamily: 'Alexandria'),
                dropdownColor: teal700,
                decoration: InputDecoration(
                  labelText: 'الجنس *',
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.wc_outlined, color: Colors.white70),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white70),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white70),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white, width: 2),
                  ),
                ),
                items: Gender.values.map((gender) {
                  return DropdownMenuItem(
                    value: gender,
                    child: Text(gender.label),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedGender = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              // Classes Dropdown from Database
              StreamBuilder<List<Model>>(
                stream: _classesRepository.getAllClasses(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: teal700.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white70),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'جاري تحميل الأسر...',
                            style: TextStyle(
                              color: Colors.white70,
                              fontFamily: 'Alexandria',
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red, width: 2),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red, size: 20),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'خطأ في تحميل الأسر',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Alexandria',
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final classes = snapshot.data ?? [];

                  // Try to match the current user's class with the loaded classes
                  if (_selectedClass == null && classes.isNotEmpty && widget.user.userClass.isNotEmpty) {
                    _selectedClass = classes.firstWhere(
                      (c) => c.name == widget.user.userClass,
                      orElse: () => classes.first,
                    );
                  }

                  if (classes.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange, width: 2),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_rounded, color: Colors.orange, size: 20),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'لا توجد أسر متاحة حالياً',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Alexandria',
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return DropdownButtonFormField<Model>(
                    value: _selectedClass,
                    style: const TextStyle(color: Colors.white, fontFamily: 'Alexandria'),
                    dropdownColor: teal700,
                    decoration: InputDecoration(
                      labelText: 'الفصل *',
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.class_outlined, color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white70),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white70),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white, width: 2),
                      ),
                    ),
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
                      setState(() {
                        _selectedClass = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'الرجاء اختيار الأسرة';
                      }
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ServiceType>(
                value: _selectedServiceType,
                style: const TextStyle(color: Colors.white, fontFamily: 'Alexandria'),
                dropdownColor: teal700,
                decoration: InputDecoration(
                  labelText: 'نوع الخدمة *',
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.church_outlined, color: Colors.white70),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white70),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white70),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white, width: 2),
                  ),
                ),
                items: ServiceType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedServiceType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _couponPointsController,
                style: const TextStyle(color: Colors.white, fontFamily: 'Alexandria'),
                decoration: InputDecoration(
                  labelText: 'نقاط الكوبون',
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.star_outline, color: Colors.white70),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white70),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white70),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white, width: 2),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (int.tryParse(value) == null) {
                      return 'يرجى إدخال رقم صحيح';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('أول تسجيل دخول', style: TextStyle(color: Colors.white)),
                subtitle: const Text('هل هذه أول مرة يسجل فيها المستخدم دخوله؟', style: TextStyle(color: Colors.white70)),
                value: _firstLogin,
                onChanged: (value) {
                  setState(() {
                    _firstLogin = value;
                  });
                },
                activeColor: teal500,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'الصلاحيات',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: teal900,
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('مسؤول النظام', style: TextStyle(color: Colors.white)),
                subtitle: const Text('منح صلاحيات المسؤول الكاملة', style: TextStyle(color: Colors.white70)),
                value: _isAdmin,
                onChanged: (value) {
                  setState(() {
                    _isAdmin = value;
                  });
                },
                activeColor: brown500,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('مسؤول المتجر', style: TextStyle(color: Colors.white)),
                subtitle: const Text('منح صلاحيات إدارة المتجر', style: TextStyle(color: Colors.white70)),
                value: _storeAdmin,
                onChanged: (value) {
                  setState(() {
                    _storeAdmin = value;
                  });
                },
                activeColor: brown500,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'معلومات إضافية',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: teal900,
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _birthday ?? DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.light(
                            primary: teal500,
                            onPrimary: Colors.white,
                            onSurface: teal900,
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
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white70),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cake_outlined, color: Colors.white70),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'تاريخ الميلاد',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _birthday != null
                                  ? '${_birthday!.day}/${_birthday!.month}/${_birthday!.year}'
                                  : 'لم يتم تحديد تاريخ الميلاد',
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      if (_birthday != null)
                        IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white70),
                          onPressed: () {
                            setState(() {
                              _birthday = null;
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '* حقول مطلوبة',
                style: TextStyle(
                  fontSize: 12,
                  color: sage600,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _saveChanges(context),
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('حفظ التغييرات'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: teal500,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showResetPasswordDialog(context),
                      icon: const Icon(Icons.lock_reset_rounded),
                      label: const Text('إعادة تعيين كلمة المرور', style: TextStyle(fontSize: 14.0),),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brown500,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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

  void _saveChanges(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      final cubit = context.read<AdminUserCubit>();

      final userData = {
        'fullName': _fullNameController.text,
        'username': _usernameController.text,
        'email': _emailController.text,
        'phoneNumber': _phoneController.text.isEmpty ? null : _phoneController.text,
        'address': _addressController.text.isEmpty ? null : _addressController.text,
        'userType': _selectedUserType.code,
        'gender': _selectedGender.code,
        // Persist as 'userClass' to avoid creating duplicate legacy 'class' field
        'userClass': _selectedClass?.name ?? '',
        'serviceType': _selectedServiceType.key,
        'couponPoints': int.tryParse(_couponPointsController.text) ?? widget.user.couponPoints,
        'firstLogin': _firstLogin,
        'isAdmin': _isAdmin,
        'storeAdmin': _storeAdmin,
        if (_birthday != null) 'birthday': _birthday,
      };

      await cubit.updateUser(widget.user.id, userData);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث بيانات المستخدم بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    }
  }

  void _showResetPasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'إعادة تعيين كلمة المرور',
          style: TextStyle(color: teal900),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'هل تريد إعادة تعيين كلمة المرور لـ ${widget.user.fullName}؟',
              style: const TextStyle(color: sage700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: teal50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: teal500.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.email_outlined, color: teal700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'البريد الإلكتروني:\n${widget.user.email}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: teal900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: brown100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: brown500.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: brown700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'سيتم إنشاء كلمة مرور مؤقتة جديدة. يرجى نسخها وإرسالها للمستخدم.',
                      style: TextStyle(
                        fontSize: 11,
                        color: brown900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              // Show loading
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('جاري إعادة تعيين كلمة المرور...'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }

              // Call cubit to reset password
              final cubit = context.read<AdminUserCubit>();
              await cubit.resetUserPassword(widget.user.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: brown500,
              foregroundColor: Colors.white,
            ),
            child: const Text('إعادة تعيين'),
          ),
        ],
      ),
    );
  }

  void _showPasswordResetSuccessDialog(BuildContext context, String temporaryPassword) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600),
            const SizedBox(width: 8),
            const Text('تم إعادة تعيين كلمة المرور'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'تم إنشاء كلمة مرور مؤقتة جديدة!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text('كلمة المرور المؤقتة:'),
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: temporaryPassword));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم نسخ كلمة المرور'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: teal50,
                  border: Border.all(color: teal500, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: SelectableText(
                        temporaryPassword,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: teal900,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.copy, color: teal700, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'اضغط على كلمة المرور لنسخها',
              style: TextStyle(
                fontSize: 11,
                color: teal700,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'يرجى نسخ كلمة المرور وإرسالها للمستخدم. سيُطلب منه تغييرها عند تسجيل الدخول الأول.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: teal500,
              foregroundColor: Colors.white,
            ),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }
}

