import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/club/attendance_service_model.dart';
import '../../models/club/coin_transaction_model.dart';
import '../../models/club/game_model.dart';
import '../../models/club/game_match_model.dart';
import '../../models/club/playing_child_model.dart';
import '../../models/user/user_model.dart';
import '../../repositories/club_repository.dart';
import '../../services/supabase_end_all_games_service.dart';
import '../../utils/gender_enum.dart';
import '../../models/club/club_subscription_info_model.dart';
import '../../models/club/club_subscription_request_model.dart';

part 'club_state.dart';

class ClubCubit extends Cubit<ClubState> {
  final ClubRepository _repo;
  final SupabaseEndAllGamesService _endAllGamesService;
  final String userId;
  final Gender userGender;

  // ── Stream subscriptions (BUG 3) ─────────────────────────────────────────
  StreamSubscription? _gamesSub;
  StreamSubscription? _txSub;
  StreamSubscription? _servicesSub;
  StreamSubscription? _coinsSub; // live child coins

  Timer? _autoEndTimer;

  List<GameModel> _games = [];
  List<CoinTransaction> _transactions = [];
  List<AttendanceService> _attendanceServices = [];
  int _clubCoins;
  String _cardStatus;
  bool _isChild;

  ClubCubit({
    required ClubRepository repository,
    required this.userId,
    required this.userGender,
    required int initialCoins,
    required String initialCardStatus,
    required bool isChild,
    SupabaseEndAllGamesService? endAllGamesService,
  })  : _repo = repository,
        _endAllGamesService = endAllGamesService ?? SupabaseEndAllGamesService(),
        _clubCoins = initialCoins,
        _cardStatus = initialCardStatus,
        _isChild = isChild,
        super(ClubInitial());

  void init() {
    if (_isChild) {
      _initChildStreams();
    } else {
      _initServantStreams();
    }
    _scheduleOrRunAutoEnd();
  }

  // ── BUG 4: auto-end at 14:00 ─────────────────────────────────────────────

  void _scheduleOrRunAutoEnd() {
    _autoEndTimer?.cancel();
    final now = DateTime.now();
    final todayAtTwo = DateTime(now.year, now.month, now.day, 14);

    if (now.isAfter(todayAtTwo) || now.isAtSameMomentAs(todayAtTwo)) {
      // Already past 14:00 → close immediately.
      _closeAllGamesNow(showSnackbar: false);
    } else {
      final delay = todayAtTwo.difference(now);
      _autoEndTimer = Timer(delay, () {
        _closeAllGamesNow(showSnackbar: true);
        // No reschedule — we only end once per day.
      });
    }
  }

  /// Called from AppLifecycleState.resumed so we re-evaluate the cutoff.
  void onAppResumed() {
    _scheduleOrRunAutoEnd();
  }

  Future<void> _closeAllGamesNow({bool showSnackbar = true}) async {
    try {
      await _endAllGamesService.endAllGames();
    } catch (_) {
      try {
        await _repo.endAllGames();
      } catch (_) {
        // Silent — background job, don't surface to user.
        return;
      }
    }
    if (showSnackbar) {
      emit(ClubActionSuccess('انتهى وقت اللعب لهذا اليوم'));
      if (_isChild) {
        _emitChild();
      } else {
        _emitServant();
      }
    }
  }

  // ── Child streams ─────────────────────────────────────────────────────────

  void _initChildStreams() {
    emit(ClubLoading());

    // BUG 3: subscribe to games stream
    _gamesSub = _repo
        .gamesStream(genderCode: _genderFilterCode())
        .listen((games) {
      _games = games;
      _emitChild();
    });

    // BUG 3: subscribe to coin transactions
    _txSub = _repo.coinTransactionsStream(userId).listen((txs) {
      _transactions = txs;
      _emitChild();
    });

    // BUG 3: live coin balance (so UI updates instantly after deductions)
    _coinsSub = _repo.childCoinsStream(userId).listen((coins) {
      _clubCoins = coins;
      _emitChild();
    });
  }

  void _emitChild() {
    emit(ClubChildLoaded(
      games: _games,
      transactions: _transactions,
      clubCoins: _clubCoins,
      cardStatus: _cardStatus,
    ));
  }

  void updateCoins(int newCoins) {
    _clubCoins = newCoins;
    if (_isChild) _emitChild();
  }

  // ── Servant streams ───────────────────────────────────────────────────────

