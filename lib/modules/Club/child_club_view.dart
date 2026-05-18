import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/blocs/club/club_cubit.dart';
import '../../core/models/user/user_model.dart';
import 'coin_history_screen.dart';
import 'game_card.dart';
import 'dart:async';

class ChildClubView extends StatefulWidget {
  final UserModel user;
  const ChildClubView({super.key, required this.user});

  @override
  State<ChildClubView> createState() => _ChildClubViewState();
}

class _ChildClubViewState extends State<ChildClubView> {
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
        final state = snapshot.data;
        if (state is ClubLoading || state is ClubInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is ClubChildLoaded) {
          return _ChildContent(user: widget.user, state: state);
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _ChildContent extends StatelessWidget {
  final UserModel user;
  final ClubChildLoaded state;
  const _ChildContent({required this.user, required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return CustomScrollView(
      slivers: [
        // ── Coins & Card Status Header ────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _CoinsHeader(
              coins: state.clubCoins,
              cardStatus: state.cardStatus,
              userName: user.fullName,
            ),
          ),
        ),

        // ── Section title ─────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الألعاب المتاحة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  '${state.games.length} لعبة',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withAlpha(179)),
                ),
              ],
            ),
          ),
        ),

        // ── Games Grid ────────────────────────────────────────────────────
        state.games.isEmpty
            ? SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.sports_esports_outlined,
                            size: 56,
                            color: colorScheme.onSurface.withAlpha(77)),
                        const SizedBox(height: 12),
                        Text('لا توجد ألعاب متاحة حالياً',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withAlpha(128),
                            )),
                      ],
                    ),
                  ),
                ),
              )
            : SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final game = state.games[index];
                      return GameCard(
                        game: game,
                        isChildView: true,
                        canAfford: state.clubCoins >= game.coins,
                        childUserId: user.id,
                      );
                    },
                    childCount: state.games.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.9,
                  ),
                ),
              ),

        // ── History Button ────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => CoinHistoryScreen(
                    transactions: state.transactions,
                    userName: user.fullName ?? '',
                  ),
                ));
              },
              icon: const Icon(Icons.history_rounded),
              label: const Text('سجل العملات'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Coins Header Widget ───────────────────────────────────────────────────────

class _CoinsHeader extends StatelessWidget {
  final int coins;
  final String cardStatus;
  final String userName;

  const _CoinsHeader({
    required this.coins,
    required this.cardStatus,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = cardStatus == 'active';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.primary.withAlpha(191),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withAlpha(89),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: greeting + card status badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'أهلاً، $userName 👋',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              _StatusBadge(isActive: isActive),
            ],
          ),
          const SizedBox(height: 20),

          // Coins display
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('🪙', style: TextStyle(fontSize: 36)),
              const SizedBox(width: 10),
              Text(
                '$coins',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'عملة',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'رصيدك الحالي في نادي صيف 2026',
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;
  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.greenAccent.withOpacity(0.2)
            : Colors.orange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? Colors.greenAccent : Colors.orange,
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle_outline : Icons.hourglass_top_rounded,
            size: 14,
            color: isActive ? Colors.greenAccent : Colors.orange,
          ),
          const SizedBox(width: 5),
          Text(
            isActive ? 'نشط' : 'مشغول',
            style: TextStyle(
              color: isActive ? Colors.greenAccent : Colors.orange,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
