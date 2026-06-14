import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/blocs/club/club_cubit.dart';
import '../../core/models/club/game_model.dart';


class GameCard extends StatelessWidget {
  final GameModel game;
  final bool isChildView;
  final bool canAfford;
  final String? childUserId;
  final VoidCallback? onTap;

  const GameCard({
    super.key,
    required this.game,
    this.isChildView = true,
    this.canAfford = true,
    this.childUserId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isEnded = game.isEnded;
    final isBusy = game.status == CardStatus.busy;

    final isBookable = isChildView && isBusy && game.allowBooking;
    final isAlreadyBooked = isBookable &&
        childUserId != null &&
        game.bookingQueue.contains(childUserId);
    final queuePosition = isAlreadyBooked
        ? game.bookingQueue.indexOf(childUserId!) + 1
        : null;
    final isLocked = isChildView && isBusy && !game.allowBooking;

    // Ended = fully blocked for children
    final isBlocked = isEnded;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: (isBlocked || isLocked)
            ? colorScheme.surfaceContainerHighest
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isBlocked
              ? Colors.red.withOpacity(0.25)
              : isLocked
                  ? colorScheme.outlineVariant.withOpacity(0.3)
                  : isBookable
                      ? Colors.amber.withOpacity(0.5)
                      : isChildView && !canAfford
                          ? colorScheme.outlineVariant.withOpacity(0.4)
                          : colorScheme.primary.withOpacity(0.25),
          width: 1.5,
        ),
        boxShadow: (isBlocked || isLocked)
            ? []
            : [
                BoxShadow(
                  color: isBookable
                      ? Colors.amber.withOpacity(0.12)
                      : colorScheme.primary.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Stack(
        children: [
          // ── Main content ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Opacity(
                  opacity: (isBlocked || isLocked) ? 0.3 : 1.0,
                  child: Text(game.icon,
                      style: const TextStyle(fontSize: 38)),
                ),
                const SizedBox(height: 8),
                Text(
                  game.nameAr,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: (isBlocked || isLocked)
                        ? colorScheme.onSurface.withOpacity(0.3)
                        : colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                // Coin cost chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isBlocked
                        ? Colors.red.withOpacity(0.08)
                        : isLocked
                            ? colorScheme.outlineVariant.withOpacity(0.2)
                            : isChildView && !canAfford
                                ? Colors.red.withOpacity(0.1)
                                : const Color(0xFFF5A623).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '🪙 ${game.coinCost}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isBlocked
                          ? Colors.red.shade400
                          : isLocked
                              ? colorScheme.onSurface.withOpacity(0.3)
                              : isChildView && !canAfford
                                  ? Colors.red.shade600
                                  : const Color(0xFFF5A623),
                    ),
                  ),
                ),

                // ── Booking button (child, bookable, busy) ────────────
                if (isBookable && !isBlocked) ...[
                  const SizedBox(height: 8),
                  isAlreadyBooked
                      ? _QueueBadge(
                          position: queuePosition!,
                          onCancel: () => context.read<ClubCubit>().cancelBooking(
                                gameId: game.id,
                                gameName: game.nameAr,
                              ),
                        )
                      : SizedBox(
                          width: double.infinity,
                          child: FilledButton.tonal(
                            onPressed: () => context.read<ClubCubit>().bookGame(
                                  gameId: game.id,
                                  gameName: game.nameAr,
                                ),
                            style: FilledButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 6),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              backgroundColor: Colors.amber.withOpacity(0.15),
                              foregroundColor: Colors.amber.shade800,
                            ),
                            child: const Text('احجز دورك',
                                style: TextStyle(fontSize: 12)),
                          ),
                        ),
                ],

                // "انتهى وقت اللعب" message for ended games in child view
                if (isBlocked && isChildView) ...[
                  const SizedBox(height: 6),
                  Text(
                    'انتهى وقت اللعب',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.red.shade400,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),

          // ── Status badge top-right ─────────────────────────────────────
          Positioned(
            top: 8,
            right: 8,
            child: _buildStatusBadge(),
          ),

          // ── Servant tap handler ───────────────────────────────────────
          if (!isChildView)
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: onTap,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    if (game.isEnded) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.shade700,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('انتهى',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10)),
      );
    }
    if (game.status == CardStatus.busy && isChildView && !game.allowBooking) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.shade700,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('مشغول',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11)),
      );
    }
    if (game.status == CardStatus.busy &&
        isChildView &&
        game.allowBooking &&
        !game.bookingQueue.contains(childUserId)) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.amber.shade700,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'مشغول • ${game.bookingQueue.length} في الانتظار',
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 10),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

// ── Queue position badge ──────────────────────────────────────────────────────

class _QueueBadge extends StatelessWidget {
  final int position;
  final VoidCallback onCancel;

  const _QueueBadge({required this.position, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.green.withOpacity(0.4)),
          ),
          child: Text(
            'دورك رقم $position 🎉',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700),
          ),
        ),
        TextButton(
          onPressed: onCancel,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 28),
            foregroundColor: Colors.red.shade400,
          ),
          child: const Text('إلغاء الحجز', style: TextStyle(fontSize: 11)),
        ),
      ],
    );
  }
}
