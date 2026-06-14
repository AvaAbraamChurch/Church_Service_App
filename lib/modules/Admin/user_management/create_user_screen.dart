import 'package:church/core/blocs/admin_user/admin_user_cubit.dart';
import 'package:church/core/blocs/admin_user/admin_user_states.dart';
import 'package:church/core/models/class_mapping/class_mapping_model.dart';
import 'package:church/core/repositories/admin_repository.dart';
import 'package:church/core/styles/colors.dart';
import 'package:church/core/styles/themeScaffold.dart';
import 'package:church/core/utils/gender_enum.dart';
import 'package:church/core/utils/userType_enum.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CreateUserScreen extends StatelessWidget {
  const CreateUserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminUserCubit(adminRepository: AdminRepository()),
      child: const _CreateUserBody(),
    );
  }
}

class _CreateUserBody extends StatefulWidget {
  const _CreateUserBody();

  @override
  State<_CreateUserBody> createState() => _CreateUserBodyState();
}

class _CreateUserBodyState extends State<_CreateUserBody> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();

  UserType _selectedUserType = UserType.child;
  Gender _selectedGender = Gender.male;
  // Stores the ClassMapping.id of the selected class (empty until stream loads)
  String _selectedUserClass = '';

  // Preview of auto-generated credentials (display only — actual values generated in cubit)
  String _previewUsername = '';
  String _previewEmail = '';
  bool _passwordVisible = false;

  @override
  void initState() {
    super.initState();
    _fullNameController.addListener(_onFullNameChanged);
  }

  @override
  void dispose() {
    _fullNameController.removeListener(_onFullNameChanged);
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onFullNameChanged() {
    final name = _fullNameController.text.trim();
    final username = name.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    setState(() {
      _previewUsername = username;
      _previewEmail = username.isEmpty ? '' : '$username@avaabraamchurch.com';
    });
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم النسخ'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    AdminUserCubit.get(context).createSingleUser(
      fullName: _fullNameController.text.trim(),
      gender: _selectedGender.code,
      userType: _selectedUserType.code,
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      userClass: _selectedUserClass,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminUserCubit, AdminUserState>(
      listenWhen: (_, curr) =>
          curr is AdminUserError || curr is AdminUserCreatedWithCredentials,
      buildWhen: (_, curr) =>
          curr is AdminUserLoading || curr is AdminUserInitial,
      listener: (context, state) {
        if (state is AdminUserError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state is AdminUserCreatedWithCredentials) {
          _showSuccessDialog(context, state);
        }
      },
      builder: (context, state) {
        final isLoading = state is AdminUserLoading;
        return ThemedScaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(110),
            child: _AppHeader(),
          ),
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Required fields ────────────────────────────────────
                    _SectionLabel('البيانات الأساسية'),
                    const SizedBox(height: 12),
                    _Field(
                      controller: _fullNameController,
                      label: 'الاسم الكامل',
                      icon: Icons.person_outline,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'الاسم الكامل مطلوب'
                              : null,
                    ),
                    const SizedBox(height: 14),
                    _DropdownField<UserType>(
                      label: 'نوع المستخدم',
                      icon: Icons.badge_outlined,
                      value: _selectedUserType,
                      items: UserType.values,
                      itemLabel: (t) => t.label,
                      onChanged: (v) =>
                          setState(() => _selectedUserType = v!),
                    ),
                    const SizedBox(height: 14),
                    _DropdownField<Gender>(
                      label: 'الجنس',
                      icon: Icons.wc_outlined,
                      value: _selectedGender,
                      items: Gender.values,
                      itemLabel: (g) => g.label,
                      onChanged: (v) =>
                          setState(() => _selectedGender = v!),
                    ),
                    const SizedBox(height: 14),
                    _ClassDropdown(
                      selectedId: _selectedUserClass,
                      onChanged: (id) =>
                          setState(() => _selectedUserClass = id),
                    ),
                    const SizedBox(height: 14),
                    _Field(
                      controller: _phoneController,
                      label: 'رقم الهاتف (اختياري)',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        if (!RegExp(r'^[0-9+\-\s]{7,15}$')
                            .hasMatch(v.trim())) {
                          return 'رقم الهاتف غير صحيح';
                        }
                        return null;
                      },
                    ),

                    // ── Auto-generated credentials preview ─────────────────
                    const SizedBox(height: 24),
                    _SectionLabel('بيانات الدخول (تلقائية)'),
                    const SizedBox(height: 4),
                    Text(
                      'يتم توليدها تلقائياً من الاسم',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12),
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 12),
                    _ReadOnlyField(
                      label: 'اسم المستخدم',
                      icon: Icons.alternate_email,
                      value: _previewUsername.isEmpty
                          ? '—'
                          : _previewUsername,
                      onCopy: _previewUsername.isEmpty
                          ? null
                          : () => _copyToClipboard(_previewUsername),
                    ),
                    const SizedBox(height: 14),
                    _ReadOnlyField(
                      label: 'البريد الإلكتروني',
                      icon: Icons.email_outlined,
                      value: _previewEmail.isEmpty ? '—' : _previewEmail,
                      onCopy: _previewEmail.isEmpty
                          ? null
                          : () => _copyToClipboard(_previewEmail),
                    ),
                    const SizedBox(height: 14),
                    _ReadOnlyField(
                      label: 'كلمة المرور',
                      icon: Icons.lock_outline,
                      value: _passwordVisible
                          ? 'سيتم توليدها تلقائياً'
                          : '••••••••',
                      trailing: IconButton(
                        icon: Icon(
                          _passwordVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.white70,
                          size: 20,
                        ),
                        onPressed: () => setState(
                            () => _passwordVisible = !_passwordVisible),
                      ),
                    ),

                    // ── Submit ─────────────────────────────────────────────
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: isLoading ? null : () => _submit(context),
                      icon: isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.person_add_rounded),
                      label: Text(
                          isLoading ? 'جارٍ الإنشاء...' : 'إنشاء المستخدم'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: teal500,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSuccessDialog(
      BuildContext context, AdminUserCreatedWithCredentials s) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: teal800,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.greenAccent),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'تم إنشاء المستخدم بنجاح',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _CredentialRow(label: 'الاسم', value: s.fullName),
              const SizedBox(height: 8),
              _CredentialRow(
                  label: 'اسم المستخدم', value: s.username),
              const SizedBox(height: 8),
              _CredentialRow(
                  label: 'البريد الإلكتروني', value: s.email),
              const SizedBox(height: 8),
              _CredentialRow(
                  label: 'كلمة المرور',
                  value: s.password,
                  sensitive: true),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.5)),
                ),
                child: const Text(
                  'سيُطلب من المستخدم تغيير كلمة المرور عند أول دخول',
                  style: TextStyle(color: Colors.orange, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // close dialog
                Navigator.of(context).pop(true); // back to list
              },
              child: const Text('حسناً',
                  style: TextStyle(color: teal300)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets ────────────────────────────────────────────────────────────────────

class _AppHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
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
                          child: const Icon(Icons.person_add_rounded,
                              color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'إضافة مستخدم جديد',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'البيانات تُولَّد تلقائياً',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textDirection: TextDirection.rtl,
      style: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.bold, color: teal300),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textDirection: TextDirection.rtl,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      decoration: _buildDecoration(label, icon),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final IconData icon;
  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final void Function(T?) onChanged;

  const _DropdownField({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      style: const TextStyle(
          color: Colors.white, fontFamily: 'Alexandria'),
      dropdownColor: teal700,
      decoration: _buildDecoration(label, icon),
      items: items
          .map((item) => DropdownMenuItem<T>(
                value: item,
                child: Text(itemLabel(item)),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final VoidCallback? onCopy;
  final Widget? trailing;

  const _ReadOnlyField({
    required this.label,
    required this.icon,
    required this.value,
    this.onCopy,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white38),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.05),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 15)),
              ],
            ),
          ),
          if (trailing != null) trailing!,
          if (onCopy != null)
            IconButton(
              icon: const Icon(Icons.copy_rounded,
                  color: Colors.white54, size: 18),
              onPressed: onCopy,
              tooltip: 'نسخ',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}

class _CredentialRow extends StatefulWidget {
  final String label;
  final String value;
  final bool sensitive;

  const _CredentialRow({
    required this.label,
    required this.value,
    this.sensitive = false,
  });

  @override
  State<_CredentialRow> createState() => _CredentialRowState();
}

class _CredentialRowState extends State<_CredentialRow> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    final display =
        widget.sensitive && !_visible ? '••••••••' : widget.value;

    return Row(
      children: [
        Expanded(
          child: RichText(
            textDirection: TextDirection.rtl,
            text: TextSpan(
              style: const TextStyle(fontSize: 13),
              children: [
                TextSpan(
                  text: '${widget.label}: ',
                  style: const TextStyle(color: Colors.white60),
                ),
                TextSpan(
                  text: display,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        if (widget.sensitive)
          GestureDetector(
            onTap: () => setState(() => _visible = !_visible),
            child: Icon(
              _visible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: Colors.white54,
              size: 18,
            ),
          ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () =>
              Clipboard.setData(ClipboardData(text: widget.value)),
          child: const Icon(Icons.copy_rounded,
              color: Colors.white54, size: 18),
        ),
      ],
    );
  }
}

/// Dropdown that loads class options live from Firestore via [ClassMappingService].
///
/// Stores the [ClassMapping.id] (Firestore document ID) as the selected value
/// so the specific class group can be resolved later.
class _ClassDropdown extends StatelessWidget {
  final String selectedId;
  final void Function(String id) onChanged;

  const _ClassDropdown({
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ClassMapping>>(
      stream: ClassMappingService.getActiveClassMappings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 56,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white38),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.redAccent),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'خطأ في تحميل الفصول: ${snapshot.error}',
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
              textDirection: TextDirection.rtl,
            ),
          );
        }

        final classes = snapshot.data ?? [];

        if (classes.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.orange.withValues(alpha: 0.6)),
              borderRadius: BorderRadius.circular(12),
              color: Colors.orange.withValues(alpha: 0.08),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'لا توجد فصول متاحة. يرجى إضافة فصول من لوحة التحكم.',
                    style: TextStyle(color: Colors.orange, fontSize: 13),
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ],
            ),
          );
        }

        // Auto-select the first class when the list first loads
        final currentId =
            classes.any((c) => c.id == selectedId) ? selectedId : classes.first.id;
        if (currentId != selectedId) {
          // Schedule after build so we don't call setState during build
          WidgetsBinding.instance.addPostFrameCallback((_) => onChanged(currentId));
        }

        return DropdownButtonFormField<String>(
          value: currentId,
          style: const TextStyle(color: Colors.white, fontFamily: 'Alexandria'),
          dropdownColor: teal700,
          decoration: _buildDecoration('الفصل', Icons.class_outlined),
          items: classes
              .map((c) => DropdownMenuItem<String>(
                    value: c.id,
                    child: Text(c.className),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
          validator: (v) =>
              (v == null || v.isEmpty) ? 'يرجى اختيار الفصل' : null,
        );
      },
    );
  }
}

InputDecoration _buildDecoration(String label, IconData icon) {
  final border =
      OutlineInputBorder(borderRadius: BorderRadius.circular(12));
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.white70),
    prefixIcon: Icon(icon, color: Colors.white70),
    border: border,
    enabledBorder: border.copyWith(
        borderSide: const BorderSide(color: Colors.white38)),
    focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: Colors.white, width: 2)),
    errorBorder: border.copyWith(
        borderSide: const BorderSide(color: Colors.redAccent)),
    focusedErrorBorder: border.copyWith(
        borderSide:
            const BorderSide(color: Colors.redAccent, width: 2)),
  );
}
