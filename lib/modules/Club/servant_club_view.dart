import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:church/core/styles/themeScaffold.dart';
import 'package:church/modules/Club/scan_or_manual_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/blocs/club/club_cubit.dart';
import '../../core/models/club/attendance_service_model.dart';
import '../../core/models/club/game_model.dart';
import '../../core/models/user/user_model.dart';
import '../../core/utils/userType_enum.dart';
import 'booking_queue_screen.dart';
import 'club_subscription_admin_screen.dart';
import 'manage_games_sheet.dart';
import 'manage_services_sheet.dart';

class ServantClubView extends StatefulWidget {
  final UserModel user;
  const ServantClubView({super.key, required this.user});

  @override
  State<ServantClubView> createState() => _ServantClubViewState();
}

class _ServantClubViewState extends State<ServantClubView>
    with WidgetsBindingObserver {
  late Timer _clockTimer;
  DateTime _now = DateTime.now();
  late final ClubCubit _cubit;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    _cubit = context.read<ClubCubit>();
  }

  // BUG 4: Re-evaluate 14:00 cutoff on app resume.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _cubit.onAppResumed();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clockTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // BlocConsumer replaces the old StreamBuilder + _cubitSub combo,
    // eliminating the duplicate subscription on the same stream.
    return BlocConsumer<ClubCubit, ClubState>(
      // Only rebuild when the loaded data or loading state changes —
      // skip transient ClubError / ClubActionSuccess to avoid flicker.
      buildWhen: (prev, curr) =>
          curr is ClubLoading ||
          curr is ClubInitial ||
          curr is ClubServantLoaded,
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
        if (state is ClubLoading || state is ClubInitial) {
          return _buildSkeleton();
        }
        if (state is ClubServantLoaded) {
          return _ServantContent(state: state, now: _now, user: widget.user);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: 6,
              itemBuilder: (_, __) => Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Main content ──────────────────────────────────────────────────────────────

class _ServantContent extends StatefulWidget {
  final ClubServantLoaded state;
  final DateTime now;
  final UserModel user;

  const _ServantContent({
    required this.state,
    required this.now,
    required this.user,
  });

  @override
  State<_ServantContent> createState() => _ServantContentState();
}

class _ServantContentState extends State<_ServantContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ThemedScaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(child: _DateTimeHeader(now: widget.now)),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.sports_esports_outlined),
                    text: 'الألعاب',
                  ),
                  Tab(icon: Icon(Icons.how_to_reg_outlined), text: 'الحضور'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _GamesTab(games: widget.state.games),
            _AttendanceTab(services: widget.state.attendanceServices),
          ],
        ),
      ),
      floatingActionButton: _ServantFAB(state: widget.state, user: widget.user),
    );
  }
}

// ── DateTime Header ───────────────────────────────────────────────────────────

class _DateTimeHeader extends StatelessWidget {
  final DateTime now;
  const _DateTimeHeader({required this.now});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final timeStr = DateFormat('hh:mm:ss a').format(now);
    final dateStr = DateFormat('EEEE، d MMMM y', 'ar').format(now);

    // BUG 4: show indicator when past 14:00
    final isPastCutoff = now.hour >= 14;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPastCutoff
              ? [Colors.grey.shade700, Colors.grey.shade600]
              : [colorScheme.primary, colorScheme.primary.withOpacity(0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isPastCutoff ? Colors.grey : colorScheme.primary)
                .withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                timeStr,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: colorScheme.onPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                dateStr,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onPrimary.withOpacity(0.8),
                ),
              ),
              if (isPastCutoff)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'انتهى وقت اللعب لهذا اليوم',
                    style: TextStyle(
                      color: Colors.red.shade200,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          Icon(
            isPastCutoff
                ? Icons.lock_clock_outlined
                : Icons.access_time_rounded,
            size: 40,
            color: colorScheme.onPrimary.withOpacity(0.6),
          ),
        ],
      ),
    );
  }
}

