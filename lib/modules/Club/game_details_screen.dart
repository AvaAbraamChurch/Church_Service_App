import 'dart:async';
import 'package:church/core/styles/themeScaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/blocs/club/club_cubit.dart';
import '../../core/models/club/game_model.dart';
import '../../core/models/club/playing_child_model.dart';
import '../../core/models/club/game_match_model.dart';
import '../../core/models/user/user_model.dart';
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
        final game = _resolveGame(snapshot.data);
        return ThemedScaffold(
          appBar: AppBar(
              backgroundColor: Colors.transparent,
              title: Text(game.nameAr, style: TextStyle(color: Colors.white),), centerTitle: true),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Game Info Header
                _GameInfoHeader(game: game),
                // Playing children
                StreamBuilder<List<PlayingChild>>(
                  stream: _cubit.playingChildrenStream(game.id),
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
                              color: Colors.white.withAlpha(150),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'لا يوجد أطفال يلعبون الآن',
                              style: TextStyle(
                                color: Colors.white.withAlpha(150),
                              ),
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
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...children.map(
                            (child) => _PlayingChildCard(
                              child: child,
                              onStop: () => _cubit.removePlayingChild(
                                gameId: game.id,
                                childUserId: child.id,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                if (game.allowBooking && game.bookingQueue.isNotEmpty)
                  _BookingQueueSection(cubit: _cubit, game: game),
                _MatchesSection(
                  cubit: _cubit,
                  game: game,
                  onCreate: () => _showCreateMatchDialog(context, game),
                  onSubmitResult: (match) =>
                      _showMatchResultDialog(context, game, match),
                  onToggleTimer: (match) => _toggleMatchTimer(game, match),
                  onAddTime: (match) => _showAddTimeDialog(context, game, match),
                ),
                // Action Buttons
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        'إدارة اللعبة',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => _addChildToGame(context, game),
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
                          onPressed: () => _finishGame(context, game),
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
            onPressed: () => _addChildToGame(context, game),
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

  GameModel _resolveGame(ClubState? state) {
    if (state is ClubServantLoaded) {
      return state.games.firstWhere(
        (g) => g.id == widget.game.id,
        orElse: () => widget.game,
      );
    }
    if (state is ClubChildLoaded) {
      return state.games.firstWhere(
        (g) => g.id == widget.game.id,
        orElse: () => widget.game,
      );
    }
    return widget.game;
  }

  Future<void> _addChildToGame(BuildContext context, GameModel game) async {
    final shortId = await showScanOrManualInputSheet(
      context,
      title: game.nameAr,
      icon: game.icon,
      coinsDisplay: '${game.coins} 🪙',
    );

    if (shortId == null || !context.mounted) return;

    context.read<ClubCubit>().playGame(
      gameId: game.id,
      childShortId: shortId,
      gameCoins: game.coins,
      gameName: game.nameAr,
    );
  }

  void _finishGame(BuildContext context, GameModel game) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إنهاء اللعبة'),
        content: Text('هل أنت متأكد من إنهاء ${game.nameAr}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ClubCubit>().finishGame(game.id);
            },
            child: const Text('إنهاء'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateMatchDialog(
    BuildContext context,
    GameModel game,
  ) async {
    final cubit = context.read<ClubCubit>();
    final queueUsers = await cubit.findUsersByIds(game.bookingQueue);
    final playingChildren = await cubit.playingChildrenStream(game.id).first;
    if (!context.mounted) return;

    final sizeCtrl = TextEditingController(text: '1');
    final durationCtrl = TextEditingController(text: '10');
    final teamA = <MatchPlayer>[];
    final teamB = <MatchPlayer>[];

    if (queueUsers.isEmpty && playingChildren.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('لا توجد قائمة حجز أو أطفال يلعبون الآن'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final size = int.tryParse(sizeCtrl.text) ?? 1;
          final canAddA = teamA.length < size;
          final canAddB = teamB.length < size;

          Widget buildTeamList(String title, List<MatchPlayer> players) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                if (players.isEmpty)
                  Text('لا يوجد لاعبين',
                      style: TextStyle(color: Colors.grey.shade600)),
                ...players.map(
                  (p) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(p.fullName.isEmpty ? p.shortId : p.fullName),
                    subtitle: Text('الرمز: ${p.shortId}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => setState(() => players.remove(p)),
                    ),
                  ),
                ),
              ],
            );
          }

          return AlertDialog(
            title: const Text('إنشاء مباراة'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: sizeCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'عدد اللاعبين لكل فريق',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: durationCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'مدة المباراة بالدقائق',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'قائمة الحجز (الدور)',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (queueUsers.isEmpty)
                    Text('لا توجد حجوزات حالياً',
                        style: TextStyle(color: Colors.grey.shade600)),
                  ...queueUsers.asMap().entries.map(
                    (entry) {
                      final idx = entry.key + 1;
                      final u = entry.value;
                      final label = u.fullName.isNotEmpty
                          ? u.fullName
                          : u.shortId;
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text('$idx) $label'),
                        subtitle: Text('الرمز: ${u.shortId}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: canAddA
                                  ? () {
                                      final player = MatchPlayer(
                                        id: u.id,
                                        fullName: u.fullName,
                                        shortId: u.shortId,
                                      );
                                      final exists = teamA.any(
                                              (p) => p.id == player.id) ||
                                          teamB.any(
                                              (p) => p.id == player.id);
                                      if (!exists) {
                                        setState(() => teamA.add(player));
                                      }
                                    }
                                  : null,
                              child: const Text('A'),
                            ),
                            TextButton(
                              onPressed: canAddB
                                  ? () {
                                      final player = MatchPlayer(
                                        id: u.id,
                                        fullName: u.fullName,
                                        shortId: u.shortId,
                                      );
                                      final exists = teamA.any(
                                              (p) => p.id == player.id) ||
                                          teamB.any(
                                              (p) => p.id == player.id);
                                      if (!exists) {
                                        setState(() => teamB.add(player));
                                      }
                                    }
                                  : null,
                              child: const Text('B'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'الأطفال يلعبون الآن',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (playingChildren.isEmpty)
                    Text('لا يوجد أطفال يلعبون الآن',
                        style: TextStyle(color: Colors.white.withAlpha(150))),
                  ...playingChildren.map(
                    (child) {
                      final label = child.fullName.isNotEmpty
                          ? child.fullName
                          : child.shortId;
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(label),
                        subtitle: Text('الرمز: ${child.shortId}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: canAddA
                                  ? () {
                                      final player = MatchPlayer(
                                        id: child.id,
                                        fullName: child.fullName,
                                        shortId: child.shortId,
                                      );
                                      final exists = teamA.any(
                                              (p) => p.id == player.id) ||
                                          teamB.any(
                                              (p) => p.id == player.id);
                                      if (!exists) {
                                        setState(() => teamA.add(player));
                                      }
                                    }
                                  : null,
                              child: const Text('A'),
                            ),
                            TextButton(
                              onPressed: canAddB
                                  ? () {
                                      final player = MatchPlayer(
                                        id: child.id,
                                        fullName: child.fullName,
                                        shortId: child.shortId,
                                      );
                                      final exists = teamA.any(
                                              (p) => p.id == player.id) ||
                                          teamB.any(
                                              (p) => p.id == player.id);
                                      if (!exists) {
                                        setState(() => teamB.add(player));
                                      }
                                    }
                                  : null,
                              child: const Text('B'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const Divider(height: 24),
                  buildTeamList('الفريق A', teamA),
                  const SizedBox(height: 8),
                  buildTeamList('الفريق B', teamB),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () {
                  final size = int.tryParse(sizeCtrl.text) ?? 0;
                  final minutes = int.tryParse(durationCtrl.text) ?? 0;
                  if (size <= 0 || teamA.length != size || teamB.length != size) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                            'تأكد من عدد اللاعبين في كل فريق'),
                        backgroundColor: Colors.red.shade700,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  if (minutes <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('أدخل مدة صحيحة بالدقائق'),
                        backgroundColor: Colors.red.shade700,
                        behavior: SnackBarBehavior.floating,
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
                    teamA: List<MatchPlayer>.from(teamA),
                    teamB: List<MatchPlayer>.from(teamB),
                    status: MatchStatus.pending,
                  );
                  cubit.createMatch(gameId: game.id, match: match);
                  Navigator.pop(context);
                },
                child: const Text('إنشاء'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showMatchResultDialog(
    BuildContext context,
    GameModel game,
    GameMatch match,
  ) async {
    final scoreACtrl = TextEditingController();
    final scoreBCtrl = TextEditingController();
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
              decoration: const InputDecoration(labelText: 'نتيجة الفريق A'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: scoreBCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'نتيجة الفريق B'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              final scoreA = int.tryParse(scoreACtrl.text) ?? -1;
              final scoreB = int.tryParse(scoreBCtrl.text) ?? -1;
              if (scoreA < 0 || scoreB < 0) return;
              _cubit.submitMatchResult(
                gameId: game.id,
                match: match,
                scoreA: scoreA,
                scoreB: scoreB,
              );
              Navigator.pop(context);
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
    final minutesCtrl = TextEditingController(text: '1');
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة وقت'),
        content: TextFormField(
          controller: minutesCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'دقائق إضافية'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              final minutes = int.tryParse(minutesCtrl.text) ?? 0;
              if (minutes <= 0) return;
              _cubit.addMatchExtraTime(
                gameId: game.id,
                match: match,
                extraSeconds: minutes * 60,
              );
              Navigator.pop(context);
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

class _BookingQueueSection extends StatelessWidget {
  final ClubCubit cubit;
  final GameModel game;

  const _BookingQueueSection({required this.cubit, required this.game});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant.withAlpha(128),
          ),
        ),
        child: FutureBuilder<List<dynamic>>(
          future: cubit.findUsersByIds(game.bookingQueue),
          builder: (context, snapshot) {
            final users = snapshot.data ?? [];
            if (users.isEmpty) {
              return const Text('لا توجد حجوزات حالياً');
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('الدور القادم',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...users.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final u = entry.value;
                  final label = u.fullName.isNotEmpty ? u.fullName : u.shortId;
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: idx == 1
                          ? Colors.green.withOpacity(0.15)
                          : Colors.transparent,
                      child: Text(idx.toString()),
                    ),
                    title: Text(label),
                    subtitle: Text('الرمز: ${u.shortId}'),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MatchesSection extends StatelessWidget {
  final ClubCubit cubit;
  final GameModel game;
  final VoidCallback onCreate;
  final ValueChanged<GameMatch> onSubmitResult;
  final ValueChanged<GameMatch> onToggleTimer;
  final ValueChanged<GameMatch> onAddTime;

  const _MatchesSection({
    required this.cubit,
    required this.game,
    required this.onCreate,
    required this.onSubmitResult,
    required this.onToggleTimer,
    required this.onAddTime,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant.withAlpha(128),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('المباريات',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                FilledButton.tonal(
                  onPressed: onCreate,
                  child: const Text('إنشاء مباراة'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            StreamBuilder<List<GameMatch>>(
              stream: cubit.matchesStream(game.id),
              builder: (context, snapshot) {
                final matches = snapshot.data ?? [];
                if (matches.isEmpty) {
                  return const Text('لا توجد مباريات');
                }
                return Column(
                  children: matches.map((m) {
                    return _MatchCard(
                      match: m,
                      onSubmitResult: onSubmitResult,
                      onToggleTimer: onToggleTimer,
                      onAddTime: onAddTime,
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchCard extends StatefulWidget {
  final GameMatch match;
  final ValueChanged<GameMatch> onSubmitResult;
  final ValueChanged<GameMatch> onToggleTimer;
  final ValueChanged<GameMatch> onAddTime;

  const _MatchCard({
    required this.match,
    required this.onSubmitResult,
    required this.onToggleTimer,
    required this.onAddTime,
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
    final match = widget.match;
    if (!match.isRunning || match.startedAt == null) return match.elapsedSeconds;
    final extra = DateTime.now().difference(match.startedAt!).inSeconds;
    return match.elapsedSeconds + extra;
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds.clamp(0, 999999);
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.match;
    final isFinished = match.status == MatchStatus.finished;
    final scoreText = isFinished
        ? '${match.scoreA ?? 0} - ${match.scoreB ?? 0}'
        : 'قيد اللعب';
    final elapsed = _effectiveElapsedSeconds();
    final total = match.durationSeconds;
    final remaining = (total - elapsed).clamp(0, total);

    String teamLabel(List<MatchPlayer> team) {
      return team
          .map((p) => p.fullName.isNotEmpty ? p.fullName : p.shortId)
          .join(' • ');
    }

    return Card(
      color: Colors.transparent,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('A: ${teamLabel(match.teamA)}'),
            const SizedBox(height: 4),
            Text('B: ${teamLabel(match.teamB)}'),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(scoreText),
                if (!isFinished)
                  TextButton(
                    onPressed: () => widget.onSubmitResult(match),
                    child: const Text('إدخال النتيجة'),
                  ),
              ],
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('الوقت: ${_formatDuration(Duration(seconds: elapsed))}'),
                Text('المتبقي: ${_formatDuration(Duration(seconds: remaining))}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                FilledButton.tonal(
                  onPressed: isFinished
                      ? null
                      : () => widget.onToggleTimer(match),
                  child: Text(match.isRunning ? 'إيقاف' : 'بدء'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: isFinished ? null : () => widget.onAddTime(match),
                  child: const Text('إضافة وقت'),
                ),
              ],
            ),
          ],
        ),
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
