import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/blocs/club/club_cubit.dart';
import '../../core/models/club/attendance_service_model.dart';


void showManageServicesSheet(
    BuildContext context, List<AttendanceService> services) {
  final cubit = context.read<ClubCubit>();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => BlocProvider.value(
      value: cubit,
      child: _ManageServicesSheet(services: services),
    ),
  );
}

class _ManageServicesSheet extends StatefulWidget {
  final List<AttendanceService> services;
  const _ManageServicesSheet({required this.services});

  @override
  State<_ManageServicesSheet> createState() => _ManageServicesSheetState();
}

class _ManageServicesSheetState extends State<_ManageServicesSheet> {
  late final ClubCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<ClubCubit>();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return StreamBuilder<ClubState>(
      stream: _cubit.stream,
      initialData: _cubit.state,
      builder: (context, snapshot) {
        final state = snapshot.data;
        final currentServices = state is ClubServantLoaded
            ? state.attendanceServices
            : widget.services;

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (_, scrollController) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('إدارة خدمات الحضور',
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        FilledButton.icon(
                          onPressed: () =>
                              _showServiceForm(context, _cubit, existing: null),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('إضافة'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: currentServices.isEmpty
                    ? const Center(child: Text('لا توجد خدمات'))
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: currentServices.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final s = currentServices[index];
                          return ListTile(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(
                                    color: colorScheme.outlineVariant
                                        .withOpacity(0.4))),
                            tileColor: colorScheme.surface,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.church_outlined,
                                  color: colorScheme.primary, size: 22),
                            ),
                            title: Text(s.nameAr,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text('+${s.coinsValue} عملة'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () => _showServiceForm(
                                      context, _cubit,
                                      existing: s),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete_outline,
                                      color: colorScheme.error),
                                  onPressed: () async {
                                    final confirm =
                                        await _confirmDialog(context, s.nameAr);
                                    if (confirm == true && context.mounted) {
                                      _cubit.deleteAttendanceService(s.id);
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showServiceForm(BuildContext context, ClubCubit cubit,
      {AttendanceService? existing}) {
    showDialog(
      context: context,
      builder: (ctx) => BlocProvider.value(
        value: cubit,
        child: _ServiceFormDialog(existing: existing),
      ),
    );
  }

  Future<bool?> _confirmDialog(BuildContext context, String name) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف الخدمة'),
        content: Text('هل أنت متأكد من حذف "$name"؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف')),
        ],
      ),
    );
  }
}

// ── Service Form Dialog ───────────────────────────────────────────────────────

class _ServiceFormDialog extends StatefulWidget {
  final AttendanceService? existing;
  const _ServiceFormDialog({this.existing});

  @override
  State<_ServiceFormDialog> createState() => _ServiceFormDialogState();
}

class _ServiceFormDialogState extends State<_ServiceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameArCtrl;
  late TextEditingController _nameCtrl;
  late TextEditingController _coinsCtrl;

  @override
  void initState() {
    super.initState();
    _nameArCtrl =
        TextEditingController(text: widget.existing?.nameAr ?? '');
    _nameCtrl =
        TextEditingController(text: widget.existing?.name ?? '');
    _coinsCtrl = TextEditingController(
        text: widget.existing?.coinsValue.toString() ?? '');
  }

  @override
  void dispose() {
    _nameArCtrl.dispose();
    _nameCtrl.dispose();
    _coinsCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final service = AttendanceService(
      id: widget.existing?.id ?? '',
      nameAr: _nameArCtrl.text.trim(),
      name: _nameCtrl.text.trim(),
      coinsValue: int.parse(_coinsCtrl.text.trim()),
    );
    final cubit = context.read<ClubCubit>();
    if (widget.existing == null) {
      cubit.addAttendanceService(service);
    } else {
      cubit.updateAttendanceService(service);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Text(isEdit ? 'تعديل الخدمة' : 'إضافة خدمة جديدة'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameArCtrl,
              decoration:
                  const InputDecoration(labelText: 'اسم الخدمة بالعربية'),
              validator: (v) => v!.isEmpty ? 'مطلوب' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtrl,
              decoration:
                  const InputDecoration(labelText: 'اسم الخدمة بالإنجليزية'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _coinsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'قيمة العملات', suffixText: '🪙'),
              validator: (v) {
                if (v == null || v.isEmpty) return 'مطلوب';
                if (int.tryParse(v) == null) return 'رقم فقط';
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء')),
        FilledButton(
            onPressed: _submit,
            child: Text(isEdit ? 'حفظ' : 'إضافة')),
      ],
    );
  }
}