// ── Games Tab ─────────────────────────────────────────────────────────────────

class _GamesTab extends StatelessWidget {
  final List<GameModel> games;
  const _GamesTab({required this.games});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (games.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_esports_outlined,
              size: 64,
              color: colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'لا توجد ألعاب. أضف ألعاباً من زر الإدارة.',
              style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: games.length,
      itemBuilder: (context, index) {
        final game = games[index];
        return _ServantGameCard(game: game);
      },
    );
  }
}

// ── Servant game card (redesigned) ───────────────────────────────────────────

class _ServantGameCard extends StatelessWidget {
  final GameModel game;
  const _ServantGameCard({required this.game});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEnded = game.isEnded;
    final isBusy = game.status == CardStatus.busy;

    return InkWell(
      onTap: () => _openBookingQueue(context),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: isEnded
              ? colorScheme.surfaceContainerHighest.withOpacity(0.6)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isEnded
                ? Colors.red.withOpacity(0.25)
                : isBusy
                ? Colors.orangeAccent.withOpacity(0.4)
                : colorScheme.primary.withOpacity(0.25),
            width: 1.5,
          ),
          boxShadow: isEnded
              ? []
              : [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.07),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Stack(
          children: [
            // Gradient top accent
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  gradient: LinearGradient(
                    colors: isEnded
                        ? [Colors.grey, Colors.grey.shade400]
                        : [colorScheme.primary, colorScheme.secondary],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Cover image or emoji icon
                  if (game.imageUrl != null)
                    Opacity(
                      opacity: isEnded ? 0.5 : 1.0,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: game.imageUrl!,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            width: 64,
                            height: 64,
                            color: colorScheme.primary.withOpacity(0.1),
                            child: Text(
                              game.icon,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 32),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Text(
                            game.icon,
                            style: const TextStyle(fontSize: 38),
                          ),
                        ),
                      ),
                    )
                  else
                    Opacity(
                      opacity: isEnded ? 0.4 : 1.0,
                      child: Text(
                        game.icon,
                        style: const TextStyle(fontSize: 38),
                      ),
                    ),
                  const SizedBox(height: 8),
                  // Name
                  Text(
                    game.nameAr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: isEnded
                          ? colorScheme.onSurface.withOpacity(0.35)
                          : colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Coin cost chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isEnded
                          ? Colors.grey.withOpacity(0.15)
                          : const Color(0xFFF5A623).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '🪙 ${game.coinCost}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isEnded ? Colors.grey : const Color(0xFFF5A623),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // "فتح القائمة" hint
                  if (!isEnded)
                    Text(
                      'فتح القائمة',
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.primary.withOpacity(0.6),
                      ),
                    ),
                ],
              ),
            ),

            // Status badge
            Positioned(top: 8, left: 8, child: _StatusBadge(game: game)),

            // QR icon
            if (!isEnded)
              Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  Icons.qr_code_scanner_rounded,
                  size: 14,
                  color: colorScheme.primary.withOpacity(0.5),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openBookingQueue(BuildContext context) {
    final cubit = context.read<ClubCubit>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: BookingQueueScreen(game: game),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final GameModel game;
  const _StatusBadge({required this.game});

  @override
  Widget build(BuildContext context) {
    Color bg;
    String label;
    switch (game.status) {
      case CardStatus.ended:
        bg = Colors.red.shade700;
        label = 'انتهى';
        break;
      case CardStatus.busy:
        bg = Colors.orange.shade700;
        label = 'مشغول';
        break;
      case CardStatus.active:
        bg = Colors.green.shade600;
        label = 'نشط';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }
}

// ── Attendance Tab ────────────────────────────────────────────────────────────

class _AttendanceTab extends StatelessWidget {
  final List<AttendanceService> services;
  const _AttendanceTab({required this.services});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (services.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.how_to_reg_outlined,
              size: 64,
              color: colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'لا توجد خدمات. أضفها من زر الإدارة.',
              style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: services.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return _AttendanceServiceCard(service: services[index]);
      },
    );
  }
}

