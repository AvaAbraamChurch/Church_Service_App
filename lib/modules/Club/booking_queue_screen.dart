import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/blocs/club/booking_queue_cubit.dart';
import '../../core/blocs/club/club_cubit.dart';
import '../../core/models/club/booking_queue_entry_model.dart';
import '../../core/models/club/game_model.dart';
import '../../core/models/club/played_queue_entry_model.dart';
import '../../core/models/user/user_model.dart';
import '../../core/repositories/club_repository.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/styles/themeScaffold.dart';
import 'game_details_screen.dart';

// ── Entry point ───────────────────────────────────────────────────────────────

class BookingQueueScreen extends StatelessWidget {
  final GameModel game;

  const BookingQueueScreen({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BookingQueueCubit(
        repository: ClubRepository(),
        gameId: game.id,
        game: game,
      )..init(),
      child: _BookingQueueBody(game: game),
    );
  }
}

// ── Main body ─────────────────────────────────────────────────────────────────

class _BookingQueueBody extends StatefulWidget {
  final GameModel game;
  const _BookingQueueBody({required this.game});

  @override
  State<_BookingQueueBody> createState() => _BookingQueueBodyState();
}

class _BookingQueueBodyState extends State<_BookingQueueBody> {
  // No manual StreamSubscription — BlocConsumer handles both listen + build
  // with a single internal subscription, eliminating the duplicate listener.

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BookingQueueCubit, BookingQueueState>(
      // Only rebuild UI on structural state changes — skip transient
      // Error/Success states so the loaded list is never wiped by a snackbar.
      buildWhen: (prev, curr) =>
          curr is BookingQueueLoading ||
          curr is BookingQueueInitial ||
          curr is BookingQueueLoaded,
      // Only fire listener on transient notification states.
      listenWhen: (prev, curr) =>
          curr is BookingQueueError || curr is BookingQueueSuccess,
      listener: (context, state) {
        if (state is BookingQueueError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ));
        } else if (state is BookingQueueSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ));
        }
      },
      builder: (context, state) {
        if (state is BookingQueueLoading || state is BookingQueueInitial) {
          return _buildScaffold(context, game: widget.game, body: _buildSkeleton());
        }
        if (state is BookingQueueLoaded) {
          return _buildScaffold(
            context,
            game: state.game,
            state: state,
            body: _BookingQueueContent(state: state),
          );
        }
        return _buildScaffold(context, game: widget.game, body: _buildSkeleton());
      },
    );
  }

  Widget _buildScaffold(
    BuildContext context, {
    required GameModel game,
    BookingQueueLoaded? state,
    required Widget body,
  }) {
    final cubit = context.read<BookingQueueCubit>();
    final isEnded = game.isEnded;
    final colorScheme = Theme.of(context).colorScheme;

    return ThemedScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Column(
          children: [
            Text(game.nameAr,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            if (state != null && state.isHistoryMode)
              Text(
                'سجل يوم ${_formatDateAr(state.viewDate)}',
                style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12),
              ),
          ],
        ),
        centerTitle: true,
        actions: [
          // History / calendar button
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined, color: Colors.white),
            tooltip: 'عرض يوم سابق',
            onPressed: () => _pickHistoryDate(context, cubit),
          ),
          if (state != null && state.isHistoryMode)
            IconButton(
              icon: const Icon(Icons.today_outlined, color: Colors.white),
              tooltip: 'العودة لليوم الحالي',
              onPressed: cubit.switchToToday,
            ),
          // Navigate to matches screen
          IconButton(
            icon: const Icon(Icons.sports_outlined, color: Colors.white),
            tooltip: 'المباريات والفرق',
            onPressed: () => _openMatchesScreen(context, game),
          ),
        ],
      ),
      body: body,
      floatingActionButton: (state == null || state.isHistoryMode || isEnded)
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showAddToQueueSheet(context, game),
              icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
              label: const Text('إضافة للقائمة', style: TextStyle(color: Colors.white)),
              backgroundColor: colorScheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (_, __) => const _SkeletonCard(),
    );
  }

  Future<void> _pickHistoryDate(
      BuildContext context, BookingQueueCubit cubit) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
    );
    if (picked != null) cubit.switchToDate(picked);
  }

  void _openMatchesScreen(BuildContext context, GameModel game) {
    final clubCubit = context.read<ClubCubit>();
    final bookingQueueCubit = context.read<BookingQueueCubit>();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: clubCubit),
          BlocProvider.value(value: bookingQueueCubit),
        ],
        child: GameDetailsScreen(game: game),
      ),
    ));
  }

  Future<void> _showAddToQueueSheet(
      BuildContext context, GameModel game) async {
    final cubit = context.read<BookingQueueCubit>();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: _AddToQueueSheet(game: game),
      ),
    );
  }

  String _formatDateAr(String date) {
    try {
      final dt = DateTime.parse(date);
      return DateFormat('d MMMM yyyy', 'ar').format(dt);
    } catch (_) {
      return date;
    }
  }
}