  void _initServantStreams() {
    emit(ClubLoading());

    // BUG 3: subscribe to games stream
    _gamesSub = _repo
        .gamesStream(genderCode: _genderFilterCode())
        .listen((games) {
      _games = games;
      _emitServant();
    });

    // BUG 3: subscribe to attendance services stream
    _servicesSub = _repo.attendanceServicesStream().listen((services) {
      _attendanceServices = services;
      _emitServant();
    });
  }

  void _emitServant() {
    emit(ClubServantLoaded(
      games: _games,
      attendanceServices: _attendanceServices,
    ));
  }

  String? _genderFilterCode() {
    return userGender == Gender.female ? Gender.female.code : null;
  }

  // ── Games management ──────────────────────────────────────────────────────

  Future<void> addGame(GameModel game) async {
    try {
      await _repo.addGame(game);
    } catch (e) {
      emit(ClubError('فشل إضافة اللعبة: $e'));
    }
  }

  Future<void> updateGame(GameModel game) async {
    try {
      await _repo.updateGame(game);
    } catch (e) {
      emit(ClubError('فشل تحديث اللعبة: $e'));
    }
  }

  Future<void> deleteGame(String gameId) async {
    try {
      await _repo.deleteGame(gameId);
    } catch (e) {
      emit(ClubError('فشل حذف اللعبة: $e'));
    }
  }

  Future<void> updateGameStatus({
    required String gameId,
    required CardStatus status,
  }) async {
    try {
      final game = _games.firstWhere(
        (g) => g.id == gameId,
        orElse: () => GameModel(
          id: gameId,
          nameAr: '',
          name: '',
          gender: Gender.male,
          coins: 0,
          icon: '',
          status: status,
        ),
      );
      final updatedGame = game.copyWith(status: status);
      await _repo.updateGame(updatedGame);
      final statusText = status == CardStatus.active ? 'تشغيل' : 'إيقاف';
      emit(ClubActionSuccess('تم $statusText ${game.nameAr}'));
      _emitServant();
    } catch (e) {
      emit(ClubError('فشل تحديث حالة اللعبة: $e'));
    }
  }

  Future<void> resetAllGames() async {
    try {
      await _repo.resetAllGames();
      emit(ClubActionSuccess('تم إعادة تشغيل جميع الألعاب'));
      _emitServant();
    } catch (e) {
      emit(ClubError('فشل إعادة التشغيل: $e'));
    }
  }

  Future<void> endAllGamesNow() async {
    try {
      await _endAllGamesService.endAllGames();
      emit(ClubActionSuccess('تم إنهاء جميع الألعاب'));
      _emitServant();
    } catch (e) {
      try {
        await _repo.endAllGames();
        emit(ClubActionSuccess('تم إنهاء جميع الألعاب'));
        _emitServant();
      } catch (inner) {
        emit(ClubError('فشل إنهاء جميع الألعاب: $inner'));
      }
    }
  }

  // ── Play game (servant scans child) ──────────────────────────────────────

  Future<void> playGame({
    required String gameId,
    required String childShortId,
    required int gameCoins,
    required String gameName,
  }) async {
    try {
      final child = await _repo.findChildByShortId(childShortId);
      if (child == null) {
        emit(ClubError('لم يتم العثور على الطفل'));
        _emitServant();
        return;
      }
      // BUG 1: coin validation in cubit layer
      final childCoins = child.clubCoins;
      if (childCoins < gameCoins) {
        emit(ClubError('رصيد العملات غير كافٍ للحجز'));
        _emitServant();
        return;
      }
      await _repo.playGame(
        gameId: gameId,
        child: child,
        childShortId: childShortId,
        gameCoins: gameCoins,
        gameName: gameName,
      );
      final displayName = child.fullName.isNotEmpty
          ? child.fullName
          : (child.username.isNotEmpty ? child.username : childShortId);
      emit(ClubActionSuccess('تم خصم $gameCoins عملة من $displayName'));
      _emitServant();
    } catch (e) {
      emit(ClubError('حدث خطأ: $e'));
      _emitServant();
    }
  }

  Stream<List<PlayingChild>> playingChildrenStream(String gameId) {
    return _repo.playingChildrenStream(gameId);
  }

  Stream<List<GameMatch>> matchesStream(String gameId) {
    return _repo.matchesStream(gameId);
  }

  Future<List<dynamic>> findUsersByIds(List<String> ids) {
    return _repo.findUsersByIds(ids);
  }

  Future<UserModel?> findChildByShortId(String shortId) {
    return _repo.findChildByShortId(shortId);
  }

