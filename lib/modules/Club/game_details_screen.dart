import 'dart:async';

import 'package:church/core/styles/themeScaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/blocs/club/booking_queue_cubit.dart';
import '../../core/blocs/club/club_cubit.dart';
import '../../core/models/club/game_match_model.dart';
import '../../core/models/club/game_model.dart';
import '../../core/models/club/playing_child_model.dart';
import '../../core/models/user/user_model.dart';

/// Matches & Teams screen — redesigned for BUG 2 fix.
class GameDetailsScreen extends StatefulWidget {
  final GameModel game;

  const GameDetailsScreen({super.key, required this.game});

  @override
  State<GameDetailsScreen> createState() => _GameDetailsScreenState();
}

class _GameDetailsScreenState extends State<GameDetailsScreen> {
  late final ClubCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<ClubCubit>();
  }

  @override
  Widget build(BuildContext context) {
    // BlocConsumer replaces the old StreamBuilder + _cubitSub combination,
    // using a single internal subscription for both listening and building.
    return BlocConsumer<ClubCubit, ClubState>(
      buildWhen: (prev, curr) =>
          curr is ClubServantLoaded || curr is ClubLoading,
      listenWhen: (prev, curr) =>
          curr is ClubError || curr is ClubActionSuccess,
      listener: (context, state) {
        if (state is ClubError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state is ClubActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final game = _resolveGame(state);
        return ThemedScaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: Text(
              game.nameAr,
              style: const TextStyle(color: Colors.white),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                _GameInfoHeader(game: game),

                // Playing children section
                StreamBuilder<List<PlayingChild>>(
                  stream: _cubit.playingChildrenStream(game.id),
                  builder: (context, snap) {
                    final children = snap.data ?? [];
                    if (children.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'الأطفال يلعبون الآن',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...children.map(
                            (child) => _PlayingChildCard(
                              child: child,
                              onStop: () =>
                                  _confirmStopChild(context, game, child),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Matches section
                _MatchesSection(
                  cubit: _cubit,
                  game: game,
                  onCreate: () => _showCreateMatchDialog(context, game),
                  onSubmitResult: (m) =>
                      _showMatchResultDialog(context, game, m),
                  onToggleTimer: (m) => _toggleMatchTimer(game, m),
                  onAddTime: (m) => _showAddTimeDialog(context, game, m),
                  onEditTeam: (m) => _showEditTeamDialog(context, game, m),
                  onDeleteMatch: (m) => _confirmDeleteMatch(context, game, m),
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        );
      },
    );
  }

  GameModel _resolveGame(ClubState? state) {
    if (state is ClubServantLoaded) {
      return state.games.firstWhere(
        (g) => g.id == widget.game.id,
        orElse: () => widget.game,
      );
    }
    return widget.game;
  }

  void _confirmStopChild(
    BuildContext context,
    GameModel game,
    PlayingChild child,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إيقاف اللعب'),
        content: Text('هل تريد إنهاء لعب ${child.displayName}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('نعم'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      _cubit.removePlayingChild(gameId: game.id, childUserId: child.id);
    }
  }

  // ── Match creation ────────────────────────────────────────────────────────

  Future<void> _showCreateMatchDialog(
    BuildContext context,
    GameModel game,
  ) async {
    final cubit = _cubit;

    // ── Collect available players ──────────────────────────────────────────
    // Priority: live day-scoped booking queue (from BookingQueueCubit if
    // navigated from BookingQueueScreen). Falls back to the old static
    // game.bookingQueue for backward compatibility.
    List<MatchPlayer> availablePlayers = [];
    String availableSection = 'قائمة الانتظار اليوم';

    try {
      final queueCubit = context.read<BookingQueueCubit>();
      final queueState = queueCubit.state;
      if (queueState is BookingQueueLoaded) {
        // Only show children still waiting (not yet played)
        availablePlayers = queueState.bookingQueue
            .where((e) => e.status == 'waiting')
            .map((e) => MatchPlayer(
                  id: e.childId,
                  fullName: e.childName,
                  shortId: e.childShortId,
                ))
            .toList();
      }
    } catch (_) {
      // BookingQueueCubit not in context — use the static list
      final users = await cubit.findUsersByIds(game.bookingQueue);
      availablePlayers = users
          .whereType<UserModel>()
          .map((u) => MatchPlayer(
                id: u.id,
                fullName: u.fullName,
                shortId: u.shortId,
              ))
          .toList();
      availableSection = 'الحجوزات';
    }

    // Also include children currently playing
    final playingChildren = await cubit.playingChildrenStream(game.id).first;
    final playingPlayers = playingChildren
        .map((c) => MatchPlayer(
              id: c.id,
              fullName: c.fullName,
              shortId: c.shortId,
            ))
        .toList();

    if (!context.mounted) return;

    if (availablePlayers.isEmpty && playingPlayers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('لا يوجد أطفال في قائمة الانتظار حالياً'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final sizeCtrl = TextEditingController(text: '1');
    final durationCtrl = TextEditingController(text: '10');
    final nameACtrl = TextEditingController(text: 'الفريق أ');
    final nameBCtrl = TextEditingController(text: 'الفريق ب');
    final teamA = <MatchPlayer>[];
    final teamB = <MatchPlayer>[];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) {
          final size = int.tryParse(sizeCtrl.text) ?? 1;
          final canAddA = teamA.length < size;
          final canAddB = teamB.length < size;

          Widget buildTeamBox(
            String title,
            List<MatchPlayer> players,
            TextEditingController nameCtrl,
          ) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'اسم الفريق',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 6),
                if (players.isEmpty)
                  const Text(
                    'لا يوجد لاعبين بعد',
                    style: TextStyle(fontSize: 12),
                  ),
                ...players.map(
                  (p) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      p.fullName.isNotEmpty ? p.fullName : p.shortId,
                      style: const TextStyle(fontSize: 13),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () => setDlg(() => players.remove(p)),
                    ),
                  ),
                ),
              ],
            );
          }

          /// A single player row showing the child's name with A/B assignment buttons.
          Widget playerRow(MatchPlayer p) {
            final label = p.fullName.isNotEmpty ? p.fullName : p.shortId;
            final alreadyAssigned =
                teamA.any((x) => x.id == p.id) || teamB.any((x) => x.id == p.id);

            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: alreadyAssigned ? Colors.grey : null,
                  decoration:
                      alreadyAssigned ? TextDecoration.lineThrough : null,
                ),
              ),
              trailing: alreadyAssigned
                  ? const Icon(Icons.check_circle_outline,
                      size: 18, color: Colors.green)
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FilledButton.tonal(
                          onPressed: canAddA
                              ? () => setDlg(() => teamA.add(p))
                              : null,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                          ),
                          child: Text(
                            nameACtrl.text.isEmpty
                                ? 'أ'
                                : nameACtrl.text.substring(0, 1),
                          ),
                        ),
                        const SizedBox(width: 4),
                        FilledButton.tonal(
                          onPressed: canAddB
                              ? () => setDlg(() => teamB.add(p))
                              : null,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                          ),
                          child: Text(
                            nameBCtrl.text.isEmpty
                                ? 'ب'
                                : nameBCtrl.text.substring(0, 1),
                          ),
                        ),
                      ],
                    ),
            );
          }

          return AlertDialog(
            title: const Text('إنشاء مباراة'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: sizeCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'لاعبون/فريق',
                              isDense: true,
                            ),
                            onChanged: (_) => setDlg(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: durationCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'المدة (دقيقة)',
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // ── Available players from today's queue ────────────────
                    if (availablePlayers.isNotEmpty) ...[
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          availableSection,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ...availablePlayers.map(playerRow),
                    ],
                    // ── Children currently playing ──────────────────────────
                    if (playingPlayers.isNotEmpty) ...[
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'يلعبون الآن',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ...playingPlayers.map(playerRow),
                    ],
                    const Divider(height: 24),
                    buildTeamBox('الفريق الأول', teamA, nameACtrl),
                    const SizedBox(height: 12),
                    buildTeamBox('الفريق الثاني', teamB, nameBCtrl),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () {
                  final size = int.tryParse(sizeCtrl.text) ?? 0;
                  final minutes = int.tryParse(durationCtrl.text) ?? 0;
                  if (size <= 0 ||
                      teamA.length != size ||
                      teamB.length != size) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: const Text('تأكد من عدد اللاعبين في كل فريق'),
                        backgroundColor: Colors.red.shade700,
                      ),
                    );
                    return;
                  }
                  if (minutes <= 0) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: const Text('أدخل مدة صحيحة بالدقائق'),
                        backgroundColor: Colors.red.shade700,
                      ),
                    );
                    return;
                  }
                  final match = GameMatch(
                    id: '',
                    gameId: game.id,
                    sizePerTeam: size,
                    durationSeconds: minutes * 60,
                    elapsedSeconds: 0,
                    isRunning: false,
                    startedAt: null,
                    teamA: List.from(teamA),
                    teamB: List.from(teamB),
                    nameA: nameACtrl.text.trim().isEmpty
                        ? 'الفريق أ'
                        : nameACtrl.text.trim(),
                    nameB: nameBCtrl.text.trim().isEmpty
                        ? 'الفريق ب'
                        : nameBCtrl.text.trim(),
                  );
                  cubit.createMatch(gameId: game.id, match: match);
                  Navigator.pop(ctx);
                },
                child: const Text('إنشاء'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── BUG 2: Edit team dialog ───────────────────────────────────────────────

  Future<void> _showEditTeamDialog(
    BuildContext context,
    GameModel game,
    GameMatch match,
  ) async {
    final nameACtrl = TextEditingController(text: match.nameA);
    final nameBCtrl = TextEditingController(text: match.nameB);
    List<MatchPlayer> teamA = List.from(match.teamA);
    List<MatchPlayer> teamB = List.from(match.teamB);

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) {
          Widget teamSection(
            String label,
            TextEditingController ctrl,
            List<MatchPlayer> team,
            List<MatchPlayer> other,
          ) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: ctrl,
                  decoration: const InputDecoration(
                    labelText: 'اسم الفريق',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 6),
                ...team.asMap().entries.map((e) {
                  final player = e.value;
                  final label = player.fullName.isNotEmpty
                      ? player.fullName
                      : player.shortId;
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.person_outline,
                      color: Theme.of(ctx).colorScheme.primary,
                    ),
                    title: Text(label, style: const TextStyle(fontSize: 13)),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      tooltip: 'إزالة اللاعب',
                      onPressed: () async {
                        // BUG 2: Confirmation dialog for player removal
                        final ok = await showDialog<bool>(
                          context: ctx,
                          builder: (c2) => AlertDialog(
                            title: const Text('إزالة اللاعب'),
                            content: Text(
                              'هل تريد إزالة هذا اللاعب من الفريق؟\n$label',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(c2, false),
                                child: const Text('إلغاء'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(c2, true),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.red.shade700,
                                ),
                                child: const Text('إزالة'),
                              ),
                            ],
                          ),
                        );
                        if (ok == true) setDlg(() => team.remove(player));
                      },
                    ),
                    // Move to other team button
                    subtitle: TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        setDlg(() {
                          team.remove(player);
                          other.add(player);
                        });
                      },
                      child: Text(
                        'نقل إلى ${ctrl == nameACtrl ? nameBCtrl.text : nameACtrl.text}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  );
                }),
              ],
            );
          }

          return AlertDialog(
            title: const Text('تعديل الفرق'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    teamSection('الفريق الأول', nameACtrl, teamA, teamB),
                    const Divider(height: 20),
                    teamSection('الفريق الثاني', nameBCtrl, teamB, teamA),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () {
                  final updated = match.copyWith(
                    teamA: teamA,
                    teamB: teamB,
                    nameA: nameACtrl.text.trim().isEmpty
                        ? 'الفريق أ'
                        : nameACtrl.text.trim(),
                    nameB: nameBCtrl.text.trim().isEmpty
                        ? 'الفريق ب'
                        : nameBCtrl.text.trim(),
                    updatedAt: DateTime.now(),
                  );
                  _cubit.updateMatch(gameId: game.id, match: updated);
                  Navigator.pop(ctx);
                },
                child: const Text('حفظ التعديلات'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── BUG 2: Delete match with confirmation ─────────────────────────────────

  Future<void> _confirmDeleteMatch(
    BuildContext context,
    GameModel game,
    GameMatch match,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف المباراة'),
        content: const Text('هل أنت متأكد من حذف هذه المباراة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      _cubit.deleteMatch(gameId: game.id, matchId: match.id);
    }
  }

  // ── Match result dialog ───────────────────────────────────────────────────

  Future<void> _showMatchResultDialog(
    BuildContext context,
    GameModel game,
    GameMatch match,
  ) async {
    final scoreACtrl = TextEditingController(
      text: match.scoreA != null ? '${match.scoreA}' : '',
    );
    final scoreBCtrl = TextEditingController(
      text: match.scoreB != null ? '${match.scoreB}' : '',
    );
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إدخال النتيجة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: scoreACtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'نتيجة ${match.nameA}'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: scoreBCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'نتيجة ${match.nameB}'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              final sA = int.tryParse(scoreACtrl.text) ?? -1;
              final sB = int.tryParse(scoreBCtrl.text) ?? -1;
              if (sA < 0 || sB < 0) return;
              _cubit.submitMatchResult(
                gameId: game.id,
                match: match,
                scoreA: sA,
                scoreB: sB,
              );
              Navigator.pop(ctx);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddTimeDialog(
    BuildContext context,
    GameModel game,
    GameMatch match,
  ) async {
    final ctrl = TextEditingController(text: '1');
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة وقت'),
        content: TextFormField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'دقائق إضافية'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              final m = int.tryParse(ctrl.text) ?? 0;
              if (m <= 0) return;
              _cubit.addMatchExtraTime(
                gameId: game.id,
                match: match,
                extraSeconds: m * 60,
              );
              Navigator.pop(ctx);
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _toggleMatchTimer(GameModel game, GameMatch match) {
    if (match.isRunning) {
      _cubit.stopMatchTimer(gameId: game.id, match: match);
    } else {
      _cubit.startMatchTimer(gameId: game.id, match: match);
    }
  }
}

// ── Matches section ───────────────────────────────────────────────────────────

class _MatchesSection extends StatelessWidget {
  final ClubCubit cubit;
  final GameModel game;
  final VoidCallback onCreate;
  final ValueChanged<GameMatch> onSubmitResult;
  final ValueChanged<GameMatch> onToggleTimer;
  final ValueChanged<GameMatch> onAddTime;
  final ValueChanged<GameMatch> onEditTeam;
  final ValueChanged<GameMatch> onDeleteMatch;

  const _MatchesSection({
    required this.cubit,
    required this.game,
    required this.onCreate,
    required this.onSubmitResult,
    required this.onToggleTimer,
    required this.onAddTime,
    required this.onEditTeam,
    required this.onDeleteMatch,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outlineVariant.withOpacity(0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'المباريات والفرق',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                FilledButton.tonal(
                  onPressed: onCreate,
                  child: const Text('إنشاء مباراة'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<GameMatch>>(
              stream: cubit.matchesStream(game.id),
              builder: (context, snap) {
                final matches = snap.data ?? [];
                if (matches.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'لا توجد مباريات بعد',
                        style: TextStyle(color: Colors.white.withOpacity(0.5)),
                      ),
                    ),
                  );
                }
                return Column(
                  children: matches
                      .map(
                        (m) => _MatchCard(
                          match: m,
                          onSubmitResult: onSubmitResult,
                          onToggleTimer: onToggleTimer,
                          onAddTime: onAddTime,
                          onEditTeam: onEditTeam,
                          onDeleteMatch: onDeleteMatch,
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Match card ────────────────────────────────────────────────────────────────

class _MatchCard extends StatefulWidget {
  final GameMatch match;
  final ValueChanged<GameMatch> onSubmitResult;
  final ValueChanged<GameMatch> onToggleTimer;
  final ValueChanged<GameMatch> onAddTime;
  final ValueChanged<GameMatch> onEditTeam;
  final ValueChanged<GameMatch> onDeleteMatch;

  const _MatchCard({
    required this.match,
    required this.onSubmitResult,
    required this.onToggleTimer,
    required this.onAddTime,
    required this.onEditTeam,
    required this.onDeleteMatch,
  });

  @override
  State<_MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends State<_MatchCard> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _syncTicker();
  }

  @override
  void didUpdateWidget(covariant _MatchCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.match.isRunning != widget.match.isRunning ||
        oldWidget.match.startedAt != widget.match.startedAt) {
      _syncTicker();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _syncTicker() {
    _ticker?.cancel();
    if (widget.match.isRunning) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  int _effectiveElapsedSeconds() {
    final m = widget.match;
    if (!m.isRunning || m.startedAt == null) return m.elapsedSeconds;
    return m.elapsedSeconds + DateTime.now().difference(m.startedAt!).inSeconds;
  }

  String _fmt(int seconds) {
    final s = seconds.clamp(0, 999999);
    return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.match;
    final isFinished = match.status == MatchStatus.finished;
    final elapsed = _effectiveElapsedSeconds();
    final remaining = (match.durationSeconds - elapsed).clamp(
      0,
      match.durationSeconds,
    );

    String teamLabel(List<MatchPlayer> team) => team
        .map((p) => p.fullName.isNotEmpty ? p.fullName : p.shortId)
        .join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Team display (two-column) ─────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      match.nameA,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      teamLabel(match.teamA),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isFinished
                      ? Colors.green.withOpacity(0.15)
                      : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isFinished
                      ? '${match.scoreA ?? 0} - ${match.scoreB ?? 0}'
                      : _fmt(elapsed),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      match.nameB,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      teamLabel(match.teamB),
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (!isFinished) ...[
            const SizedBox(height: 4),
            Text(
              'المتبقي: ${_fmt(remaining)}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 11,
              ),
            ),
          ],

          const Divider(height: 16, color: Colors.white24),

          // ── Action buttons ────────────────────────────────────────────
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (!isFinished) ...[
                _ActionChip(
                  label: match.isRunning ? 'إيقاف' : 'بدء',
                  icon: match.isRunning
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  onTap: () => widget.onToggleTimer(match),
                ),
                _ActionChip(
                  label: 'إضافة وقت',
                  icon: Icons.more_time_rounded,
                  onTap: () => widget.onAddTime(match),
                ),
                _ActionChip(
                  label: 'إدخال النتيجة',
                  icon: Icons.scoreboard_outlined,
                  onTap: () => widget.onSubmitResult(match),
                  color: Colors.green,
                ),
              ],
              // BUG 2: Edit teams button (always visible for pending matches)
              if (!isFinished)
                _ActionChip(
                  label: 'تعديل الفرق',
                  icon: Icons.group_outlined,
                  onTap: () => widget.onEditTeam(match),
                  color: Colors.blue,
                ),
              // BUG 2: Delete match
              _ActionChip(
                label: 'حذف',
                icon: Icons.delete_outline_rounded,
                onTap: () => widget.onDeleteMatch(match),
                color: Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _ActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.white;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: c.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: c.withOpacity(0.9)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: c.withOpacity(0.9),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Game info header ──────────────────────────────────────────────────────────

class _GameInfoHeader extends StatelessWidget {
  final GameModel game;
  const _GameInfoHeader({required this.game});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEnded = game.isEnded;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isEnded
              ? [Colors.grey.shade700, Colors.grey.shade500]
              : [colorScheme.primary, colorScheme.primary.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isEnded ? Colors.grey : colorScheme.primary).withOpacity(
              0.3,
            ),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                    if (game.name.isNotEmpty)
                      Text(
                        game.name,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.75),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoChip(label: '🪙 ${game.coinCost} عملة', color: Colors.amber),
              const SizedBox(width: 8),
              _InfoChip(
                label: isEnded
                    ? 'انتهى'
                    : game.status == CardStatus.busy
                    ? 'مشغول'
                    : 'نشط',
                color: isEnded
                    ? Colors.red.shade300
                    : game.status == CardStatus.busy
                    ? Colors.orangeAccent
                    : Colors.greenAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;
  const _InfoChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

// ── Playing child card ────────────────────────────────────────────────────────

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
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.person, color: colorScheme.primary, size: 22),
        ),
        title: Text(
          child.displayName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'الرمز: ${child.shortId}',
          style: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.55),
            fontSize: 12,
          ),
        ),
        trailing: IconButton(
          icon: Icon(Icons.close_rounded, color: colorScheme.error, size: 20),
          onPressed: onStop,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
