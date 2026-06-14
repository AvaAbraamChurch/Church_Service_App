import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../models/club/booking_queue_entry_model.dart';
import '../../models/club/game_model.dart';
import '../../models/club/played_queue_entry_model.dart';
import '../../repositories/club_repository.dart';
import '../../services/connectivity_service.dart';

part 'booking_queue_state.dart';

class BookingQueueCubit extends Cubit<BookingQueueState> {
  final ClubRepository _repo;
  final String gameId;
  final GameModel game;

  /// The date being viewed — today by default, can be changed for history mode.
  String _viewDate;

  StreamSubscription<List<BookingQueueEntry>>? _bookingSub;
  StreamSubscription<List<PlayedQueueEntry>>? _playedSub;

  List<BookingQueueEntry> _bookingQueue = [];
  List<PlayedQueueEntry> _playedQueue = [];
  bool _isHistoryMode = false;

  BookingQueueCubit({
    required ClubRepository repository,
    required this.gameId,
    required this.game,
  })  : _repo = repository,
        _viewDate = DateFormat('yyyy-MM-dd').format(DateTime.now()),
        super(BookingQueueInitial());

  String get viewDate => _viewDate;
  bool get isHistoryMode => _isHistoryMode;

  void init() => _subscribeToDate(_viewDate);

  void _subscribeToDate(String date) {
    _bookingSub?.cancel();
    _playedSub?.cancel();
    emit(BookingQueueLoading());

    _bookingSub = _repo.bookingQueueStream(date, gameId).listen(
      (entries) {
        _bookingQueue = entries;
        _emitLoaded();
      },
      onError: (e) => emit(BookingQueueError('خطأ في تحميل قائمة الحجز: $e')),
    );

    _playedSub = _repo.playedQueueStream(date, gameId).listen(
      (entries) {
        _playedQueue = entries;
        _emitLoaded();
      },
      onError: (e) => emit(BookingQueueError('خطأ في تحميل سجل اللاعبين: $e')),
    );
  }

  void _emitLoaded() {
    emit(BookingQueueLoaded(
      bookingQueue: List.unmodifiable(_bookingQueue),
      playedQueue: List.unmodifiable(_playedQueue),
      game: game,
      viewDate: _viewDate,
      isHistoryMode: _isHistoryMode,
    ));
  }

  /// Switch to history mode for a past date.
  void switchToDate(DateTime date) {
    final formatted = DateFormat('yyyy-MM-dd').format(date);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _viewDate = formatted;
    _isHistoryMode = formatted != today;
    _subscribeToDate(formatted);
  }

  /// Switch back to today (live mode).
  void switchToToday() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _viewDate = today;
    _isHistoryMode = false;
    _subscribeToDate(today);
  }

  // ── Add to queue ──────────────────────────────────────────────────────────

  /// Validates coins and adds child to booking queue.
  /// BUG 1 fix: coin validation happens in the cubit layer, not just UI.
  Future<void> addToQueue(String childShortId) async {
    if (_isHistoryMode) return; // no mutations on history

    // Connectivity guard — coin deduction requires server confirmation
    if (!ConnectivityService().isConnected) {
      emit(BookingQueueError('لا يمكن تنفيذ هذا الإجراء بدون اتصال بالإنترنت'));
      _emitLoaded();
      return;
    }

    // Check game is still active
    if (game.isEnded) {
      emit(BookingQueueError('انتهى وقت الحجز لهذه اللعبة'));
      _emitLoaded();
      return;
    }

    // Optimistic: show loading indicator without wiping list
    final prevState = state;

    try {
      final error = await _repo.addToBookingQueue(
        date: _viewDate,
        gameId: gameId,
        gameName: game.nameAr,
        childShortId: childShortId,
        coinCost: game.coinCost,
      );

      if (error != null) {
        emit(BookingQueueError(error));
        if (prevState is BookingQueueLoaded) emit(prevState);
        return;
      }

      emit(const BookingQueueSuccess('تم إضافة الطفل إلى قائمة الحجز ✓'));
      // Stream will refresh the loaded state automatically.
    } catch (e) {
      emit(BookingQueueError('حدث خطأ أثناء الحجز: $e'));
      if (prevState is BookingQueueLoaded) emit(prevState);
    }
  }

  // ── Mark as played ────────────────────────────────────────────────────────

  /// BUG 5 fix: moves entry from booking_queue → played_queue.
  Future<void> markAsPlayed(BookingQueueEntry entry) async {
    if (_isHistoryMode) return;

    // Connectivity guard — queue mutation must be confirmed by server
    if (!ConnectivityService().isConnected) {
      emit(BookingQueueError('لا يمكن تنفيذ هذا الإجراء بدون اتصال بالإنترنت'));
      _emitLoaded();
      return;
    }

    // Optimistic remove from local list
    _bookingQueue = _bookingQueue.where((e) => e.id != entry.id).toList();
    _emitLoaded();

    try {
      await _repo.markAsPlayed(
        date: _viewDate,
        gameId: gameId,
        entry: entry,
      );
      emit(const BookingQueueSuccess('تم تسجيل انتهاء اللعب ✓'));
    } catch (e) {
      // Rollback optimistic update — stream will correct it.
      emit(BookingQueueError('فشل تسجيل اللعب: $e'));
    }
  }

  // ── Remove from queue ─────────────────────────────────────────────────────

  Future<void> removeFromQueue(BookingQueueEntry entry) async {
    if (_isHistoryMode) return;

    // Optimistic remove
    _bookingQueue = _bookingQueue.where((e) => e.id != entry.id).toList();
    _emitLoaded();

    try {
      await _repo.removeFromBookingQueue(
        date: _viewDate,
        gameId: gameId,
        docId: entry.id,
      );
      emit(const BookingQueueSuccess('تم إزالة الطفل من قائمة الانتظار'));
    } catch (e) {
      emit(BookingQueueError('فشل الإزالة: $e'));
    }
  }

  @override
  Future<void> close() {
    _bookingSub?.cancel();
    _playedSub?.cancel();
    return super.close();
  }
}