  Future<void> createMatch({
    required String gameId,
    required GameMatch match,
  }) async {
    try {
      await _repo.createMatch(gameId: gameId, match: match);
      emit(ClubActionSuccess('تم إنشاء المباراة'));
      _emitServant();
    } catch (e) {
      emit(ClubError('فشل إنشاء المباراة: $e'));
      _emitServant();
    }
  }

  Future<void> updateMatch({
    required String gameId,
    required GameMatch match,
  }) async {
    try {
      await _repo.updateMatch(gameId: gameId, match: match);
      emit(ClubActionSuccess('تم تحديث المباراة'));
      _emitServant();
    } catch (e) {
      emit(ClubError('فشل تحديث المباراة: $e'));
      _emitServant();
    }
  }

  /// BUG 2: Delete match with fresh state emit.
  Future<void> deleteMatch({
    required String gameId,
    required String matchId,
  }) async {
    try {
      await _repo.deleteMatch(gameId: gameId, matchId: matchId);
      emit(ClubActionSuccess('تم حذف المباراة'));
      _emitServant();
    } catch (e) {
      emit(ClubError('فشل حذف المباراة: $e'));
      _emitServant();
    }
  }

  Future<void> submitMatchResult({
    required String gameId,
    required GameMatch match,
    required int scoreA,
    required int scoreB,
  }) async {
    try {
      final now = DateTime.now();
      final startedAt = match.startedAt;
      final extra = (!match.isRunning || startedAt == null)
          ? 0
          : now.difference(startedAt).inSeconds;
      final updated = match.copyWith(
        scoreA: scoreA,
        scoreB: scoreB,
        status: MatchStatus.finished,
        isRunning: false,
        startedAt: null,
        elapsedSeconds: match.elapsedSeconds + extra,
        updatedAt: DateTime.now(),
      );
      await _repo.updateMatch(gameId: gameId, match: updated);
      emit(ClubActionSuccess('تم حفظ نتيجة المباراة'));
      _emitServant();
    } catch (e) {
      emit(ClubError('فشل حفظ النتيجة: $e'));
      _emitServant();
    }
  }

