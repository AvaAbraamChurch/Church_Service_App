import 'dart:async';
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
import 'game_card.dart';
import 'game_details_screen.dart';
import 'manage_games_sheet.dart';
import 'manage_services_sheet.dart';


class ServantClubView extends StatefulWidget {
  final UserModel user;
  const ServantClubView({super.key, required this.user});

  @override
  State<ServantClubView> createState() => _ServantClubViewState();
}

class _ServantClubViewState extends State<ServantClubView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Timer _clockTimer;
  DateTime _now = DateTime.now();
  late final ClubCubit _cubit;
  StreamSubscription<ClubState>? _cubitSub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _clockTimer =
        Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
    _cubit = context.read<ClubCubit>();
    _cubitSub = _cubit.stream.listen((state) {
      if (state is ClubError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(state.message),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ));
      }
      if (state is ClubActionSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(state.message),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ));
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _clockTimer.cancel();
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
        if (state is ClubServantLoaded) {
          return _ServantContent(
            state: state,
            now: _now,
            tabController: _tabController,
            user: widget.user,
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

// ── Main content ──────────────────────────────────────────────────────────────

class _ServantContent extends StatelessWidget {
  final ClubServantLoaded state;
  final DateTime now;
  final TabController tabController;
  final UserModel user;

  const _ServantContent({
    required this.state,
    required this.now,
    required this.tabController,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ThemedScaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(
            child: _DateTimeHeader(now: now),
          ),
          SliverPersistentHeader(
            pinned: true,
            floating: false,
            delegate: _TabBarDelegate(
              TabBar(
                controller: tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.sports_esports_outlined), text: 'الألعاب'),
                  Tab(icon: Icon(Icons.how_to_reg_outlined), text: 'الحضور'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: tabController,
          children: [
            _GamesTab(games: state.games),
            _AttendanceTab(services: state.attendanceServices),
          ],
        ),
      ),
      floatingActionButton: _ServantFAB(state: state, user: user),
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

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.primary.withAlpha(191),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.primary.withAlpha(77),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withAlpha(38),
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
                  color: colorScheme.onPrimary.withAlpha(204),
                ),
              ),
            ],
          ),
          Icon(
            Icons.access_time_rounded,
            size: 40,
            color: colorScheme.onPrimary.withAlpha(153),
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
            Icon(Icons.sports_esports_outlined,
                size: 64, color: colorScheme.onSurface.withAlpha(77)),
            const SizedBox(height: 12),
            Text('لا توجد ألعاب. أضف ألعاباً من زر الإدارة.',
                style: TextStyle(
                    color: colorScheme.onSurface.withAlpha(128))),
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
        childAspectRatio: 0.88,
      ),
      itemCount: games.length,
      itemBuilder: (context, index) {
        final game = games[index];
        return GestureDetector(
          onTap: () => _openGameDetails(context, game),
          child: GameCard(
            game: game,
            isChildView: false,
          ),
        );
      },
    );
  }

  void _openGameDetails(BuildContext context, GameModel game) {
    final cubit = context.read<ClubCubit>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: GameDetailsScreen(game: game),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (services.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.how_to_reg_outlined,
                size: 64, color: colorScheme.onSurface.withAlpha(77)),
            const SizedBox(height: 12),
            Text('لا توجد خدمات. أضفها من زر الإدارة.',
                style: TextStyle(
                    color: colorScheme.onSurface.withAlpha(128))),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: services.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final service = services[index];
        return _AttendanceServiceCard(service: service);
      },
    );
  }
}

class _AttendanceServiceCard extends StatelessWidget {
  final AttendanceService service;
  const _AttendanceServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(128)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withAlpha(26),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.church_outlined,
                    color: colorScheme.primary, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(service.nameAr,
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('+${service.coinsValue} عملة 🪙',
                        style: TextStyle(
                            color: colorScheme.tertiary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAttendanceSheet(
      BuildContext context, AttendanceService service) async {
    final shortId =
        await _showAttendanceInputSheet(context, service);
    if (shortId == null || !context.mounted) return;
    context.read<ClubCubit>().recordAttendance(
          childShortId: shortId,
          coinsValue: service.coinsValue,
          serviceName: service.nameAr,
        );
  }

  Future<String?> _showAttendanceInputSheet(
      BuildContext context, AttendanceService service) {
    return showScanOrManualInputSheet(
      context,
      title: service.nameAr,
      icon: '🏫',
      coinsDisplay: '+${service.coinsValue} 🪙',
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
      child: const Icon(Icons.tune_rounded, color: Colors.white,),
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
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                showManageGamesSheet(context, state.games);
              },
              icon: const Icon(Icons.sports_esports_rounded),
              label: const Text('إدارة الألعاب'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                showManageServicesSheet(context, state.attendanceServices);
              },
              icon: const Icon(Icons.church_rounded),
              label: const Text('إدارة خدمات الحضور'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (isAdmin) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _confirmEndAllGames(context),
                icon: const Icon(Icons.power_settings_new_rounded),
                label: const Text('إنهاء جميع الألعاب الآن'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
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

// ── SliverPersistentHeader delegate for TabBar ────────────────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withAlpha(26),
            colorScheme.secondary.withAlpha(26),
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