class _AttendanceServiceCard extends StatelessWidget {
  final AttendanceService service;
  const _AttendanceServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.church_outlined,
                  color: colorScheme.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.nameAr,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '+${service.coinsValue} عملة 🪙',
                      style: TextStyle(
                        color: colorScheme.tertiary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _showAttendanceSheet(context, service),
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
              label: const Text('تسجيل'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAttendanceSheet(
    BuildContext context,
    AttendanceService service,
  ) async {
    final shortId = await showScanOrManualInputSheet(
      context,
      title: service.nameAr,
      icon: '🏫',
      coinsDisplay: '+${service.coinsValue} 🪙',
    );
    if (shortId == null || !context.mounted) return;
    context.read<ClubCubit>().recordAttendance(
      childShortId: shortId,
      coinsValue: service.coinsValue,
      serviceName: service.nameAr,
    );
  }
}

// ── FAB ───────────────────────────────────────────────────────────────────────

class _ServantFAB extends StatelessWidget {
  final ClubServantLoaded state;
  final UserModel user;
  const _ServantFAB({required this.state, required this.user});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onPressed: () => _showManagementMenu(context),
      child: const Icon(Icons.tune_rounded, color: Colors.white),
    );
  }

  void _showManagementMenu(BuildContext context) {
    final cubit = context.read<ClubCubit>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: _ManagementMenu(state: state, user: user),
      ),
    );
  }
}

class _ManagementMenu extends StatelessWidget {
  final ClubServantLoaded state;
  final UserModel user;
  const _ManagementMenu({required this.state, required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isAdmin = user.isAdmin || user.userType == UserType.priest;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'إدارة النادي',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _MenuBtn(
            icon: Icons.sports_esports_rounded,
            label: 'إدارة الألعاب',
            onTap: () {
              Navigator.pop(context);
              showManageGamesSheet(context, state.games);
            },
          ),
          const SizedBox(height: 12),
          _MenuBtn(
            icon: Icons.church_rounded,
            label: 'إدارة خدمات الحضور',
            onTap: () {
              Navigator.pop(context);
              showManageServicesSheet(context, state.attendanceServices);
            },
          ),
          const SizedBox(height: 12),
          _MenuBtn(
            icon: Icons.how_to_reg_rounded,
            label: 'إدارة اشتراك النادي',
            onTap: () {
              final cubit = context.read<ClubCubit>();
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: cubit,
                    child: const ClubSubscriptionAdminScreen(),
                  ),
                ),
              );
            },
          ),
          if (isAdmin) ...[
            const SizedBox(height: 12),
            _MenuBtn(
              icon: Icons.power_settings_new_rounded,
              label: 'إنهاء جميع الألعاب الآن',
              color: Colors.red.shade700,
              onTap: () => _confirmEndAllGames(context),
            ),
            const SizedBox(height: 12),
            _MenuBtn(
              icon: Icons.refresh_rounded,
              label: 'إعادة تشغيل الألعاب',
              color: Colors.green.shade700,
              onTap: () {
                Navigator.pop(context);
                context.read<ClubCubit>().resetAllGames();
              },
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _confirmEndAllGames(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد إنهاء الألعاب'),
        content: const Text('سيتم إنهاء جميع الألعاب الحالية. هل أنت متأكد؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('إنهاء الآن'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      Navigator.pop(context);
      context.read<ClubCubit>().endAllGamesNow();
    }
  }
}

class _MenuBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _MenuBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final c = color ?? colorScheme.primary;
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: color != null ? c : colorScheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

// ── TabBar delegate ───────────────────────────────────────────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withOpacity(0.12),
            colorScheme.secondary.withOpacity(0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate old) => false;
}