// ── Main content ──────────────────────────────────────────────────────────────

class _BookingQueueContent extends StatefulWidget {
  final BookingQueueLoaded state;
  const _BookingQueueContent({required this.state});

  @override
  State<_BookingQueueContent> createState() => _BookingQueueContentState();
}

class _BookingQueueContentState extends State<_BookingQueueContent> {
  bool _playedExpanded = false;
  bool _isOnline = ConnectivityService().isConnected;
  StreamSubscription<bool>? _connectivitySub;

  @override
  void initState() {
    super.initState();
    _connectivitySub = ConnectivityService().connectivityStream.listen((online) {
      if (mounted) setState(() => _isOnline = online);
    });
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final colorScheme = Theme.of(context).colorScheme;

    return CustomScrollView(
      slivers: [
        // ── Game header ───────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _GameHeaderCard(game: state.game, queueCount: state.bookingQueue.length),
          ),
        ),

        // ── Ended overlay ─────────────────────────────────────────────────
        if (state.game.isEnded)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: const _EndedBanner(),
            ),
          ),

        // ── Booking queue title ───────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
            child: Row(
              children: [
                Icon(Icons.queue_rounded, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text('قائمة الانتظار',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: colorScheme.onSurface)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${state.bookingQueue.length} طفل',
                    style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Booking queue list ────────────────────────────────────────────
        if (state.bookingQueue.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.people_outline,
                      size: 60,
                      color: colorScheme.onSurface.withOpacity(0.3)),
                  const SizedBox(height: 12),
                  Text('قائمة الانتظار فارغة',
                      style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.5))),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.separated(
              itemCount: state.bookingQueue.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final entry = state.bookingQueue[index];
                return _BookingEntryCard(
                  entry: entry,
                  position: index + 1,
                  isHistoryMode: state.isHistoryMode,
                  isGameEnded: state.game.isEnded,
                  isOnline: _isOnline,
                );
              },
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // ── Played queue section (collapsible) ────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => setState(() => _playedExpanded = !_playedExpanded),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: colorScheme.outlineVariant.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline,
                        color: Colors.green.shade600, size: 20),
                    const SizedBox(width: 8),
                    Text('الأطفال الذين لعبوا',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: colorScheme.onSurface)),
                    const Spacer(),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${state.playedQueue.length}',
                        style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: _playedExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.expand_more_rounded,
                          color: colorScheme.onSurface.withOpacity(0.6)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        if (_playedExpanded) ...[
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          if (state.playedQueue.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 16, 32, 16),
                child: Text(
                  'لا يوجد أطفال لعبوا بعد',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.5)),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              sliver: SliverList.separated(
                itemCount: state.playedQueue.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  return _PlayedEntryCard(
                      entry: state.playedQueue[index], index: index);
                },
              ),
            ),
        ],

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

// ── Game header card ──────────────────────────────────────────────────────────

class _GameHeaderCard extends StatelessWidget {
  final GameModel game;
  final int queueCount;
  const _GameHeaderCard({required this.game, required this.queueCount});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEnded = game.isEnded;
    final hasImage = game.imageUrl != null;

