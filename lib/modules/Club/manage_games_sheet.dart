import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/blocs/club/club_cubit.dart';
import '../../core/models/club/game_model.dart';
import '../../core/utils/gender_enum.dart';

void showManageGamesSheet(BuildContext context, List<GameModel> games) {
  final cubit = context.read<ClubCubit>();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => BlocProvider.value(
      value: cubit,
      child: _ManageGamesSheet(games: games),
    ),
  );
}

class _ManageGamesSheet extends StatefulWidget {
  final List<GameModel> games;
  const _ManageGamesSheet({required this.games});

  @override
  State<_ManageGamesSheet> createState() => _ManageGamesSheetState();
}

class _ManageGamesSheetState extends State<_ManageGamesSheet> {
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
        final currentGames = state is ClubServantLoaded ? state.games : widget.games;

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.92,
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
                        Text('إدارة الألعاب',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            )),
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: () async {
                                final confirm = await _confirmDialog(
                                  context,
                                  title: 'إعادة تشغيل الألعاب',
                                  content:
                                      'سيتم تحويل جميع الألعاب إلى حالة "نشط". هل تريد المتابعة؟',
                                );
                                if (confirm == true && context.mounted) {
                                  _cubit.resetAllGames();
                                  Navigator.pop(context);
                                }
                              },
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('إعادة تشغيل'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              onPressed: () =>
                                  _showGameForm(context, existingGame: null),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('إضافة'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: currentGames.isEmpty
                    ? const Center(child: Text('لا توجد ألعاب'))
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: currentGames.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final g = currentGames[index];
                          return _GameTile(
                            game: g,
                            onEdit: () => _showGameForm(context, existingGame: g),
                            onDelete: () async {
                              final confirm = await _confirmDialog(
                                context,
                                title: 'حذف اللعبة',
                                content: 'هل تريد حذف ${g.nameAr}؟',
                              );
                              if (confirm == true && context.mounted) {
                                _cubit.deleteGame(g.id);
                              }
                            },
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

  void _showGameForm(BuildContext context, {GameModel? existingGame}) {
    showDialog(
      context: context,
      builder: (ctx) => BlocProvider.value(
        value: _cubit,
        child: _GameFormDialog(existingGame: existingGame),
      ),
    );
  }

  Future<bool?> _confirmDialog(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('تأكيد')),
        ],
      ),
    );
  }
}

// ── Game Add/Edit Dialog ──────────────────────────────────────────────────────

class _GameFormDialog extends StatefulWidget {
  final GameModel? existingGame;
  const _GameFormDialog({this.existingGame});

  @override
  State<_GameFormDialog> createState() => _GameFormDialogState();
}

class _GameFormDialogState extends State<_GameFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameArCtrl;
  late TextEditingController _nameCtrl;
  late TextEditingController _coinsCtrl;
  late TextEditingController _iconCtrl;
  late bool _allowBooking;
  late Gender _gender;

  @override
  void initState() {
    super.initState();
    _nameArCtrl =
        TextEditingController(text: widget.existingGame?.nameAr ?? '');
    _nameCtrl = TextEditingController(text: widget.existingGame?.name ?? '');
    _coinsCtrl = TextEditingController(
        text: widget.existingGame?.coins.toString() ?? '');
    _iconCtrl =
        TextEditingController(text: widget.existingGame?.icon ?? '🎮');
    _allowBooking = widget.existingGame?.allowBooking ?? false;
    _gender = widget.existingGame?.gender ?? Gender.male;
  }

  @override
  void dispose() {
    _nameArCtrl.dispose();
    _nameCtrl.dispose();
    _coinsCtrl.dispose();
    _iconCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final game = GameModel(
      id: widget.existingGame?.id ?? '',
      nameAr: _nameArCtrl.text.trim(),
      name: _nameCtrl.text.trim(),
      gender: _gender,
      coins: int.parse(_coinsCtrl.text.trim()),
      icon: _iconCtrl.text.trim(),
      status: widget.existingGame?.status ?? CardStatus.active,
      allowBooking: _allowBooking,
    );
    final cubit = context.read<ClubCubit>();
    if (widget.existingGame == null) {
      cubit.addGame(game);
    } else {
      cubit.updateGame(game);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingGame != null;
    return AlertDialog(
      title: Text(isEdit ? 'تعديل اللعبة' : 'إضافة لعبة جديدة'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 70,
                  child: TextFormField(
                    controller: _iconCtrl,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 28),
                    decoration: const InputDecoration(labelText: 'أيقونة'),
                    validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _nameArCtrl,
                    decoration: const InputDecoration(labelText: 'الاسم بالعربية'),
                    validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'الاسم بالإنجليزية'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Gender>(
              initialValue: _gender,
              decoration: const InputDecoration(labelText: 'النوع'),
              items: GenderLists.selectable
                  .map(
                    (g) => DropdownMenuItem(
                      value: g,
                      child: Text(g.label),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setState(() => _gender = val ?? _gender),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _coinsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'عدد العملات', suffixText: '🪙'),
              validator: (v) {
                if (v == null || v.isEmpty) return 'مطلوب';
                if (int.tryParse(v) == null) return 'رقم فقط';
                return null;
              },
            ),
            const SizedBox(height: 4),
            // ── Allow Booking toggle ──────────────────────────────────────
            StatefulBuilder(
              builder: (context, setLocal) => SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('السماح بحجز الدور'),
                subtitle: const Text(
                  'الأطفال يمكنهم حجز دورهم عندما تكون اللعبة مشغولة',
                  style: TextStyle(fontSize: 11),
                ),
                value: _allowBooking,
                onChanged: (val) {
                  setLocal(() => _allowBooking = val);
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء')),
        FilledButton(
            onPressed: _submit, child: Text(isEdit ? 'حفظ' : 'إضافة')),
      ],
    );
  }
}

class _GameTile extends StatelessWidget {
  final GameModel game;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _GameTile({
    required this.game,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: colorScheme.outlineVariant.withOpacity(0.4),
        ),
      ),
      tileColor: colorScheme.surface,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(game.icon, style: const TextStyle(fontSize: 20)),
      ),
      title: Text(game.nameAr,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('+${game.coins} عملة'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: onEdit,
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: colorScheme.error),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
