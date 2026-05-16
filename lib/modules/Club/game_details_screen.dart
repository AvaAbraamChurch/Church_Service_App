import 'dart:async';
import 'package:church/core/styles/themeScaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/blocs/club/club_cubit.dart';
import '../../core/models/club/game_model.dart';
import '../../core/models/club/playing_child_model.dart';
import 'scan_or_manual_sheet.dart';

class GameDetailsScreen extends StatefulWidget {
  final GameModel game;

  const GameDetailsScreen({super.key, required this.game});

  @override
  State<GameDetailsScreen> createState() => _GameDetailsScreenState();
}

class _GameDetailsScreenState extends State<GameDetailsScreen> {
  late final ClubCubit _cubit;
  StreamSubscription<ClubState>? _cubitSub;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<ClubCubit>();
    _cubitSub = _cubit.stream.listen((state) {
      if (state is ClubError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.message),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      if (state is ClubActionSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.message),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _cubitSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ClubState>(
      stream: _cubit.stream,
      initialData: _cubit.state,
      builder: (context, snapshot) {
        return ThemedScaffold(
          appBar: AppBar(title: Text(widget.game.nameAr), centerTitle: true),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Game Info Header
                _GameInfoHeader(game: widget.game),
                // Playing children
                StreamBuilder<List<PlayingChild>>(
                  stream: _cubit.playingChildrenStream(widget.game.id),
                  builder: (context, snapshot) {
                    final children = snapshot.data ?? [];
                    if (children.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 56,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withAlpha(77),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'لا يوجد أطفال يلعبون الآن',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الأطفال يلعبون الآن',
                            style: TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          ...children.map(
                            (child) => _PlayingChildCard(
                              child: child,
                              onStop: () => _cubit.removePlayingChild(
                                gameId: widget.game.id,
                                childUserId: child.id,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                // Action Buttons
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        'إدارة اللعبة',
                        style: TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => _addChildToGame(context),
                          icon: const Icon(Icons.add),
                          label: const Text('إضافة طفل للعبة'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => _finishGame(context),
                          icon: const Icon(Icons.stop_circle_outlined),
                          label: const Text('إنهاء اللعبة'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.orange.shade600,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            onPressed: () => _addChildToGame(context),
            icon: const Icon(
              Icons.qr_code_scanner_rounded,
              color: Colors.white,
            ),
            label: const Text('مسح QR', style: TextStyle(color: Colors.white)),
          ),
        );
      },
    );
  }

  Future<void> _addChildToGame(BuildContext context) async {
    final shortId = await showScanOrManualInputSheet(
      context,
      title: widget.game.nameAr,
      icon: widget.game.icon,
      coinsDisplay: '${widget.game.coins} 🪙',
    );

    if (shortId == null || !context.mounted) return;

    context.read<ClubCubit>().playGame(
      gameId: widget.game.id,
      childShortId: shortId,
      gameCoins: widget.game.coins,
      gameName: widget.game.nameAr,
    );
  }

  void _finishGame(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إنهاء اللعبة'),
        content: Text('هل أنت متأكد من إنهاء ${widget.game.nameAr}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ClubCubit>().finishGame(widget.game.id);
            },
            child: const Text('إنهاء'),
          ),
        ],
      ),
    );
  }
}

class _GameInfoHeader extends StatelessWidget {
  final GameModel game;

  const _GameInfoHeader({required this.game});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.primary.withAlpha(191)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withAlpha(38),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(game.icon, style: const TextStyle(fontSize: 48)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.nameAr,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      game.name,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withAlpha(204),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🪙', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text(
                  '${game.coins} عملة',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: game.status == CardStatus.active
                  ? Colors.greenAccent.withAlpha(51)
                  : Colors.orangeAccent.withAlpha(51),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  game.status == CardStatus.active
                      ? Icons.check_circle
                      : Icons.pause_circle,
                  size: 16,
                  color: game.status == CardStatus.active
                      ? Colors.greenAccent
                      : Colors.orangeAccent,
                ),
                const SizedBox(width: 6),
                Text(
                  game.status == CardStatus.active ? 'نشط' : 'غير نشط',
                  style: TextStyle(
                    color: game.status == CardStatus.active
                        ? Colors.greenAccent
                        : Colors.orangeAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayingChildCard extends StatelessWidget {
  final PlayingChild child;
  final VoidCallback onStop;

  const _PlayingChildCard({required this.child, required this.onStop});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(128)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colorScheme.primary.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.person, color: colorScheme.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  child.fullName,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'الرمز: ${child.shortId}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withAlpha(128),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, color: colorScheme.error, size: 20),
            onPressed: onStop,
            iconSize: 20,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
