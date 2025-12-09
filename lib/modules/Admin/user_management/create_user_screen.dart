import 'package:church/core/styles/themeScaffold.dart';
import 'package:church/core/styles/colors.dart';
import 'package:church/core/utils/userType_enum.dart';
import 'package:church/core/utils/gender_enum.dart';
import 'package:church/core/utils/service_enum.dart';
import 'package:church/core/utils/classes_mapping.dart';
import 'package:church/core/models/class_mapping/class_mapping_model.dart';
import 'package:flutter/material.dart';

import '../../../core/models/class_mapping/class_mapping_model.dart';

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _couponPointsController = TextEditingController(text: '0');

  UserType _selectedUserType = UserType.child;
  Gender _selectedGender = Gender.male;
  ServiceType _selectedServiceType = ServiceType.primaryBoys;
  String _selectedUserClass = '1'; // Default to class 1
  bool _firstLogin = true;
  bool _isAdmin = false;
  bool _storeAdmin = false;
  bool _isActive = true;
  DateTime? _birthday;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _couponPointsController.dispose();
    super.dispose();
  }

  List<DropdownMenuItem<String>> _buildClassDropdownItems(Map<String, List<ClassMapping>> groupedMappings) {
    List<DropdownMenuItem<String>> items = [];

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
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ),
      );

      // Add class options
      for (var mapping in mappings) {
        items.add(
          DropdownMenuItem<String>(
            value: mapping.id, // Use mapping ID as value
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

  @override
  Widget build(BuildContext context) {
    return ThemedScaffold(
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
                                Icons.person_add_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'إضافة مستخدم جديد',
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
                          'إنشاء حساب مستخدم جديد',
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
                'معلومات الحساب',
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
                  labelStyle: const TextStyle(color: Colors.white),
                  prefixIcon: const Icon(Icons.person_outline, color: Colors.white),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white),
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
                  labelStyle: const TextStyle(color: Colors.white),
                  prefixIcon: const Icon(Icons.alternate_email, color: Colors.white),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white),
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
                  labelStyle: const TextStyle(color: Colors.white),
                  prefixIcon: const Icon(Icons.email_outlined, color: Colors.white),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white),
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
                controller: _passwordController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'كلمة المرور *',
                  labelStyle: const TextStyle(color: Colors.white),
                  prefixIcon: const Icon(Icons.lock_outline, color: Colors.white),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white, width: 2),
                  ),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال كلمة المرور';
                  }
                  if (value.length < 6) {
                    return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
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
                  labelStyle: const TextStyle(color: Colors.white),
                  prefixIcon: const Icon(Icons.phone_outlined, color: Colors.white),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white),
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
                  labelStyle: const TextStyle(color: Colors.white),
                  prefixIcon: const Icon(Icons.location_on_outlined, color: Colors.white),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white),
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
                  labelStyle: const TextStyle(color: Colors.white),
                  prefixIcon: const Icon(Icons.person_pin_outlined, color: Colors.white),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white),
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
                  labelStyle: const TextStyle(color: Colors.white),
                  prefixIcon: const Icon(Icons.wc_outlined, color: Colors.white),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white),
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
              // User Class Dropdown with StreamBuilder
              StreamBuilder<List<ClassMapping>>(
                stream: ClassMappingService.getActiveClassMappings(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('خطأ في تحميل الصفوف: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red));
                  }

                  final classMappings = snapshot.data ?? [];

                  if (classMappings.isEmpty) {
                    return Container(
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
                              'لا توجد صفوف متاحة. يرجى إضافة صفوف من لوحة التحكم.',
                              style: TextStyle(color: Colors.orange),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Group by classCode
                  final groupedMappings = <String, List<ClassMapping>>{};
                  for (var mapping in classMappings) {
                    groupedMappings.putIfAbsent(mapping.classCode, () => []).add(mapping);
                  }

                  // Ensure selected value is valid
                  final allMappingIds = classMappings.map((m) => m.id).toList();
                  if (classMappings.isNotEmpty && !allMappingIds.contains(_selectedUserClass)) {
                    _selectedUserClass = classMappings.first.id;
                  }

                  return DropdownButtonFormField<String>(
                    value: _selectedUserClass,
                    style: const TextStyle(color: Colors.white, fontFamily: 'Alexandria'),
                    dropdownColor: teal700,
                    decoration: InputDecoration(
                      labelText: 'الفصل *',
                      labelStyle: const TextStyle(color: Colors.white),
                      prefixIcon: const Icon(Icons.class_outlined, color: Colors.white),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white, width: 2),
                      ),
                    ),
                    items: _buildClassDropdownItems(groupedMappings),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedUserClass = value;
                        });
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى اختيار الفصل';
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
                  labelStyle: const TextStyle(color: Colors.white),
                  prefixIcon: const Icon(Icons.church_outlined, color: Colors.white),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white),
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
                  labelStyle: const TextStyle(color: Colors.white),
                  prefixIcon: const Icon(Icons.star_outline, color: Colors.white),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white),
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
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('حساب نشط', style: TextStyle(color: Colors.white)),
                subtitle: const Text('تفعيل أو تعطيل حساب المستخدم', style: TextStyle(color: Colors.white70)),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
                activeColor: _isActive ? Colors.green : Colors.red,
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
              ElevatedButton.icon(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // TODO: Implement create user
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('سيتم إضافة وظيفة إنشاء المستخدم قريباً'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.save_rounded),
                label: const Text('إنشاء المستخدم'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: teal500,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