    return Container(
      height: hasImage ? 140 : null,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isEnded
              ? [Colors.grey.shade700, Colors.grey.shade500]
              : [colorScheme.primary, colorScheme.primary.withOpacity(0.75)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isEnded ? Colors.grey : colorScheme.primary).withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: hasImage ? StackFit.expand : StackFit.loose,
        children: [
          // ── Cover image background ──────────────────────────────────
          if (hasImage)
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: game.imageUrl!,
                fit: BoxFit.cover,
                color: Colors.black.withOpacity(isEnded ? 0.65 : 0.45),
                colorBlendMode: BlendMode.darken,
                placeholder: (_, __) => Container(color: Colors.black26),
                errorWidget: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),

          // ── Content ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                if (!hasImage)
                  Text(game.icon, style: const TextStyle(fontSize: 44))
                else
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(game.icon,
                        style: const TextStyle(fontSize: 26)),
                  ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(game.nameAr,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _Chip(
                              label: '🪙 ${game.coinCost} عملة',
                              color: Colors.amber),
                          const SizedBox(width: 8),
                          _Chip(
                            label: isEnded ? 'انتهى' : 'نشط',
                            color: isEnded
                                ? Colors.red.shade300
                                : Colors.greenAccent,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Queue count badge
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$queueCount',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900)),
                    Text('في الانتظار',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }
}

// ── Ended banner ──────────────────────────────────────────────────────────────

class _EndedBanner extends StatelessWidget {
  const _EndedBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_clock_outlined, color: Colors.red.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'انتهى وقت الحجز لهذه اللعبة',
              style: TextStyle(
                  color: Colors.red.shade700, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Booking entry card ────────────────────────────────────────────────────────

class _BookingEntryCard extends StatelessWidget {
  final BookingQueueEntry entry;
  final int position;
  final bool isHistoryMode;
  final bool isGameEnded;
  final bool isOnline;

  const _BookingEntryCard({
    required this.entry,
    required this.position,
    required this.isHistoryMode,
    required this.isGameEnded,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cubit = context.read<BookingQueueCubit>();
    final timeStr =
        DateFormat('h:mm a', 'ar').format(entry.bookedAt.toLocal());

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: position == 1
              ? Colors.amber.withOpacity(0.2)
              : colorScheme.primary.withOpacity(0.1),
          child: Text(
            '$position',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color:
                  position == 1 ? Colors.amber.shade700 : colorScheme.primary,
            ),
          ),
        ),
        title: Text(entry.childName,
            style:
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        subtitle: Row(
          children: [
            Icon(Icons.badge_outlined,
                size: 12, color: colorScheme.onSurface.withOpacity(0.5)),
            const SizedBox(width: 4),
            Text(entry.childShortId,
                style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 12)),
            const SizedBox(width: 12),
            Icon(Icons.access_time_outlined,
                size: 12, color: colorScheme.onSurface.withOpacity(0.5)),
            const SizedBox(width: 4),
            Text(timeStr,
                style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 12)),
          ],
        ),
        trailing: (isHistoryMode || isGameEnded)
            ? null
            : _ActionButtons(entry: entry, cubit: cubit, isOnline: isOnline),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final BookingQueueEntry entry;
  final BookingQueueCubit cubit;
  final bool isOnline;
  const _ActionButtons({required this.entry, required this.cubit, required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Mark as played — disabled while offline
        Tooltip(
          message: isOnline ? '' : 'غير متاح بدون اتصال بالإنترنت',
          child: FilledButton(
            onPressed: isOnline ? () => _confirmMarkPlayed(context) : null,
            style: FilledButton.styleFrom(
              backgroundColor: isOnline ? Colors.green.shade600 : Colors.grey.shade400,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('انتهى اللعب', style: TextStyle(fontSize: 12)),
          ),
        ),
        const SizedBox(width: 6),
        // Remove from queue
        IconButton(
          onPressed: () => _confirmRemove(context),
          icon: const Icon(Icons.remove_circle_outline_rounded),
          color: Colors.red.shade400,
          iconSize: 20,
          padding: EdgeInsets.zero,
          constraints:
              const BoxConstraints(minWidth: 32, minHeight: 32),
          tooltip: 'إزالة من القائمة',
        ),
      ],
    );
  }

  Future<void> _confirmMarkPlayed(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد انتهاء اللعب'),
        content: Text('هل انتهى ${entry.childName} من اللعب؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                  backgroundColor: Colors.green.shade600),
              child: const Text('نعم، انتهى')),
        ],
      ),
    );
    if (ok == true) cubit.markAsPlayed(entry);
  }

  Future<void> _confirmRemove(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إزالة من قائمة الانتظار؟'),
        content: Text('سيتم إزالة ${entry.childName} من قائمة الانتظار.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style:
                  FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
              child: const Text('إزالة')),
        ],
      ),
    );
    if (ok == true) cubit.removeFromQueue(entry);
  }
}

