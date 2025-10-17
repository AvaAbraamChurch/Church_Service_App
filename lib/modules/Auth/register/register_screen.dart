import 'package:church/core/blocs/auth/auth_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/blocs/auth/auth_cubit.dart';
import '../../../core/constants/strings.dart';
import '../../../core/styles/colors.dart';
import '../../../core/styles/themeScaffold.dart';
import '../../../shared/widgets.dart';
import '../../../core/utils/gender_enum.dart';
import '../../../core/utils/userType_enum.dart';

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
  final _userClassController = TextEditingController();

  // Dropdown selections
  Gender? _gender;
  UserType? _userType;

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

  void _onSave(AuthCubit cubit) {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;
    if (_gender == null || _userType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(fillAllFields)),
      );
      return;
    }

    final data = {
      'fullName': _fullNameController.text.trim(),
      'username': _usernameController.text.trim(),
      'gender': _gender!.label, // Arabic value
      'address': _addressController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'userType': _userType!.label, // Arabic value
      'userClass': _userClassController.text.trim(),
    };

    // ignore: avoid_print
    print(data);
    cubit.signUp(_emailController.text.trim(), _passwordController.text.trim(), extraData: data);

  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (BuildContext context) => AuthCubit(),
      child: BlocConsumer<AuthCubit, AuthState>(
        builder: (BuildContext context, state) {
          final cubit = AuthCubit.get(context);
          return ThemedScaffold(
            body: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                  Text(
                    register,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Step indicator bound to current page
                  RegistrationStepIndicator(currentStep: _currentPage + 1, totalSteps: 2),
                  const SizedBox(height: 16),

                  // Form with horizontal paging of fields
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: (i) => setState(() => _currentPage = i),
                        children: [
                          // Page 1
                          SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                                coloredTextField(
                                  enabledBorder: InputBorder.none,
                                  prefixIcon: Icons.abc,
                                  fillColor: brown300,
                                  controller: _fullNameController,
                                  label: fullName,
                                  validator: _requiredValidator,
                                ),
                                const SizedBox(height: 16.0),
                                coloredTextField(
                                  enabledBorder: InputBorder.none,
                                  prefixIcon: Icons.person,
                                  fillColor: red500,
                                  controller: _usernameController,
                                  label: username,
                                  validator: _requiredValidator,
                                ),
                                const SizedBox(height: 16.0),
                                coloredDropdownMenu<Gender>(
                                  width: MediaQuery.of(context).size.width,
                                  fillColor: sage500,
                                  enabledBorder: InputBorder.none,
                                  hintText: gender,
                                  dropdownMenuEntries: [
                                    DropdownMenuEntry<Gender>(value: Gender.male, label: male),
                                    DropdownMenuEntry<Gender>(value: Gender.female, label: female),
                                  ],
                                  onSelected: (Gender? val) {
                                    setState(() => _gender = val);
                                  },
                                ),
                                const SizedBox(height: 16.0),
                                coloredTextField(
                                  enabledBorder: InputBorder.none,
                                  prefixIcon: Icons.location_on_rounded,
                                  fillColor: tawny,
                                  controller: _addressController,
                                  label: address,
                                  validator: _requiredValidator,
                                ),
                                const SizedBox(height: 8.0),
                              ],
                            ),
                          ),

                          // Page 2
                          SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                                coloredTextField(
                                  enabledBorder: InputBorder.none,
                                  prefixIcon: Icons.mail_outline,
                                  fillColor: brown300,
                                  controller: _emailController,
                                  label: email,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: _emailValidator,
                                ),
                                const SizedBox(height: 16.0),
                                coloredTextField(
                                  enabledBorder: InputBorder.none,
                                  prefixIcon: Icons.phone,
                                  fillColor: red500,
                                  controller: _phoneController,
                                  label: phone,
                                  keyboardType: TextInputType.phone,
                                  validator: _phoneValidator,
                                ),
                                const SizedBox(height: 16.0),
                                coloredDropdownMenu<UserType>(
                                  width: MediaQuery.of(context).size.width,
                                  fillColor: sage500,
                                  enabledBorder: InputBorder.none,
                                  hintText: userType,
                                  dropdownMenuEntries: const [
                                    DropdownMenuEntry<UserType>(value: UserType.priest, label: priest),
                                    DropdownMenuEntry<UserType>(value: UserType.superServant, label: superServant),
                                    DropdownMenuEntry<UserType>(value: UserType.servant, label: servant),
                                    DropdownMenuEntry<UserType>(value: UserType.child, label: child),
                                  ],
                                  onSelected: (UserType? val) {
                                    setState(() => _userType = val);
                                    print(_userType?.label);
                                  },
                                ),
                                const SizedBox(height: 16.0),
                                coloredTextField(
                                  enabledBorder: InputBorder.none,
                                  prefixIcon: Icons.lock_outline,
                                  fillColor: tawny,
                                  controller: _passwordController,
                                  label: password,
                                  isPassword: true,
                                  validator: _passwordValidator,
                                ),
                                const SizedBox(height: 16.0),
                                coloredTextField(
                                  enabledBorder: InputBorder.none,
                                  prefixIcon: Icons.lock,
                                  fillColor: teal500,
                                  controller: _confirmPasswordController,
                                  label: confirmPassword,
                                  isPassword: true,
                                  validator: _confirmValidator,
                                ),
                                const SizedBox(height: 8.0),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Save action (validates entire form)
                  ElevatedButton(
                    onPressed: () => _onSave(cubit),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: teal100,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Alexandria',
                      ),
                    ),
                    child: Text(save),
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
        listener: (BuildContext context, state) {
          if (state is AuthLoading) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => const Center(child: CircularProgressIndicator()),
            );
          } else {
            Navigator.of(context, rootNavigator: true).pop(); // Close loading dialog if open
          }

          if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error)),
            );
          } else if (state is AuthSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(registrationSuccessful)),
            );
            Navigator.of(context).pop(); // Go back to previous screen (e.g., login)
          }
        },
      ),
    );
  }
}