  Future<void> startMatchTimer({
    required String gameId,
    required GameMatch match,
  }) async {
    try {
      final updated = match.copyWith(
        isRunning: true,
        startedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _repo.updateMatch(gameId: gameId, match: updated);
    } catch (e) {
      emit(ClubError('فشل تشغيل المؤقت: $e'));
      _emitServant();
    }
  }

  Future<void> stopMatchTimer({
    required String gameId,
    required GameMatch match,
  }) async {
    try {
      final now = DateTime.now();
      final startedAt = match.startedAt;
      final extra =
          startedAt == null ? 0 : now.difference(startedAt).inSeconds;
      final updated = match.copyWith(
        isRunning: false,
        startedAt: null,
        elapsedSeconds: match.elapsedSeconds + extra,
        updatedAt: DateTime.now(),
      );
      await _repo.updateMatch(gameId: gameId, match: updated);
    } catch (e) {
      emit(ClubError('فشل إيقاف المؤقت: $e'));
      _emitServant();
    }
  }

  Future<void> addMatchExtraTime({
    required String gameId,
    required GameMatch match,
    required int extraSeconds,
  }) async {
    try {
      final updated = match.copyWith(
        durationSeconds: match.durationSeconds + extraSeconds,
        updatedAt: DateTime.now(),
      );
      await _repo.updateMatch(gameId: gameId, match: updated);
    } catch (e) {
      emit(ClubError('فشل إضافة وقت إضافي: $e'));
      _emitServant();
    }
  }

  Future<void> removePlayingChild({
    required String gameId,
    required String childUserId,
  }) async {
    try {
      await _repo.removePlayingChild(
        gameId: gameId,
        childUserId: childUserId,
      );
      emit(ClubActionSuccess('تم إنهاء لعب الطفل'));
      _emitServant();
    } catch (e) {
      emit(ClubError('فشل إنهاء لعب الطفل: $e'));
      _emitServant();
    }
  }

  Future<void> finishGame(String gameId) async {
    try {
      await _repo.clearPlayingChildren(gameId);
      final game = _games.firstWhere((g) => g.id == gameId);
      await _repo.updateGame(game.copyWith(status: CardStatus.active));
      emit(ClubActionSuccess('تم إنهاء اللعبة وإتاحة اللعب من جديد'));
      _emitServant();
    } catch (e) {
      emit(ClubError('فشل إنهاء اللعبة: $e'));
      _emitServant();
    }
  }

  // ── Booking (child queues for a busy bookable game) ───────────────────────

  Future<void> bookGame({
    required String gameId,
    required String gameName,
  }) async {
    try {
      final added = await _repo.bookGame(
        gameId: gameId,
        childUserId: userId,
      );
      if (added) {
        emit(ClubActionSuccess('تم حجز دورك في $gameName'));
      } else {
        emit(ClubError('أنت محجوز بالفعل في هذه اللعبة'));
      }
      _emitChild();
    } catch (e) {
      emit(ClubError('فشل الحجز: $e'));
      _emitChild();
    }
  }

  Future<void> cancelBooking({
    required String gameId,
    required String gameName,
  }) async {
    try {
      await _repo.cancelBooking(gameId: gameId, childUserId: userId);
      emit(ClubActionSuccess('تم إلغاء حجزك في $gameName'));
      _emitChild();
    } catch (e) {
      emit(ClubError('فشل إلغاء الحجز: $e'));
      _emitChild();
    }
  }

  // ── Attendance services ───────────────────────────────────────────────────

  Future<void> addAttendanceService(AttendanceService service) async {
    try {
      await _repo.addAttendanceService(service);
    } catch (e) {
      emit(ClubError('فشل إضافة الخدمة: $e'));
    }
  }

  Future<void> updateAttendanceService(AttendanceService service) async {
    try {
      await _repo.updateAttendanceService(service);
    } catch (e) {
      emit(ClubError('فشل تحديث الخدمة: $e'));
    }
  }

  Future<void> deleteAttendanceService(String id) async {
    try {
      await _repo.deleteAttendanceService(id);
    } catch (e) {
      emit(ClubError('فشل حذف الخدمة: $e'));
    }
  }

  Future<void> recordAttendance({
    required String childShortId,
    required int coinsValue,
    required String serviceName,
  }) async {
    try {
      final childId = await _repo.recordAttendance(
        childShortId: childShortId,
        coinsValue: coinsValue,
        serviceName: serviceName,
      );
      if (childId == null) {
        emit(ClubError('لم يتم العثور على الطفل'));
      } else {
        emit(ClubActionSuccess('تم إضافة $coinsValue عملة للحضور'));
      }
      _emitServant();
    } catch (e) {
      emit(ClubError('حدث خطأ: $e'));
      _emitServant();
    }
  }

  // ── Club subscription ─────────────────────────────────────────────────────

  Stream<ClubSubscriptionInfo?> clubSubscriptionInfoStream() {
    return _repo.clubSubscriptionInfoStream();
  }

  Stream<ClubSubscriptionRequest?> mySubscriptionRequestStream() {
    return _repo.subscriptionRequestForChild(userId);
  }

  Stream<List<ClubSubscriptionRequest>> subscriptionRequestsStream({
    SubscriptionRequestStatus? status,
  }) {
    return _repo.subscriptionRequestsStream(status: status);
  }

  Future<void> updateClubSubscriptionInfo({
    required String title,
    required String description,
  }) async {
    try {
      final info = ClubSubscriptionInfo(
        id: ClubSubscriptionInfo.docId,
        title: title,
        description: description,
        updatedAt: DateTime.now(),
        updatedBy: userId,
      );
      await _repo.upsertClubSubscriptionInfo(info);
      emit(ClubActionSuccess('تم حفظ معلومات الاشتراك'));
    } catch (e) {
      emit(ClubError('فشل حفظ المعلومات: $e'));
    }
  }

  Future<bool> submitClubSubscriptionRequest({
    required UserModel child,
  }) async {
    try {
      final created = await _repo.createSubscriptionRequest(child: child);
      if (created) {
        emit(ClubActionSuccess('تم إرسال طلب الاشتراك'));
      } else {
        emit(ClubError('لديك طلب اشتراك قائم بالفعل'));
      }
      if (_isChild) _emitChild();
      return created;
    } catch (e) {
      emit(ClubError('فشل إرسال الطلب: $e'));
      if (_isChild) _emitChild();
      return false;
    }
  }

  Future<void> approveClubSubscriptionRequest({
    required ClubSubscriptionRequest request,
  }) async {
    try {
      await _repo.approveSubscriptionRequest(
        request: request,
        approvedBy: userId,
      );
      emit(ClubActionSuccess('تمت الموافقة على الطلب'));
      _emitServant();
    } catch (e) {
      emit(ClubError('فشل الموافقة: $e'));
      _emitServant();
    }
  }

  @override
  Future<void> close() {
    _gamesSub?.cancel();
    _txSub?.cancel();
    _servicesSub?.cancel();
    _coinsSub?.cancel();
    _autoEndTimer?.cancel();
    return super.close();
  }
}