// ── Played entry card ─────────────────────────────────────────────────────────

class _PlayedEntryCard extends StatelessWidget {
  final PlayedQueueEntry entry;
  final int index;
  const _PlayedEntryCard({required this.entry, required this.index});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final timeStr =
        DateFormat('h:mm a', 'ar').format(entry.playedAt.toLocal());

    return Container(
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: Colors.green.withOpacity(0.15),
          child: Icon(Icons.check_rounded,
              color: Colors.green.shade700, size: 18),
        ),
        title: Text(entry.childName,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: colorScheme.onSurface)),
        trailing: Text(timeStr,
            style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.5),
                fontSize: 12)),
      ),
    );
  }
}

// ── Skeleton loader ───────────────────────────────────────────────────────────

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      height: 72,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}

// ── Add to queue bottom sheet ─────────────────────────────────────────────────

class _AddToQueueSheet extends StatefulWidget {
  final GameModel game;
  const _AddToQueueSheet({required this.game});

  @override
  State<_AddToQueueSheet> createState() => _AddToQueueSheetState();
}

enum _AddStep { choose, scan, manual, preview }

class _AddToQueueSheetState extends State<_AddToQueueSheet> {
  _AddStep _step = _AddStep.choose;
  final _manualCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  MobileScannerController? _scanCtrl;
  bool _scanned = false;

  // Preview step
  String? _scannedId;
  UserModel? _foundChild;
  bool _isLookingUp = false;
  String? _lookupError;

  @override
  void dispose() {
    _manualCtrl.dispose();
    _scanCtrl?.dispose();
    super.dispose();
  }

