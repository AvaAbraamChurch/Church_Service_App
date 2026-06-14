import 'package:church/core/services/connectivity_service.dart';
import 'package:church/core/styles/themeScaffold.dart';
import 'package:church/core/utils/userType_enum.dart';
import 'package:church/modules/Club/servant_club_view.dart';
import 'package:church/modules/Club/child_club_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/blocs/club/club_cubit.dart';
import '../../core/models/user/user_model.dart';
import '../../core/repositories/club_repository.dart';


class ClubScreen extends StatefulWidget {
  final UserModel user;
  const ClubScreen({super.key, required this.user});

  @override
  State<ClubScreen> createState() => _ClubScreenState();
}

class _ClubScreenState extends State<ClubScreen> {
  @override
  Widget build(BuildContext context) {
    final isChild = widget.user.userType == UserType.child;

    return BlocProvider(
      create: (_) => ClubCubit(
        repository: ClubRepository(),
        userId: widget.user.id,
        userGender: widget.user.gender,
        initialCoins: widget.user.clubCoins,
        initialCardStatus: widget.user.cardStatus,
        isChild: isChild,
      )..init(),
      // No StreamBuilder here — sub-views (ServantClubView / ChildClubView)
      // each manage their own BlocBuilder. The outer scaffold never needs to
      // rebuild on cubit state changes, eliminating unnecessary AppBar rebuilds.
      child: ThemedScaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text(
            'نادي صيف 2026',
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // ── Persistent offline banner ─────────────────────────────
            const _OfflineBanner(),

            // ── Club content ──────────────────────────────────────────
            Expanded(
              child: switch (widget.user.userType) {
                UserType.child => ChildClubView(user: widget.user),
                UserType.servant => ServantClubView(user: widget.user),
                UserType.superServant => ServantClubView(user: widget.user),
                UserType.priest => ServantClubView(user: widget.user),
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Offline banner ────────────────────────────────────────────────────────────

/// Shows a persistent Arabic banner whenever connectivity is lost.
/// Uses [ConnectivityService] which is already initialised in main().
class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: ConnectivityService().connectivityStream,
      initialData: ConnectivityService().isConnected,
      builder: (context, snap) {
        final isOnline = snap.data ?? true;
        return AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: isOnline
              ? const SizedBox.shrink()
              : const _BannerContent(),
        );
      },
    );
  }
}

class _BannerContent extends StatelessWidget {
  const _BannerContent();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.red.shade800,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'أنت غير متصل بالإنترنت — البيانات قد لا تكون محدثة',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Exposed for use in sub-screens that are pushed on top of ClubScreen
/// (e.g. BookingQueueScreen) and need to show the banner independently.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) => const _OfflineBanner();
}