  void _startScan() {
    _scanCtrl = MobileScannerController();
    setState(() => _step = _AddStep.scan);
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code != null && code.isNotEmpty) {
      _scanned = true;
      _scanCtrl?.dispose();
      _scanCtrl = null;
      _lookupChild(code);
    }
  }

  Future<void> _lookupChild(String shortId) async {
    setState(() {
      _scannedId = shortId;
      _step = _AddStep.preview;
      _isLookingUp = true;
      _lookupError = null;
      _foundChild = null;
    });
    try {
      final repo = ClubRepository();
      final child = await repo.findChildByShortId(shortId);
      if (!mounted) return;
      if (child == null) {
        setState(() {
          _isLookingUp = false;
          _lookupError = 'لم يتم العثور على طفل بالرمز: $shortId';
        });
      } else {
        setState(() {
          _isLookingUp = false;
          _foundChild = child;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLookingUp = false;
        _lookupError = 'خطأ في البحث: $e';
      });
    }
  }

  void _confirmAdd(BuildContext context) {
    final cubit = context.read<BookingQueueCubit>();
    Navigator.pop(context); // close sheet
    cubit.addToQueue(_scannedId!);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Row(
                children: [
                  Text(widget.game.icon,
                      style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(widget.game.nameAr,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5A623).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '🪙 ${widget.game.coinCost}',
                      style: const TextStyle(
                          color: Color(0xFFF5A623),
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Step: choose mode ─────────────────────────────────────
              if (_step == _AddStep.choose) ...[
                _SheetOption(
                  icon: Icons.qr_code_scanner_rounded,
                  label: 'مسح QR Code',
                  sublabel: 'امسح رمز QR الخاص بالطفل',
                  onTap: _startScan,
                ),
                const SizedBox(height: 12),
                _SheetOption(
                  icon: Icons.keyboard_alt_outlined,
                  label: 'إدخال الرمز يدوياً',
                  sublabel: 'اكتب الرمز القصير للطفل',
                  onTap: () => setState(() => _step = _AddStep.manual),
                ),
              ],

              // ── Step: QR scan ──────────────────────────────────────────
              if (_step == _AddStep.scan) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 260,
                    child: MobileScanner(
                      controller: _scanCtrl!,
                      onDetect: _onDetect,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () {
                    _scanCtrl?.dispose();
                    _scanCtrl = null;
                    setState(() => _step = _AddStep.choose);
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('رجوع'),
                ),
              ],

              // ── Step: manual entry ─────────────────────────────────────
              if (_step == _AddStep.manual) ...[
                Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _manualCtrl,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: 'الرمز القصير',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'أدخل الرمز' : null,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => setState(() {
                        _step = _AddStep.choose;
                        _manualCtrl.clear();
                      }),
                      child: const Text('رجوع'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _lookupChild(_manualCtrl.text.trim());
                          }
                        },
                        child: const Text('بحث'),
                      ),
                    ),
                  ],
                ),
              ],

              // ── Step: preview child info ───────────────────────────────
              if (_step == _AddStep.preview) ...[
                if (_isLookingUp)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  )
                else if (_lookupError != null) ...[
                  Icon(Icons.error_outline,
                      color: Colors.red.shade400, size: 48),
                  const SizedBox(height: 12),
                  Text(_lookupError!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red.shade700)),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () => setState(() => _step = _AddStep.choose),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('حاول مرة أخرى'),
                  ),
                ] else if (_foundChild != null) ...[
                  _ChildPreviewCard(
                    child: _foundChild!,
                    coinCost: widget.game.coinCost,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () =>
                            setState(() => _step = _AddStep.choose),
                        child: const Text('إلغاء'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: (_foundChild!.clubCoins >= widget.game.coinCost)
                              ? () => _confirmAdd(context)
                              : null,
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('تأكيد الإضافة'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_foundChild!.clubCoins < widget.game.coinCost)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'رصيد العملات غير كافٍ للحجز',
                        style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ],

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Child preview card ────────────────────────────────────────────────────────

class _ChildPreviewCard extends StatelessWidget {
  final UserModel child;
  final int coinCost;
  const _ChildPreviewCard({required this.child, required this.coinCost});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final afterCoins = child.clubCoins - coinCost;
    final canAfford = child.clubCoins >= coinCost;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: canAfford
                ? colorScheme.primary.withOpacity(0.3)
                : Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: colorScheme.primary.withOpacity(0.1),
            backgroundImage: (child.profileImageUrl != null &&
                    child.profileImageUrl!.isNotEmpty)
                ? CachedNetworkImageProvider(child.profileImageUrl!)
                : null,
            child: (child.profileImageUrl == null || child.profileImageUrl!.isEmpty)
                ? Icon(Icons.person, color: colorScheme.primary, size: 32)
                : null,
          ),
          const SizedBox(height: 10),
          Text(
            child.fullName.isNotEmpty ? child.fullName : child.username,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'الرمز: ${child.shortId}',
            style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.6), fontSize: 13),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _CoinStat(
                  label: 'الرصيد الحالي',
                  value: child.clubCoins,
                  color: const Color(0xFFF5A623)),
              Icon(Icons.arrow_back_rounded,
                  color: colorScheme.onSurface.withOpacity(0.4)),
              _CoinStat(
                  label: 'بعد الخصم',
                  value: afterCoins,
                  color: canAfford ? Colors.teal : Colors.red),
            ],
          ),
        ],
      ),
    );
  }
}

class _CoinStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _CoinStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('🪙 $value',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                fontSize: 11)),
      ],
    );
  }
}

// ── Sheet option button ───────────────────────────────────────────────────────

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final VoidCallback onTap;
  const _SheetOption({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: colorScheme.primary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                  Text(sublabel,
                      style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withOpacity(0.5))),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 16,
                color: colorScheme.onSurface.withOpacity(0.4)),
          ],
        ),
      ),
    );
  }
}
