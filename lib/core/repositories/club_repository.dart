import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../services/cloudinary_upload_service.dart';

import '../models/club/attendance_service_model.dart';
import '../models/club/booking_queue_entry_model.dart';
import '../models/club/coin_transaction_model.dart';
import '../models/club/game_model.dart';
import '../models/club/game_match_model.dart';
import '../models/club/played_queue_entry_model.dart';
import '../models/club/playing_child_model.dart';
import '../models/user/user_model.dart';
import '../models/club/club_subscription_info_model.dart';
import '../models/club/club_subscription_request_model.dart';


class ClubRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final CloudinaryUploadService _cloudinary = CloudinaryUploadService();

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String todayDate() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  CollectionReference _bookingQueueRef(String date, String gameId) => _db
      .collection('club_days')
      .doc(date)
      .collection('game_sessions')
      .doc(gameId)
      .collection('booking_queue');

  CollectionReference _playedQueueRef(String date, String gameId) => _db
      .collection('club_days')
      .doc(date)
      .collection('game_sessions')
      .doc(gameId)
      .collection('played_queue');

  // ── Games ────────────────────────────────────────────────────────────────

  Stream<List<GameModel>> gamesStream({String? genderCode}) {
    final query = genderCode == null
        ? _db.collection('club_games')
        : _db.collection('club_games').where('gender', isEqualTo: genderCode);
    return query
        .snapshots()
        .map((s) => s.docs.map(GameModel.fromFirestore).toList());
  }

  Future<void> addGame(GameModel game) =>
      _db.collection('club_games').add(game.toMap());

  Future<void> updateGame(GameModel game) =>
      _db.collection('club_games').doc(game.id).update(game.toMap());

  Future<void> deleteGame(String gameId) =>
      _db.collection('club_games').doc(gameId).delete();

  /// Uploads a game cover image to Cloudinary and returns the secure URL.
  /// Uses [gameId] as the stable public ID so re-uploads overwrite the
  /// previous file instead of orphaning it.
  Future<String> uploadGameImage({
    required String gameId,
    required XFile imageFile,
  }) {
    return _cloudinary.uploadGameCoverImage(File(imageFile.path), gameId);
  }

  /// Sets game status to busy and deducts coins from the child.
  Future<void> playGame({
    required String gameId,
    required UserModel child,
    required String childShortId,
    required int gameCoins,
    required String gameName,
  }) async {
    final batch = _db.batch();

    // Mark game as busy
    batch.update(_db.collection('club_games').doc(gameId), {'status': 'busy'});

    // Deduct coins from child
    final userRef = _db.collection('users').doc(child.id);
    batch.update(userRef, {'clubCoins': FieldValue.increment(-gameCoins)});

    // Add transaction record
    final txRef = _db
        .collection('users')
        .doc(child.id)
        .collection('coin_transactions')
        .doc();
    batch.set(txRef, {
      'amount': gameCoins,
      'type': 'subtracted',
      'reason': 'لعبة: $gameName',
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Track playing child
    final playingRef = _db
        .collection('club_games')
        .doc(gameId)
        .collection('playing_children')
        .doc(child.id);
    batch.set(playingRef, {
      'fullName': child.fullName,
      'username': child.username,
      'shortId': childShortId,
      'userClass': child.userClass,
      if (child.profileImageUrl != null) 'profileImageUrl': child.profileImageUrl,
      'startedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Resets all games back to active status.
  Future<void> resetAllGames() async {
    final snapshot = await _db.collection('club_games').get();
    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'status': 'active'});
    }
    await batch.commit();
  }

  /// Ends all active games by setting status to "ended".
  Future<void> endAllGames() async {
    final snapshot = await _db.collection('club_games').get();

    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      final currentStatus = (doc.data() as Map<String, dynamic>)['status'];
      // Only end active/busy games — do not touch already-ended ones unnecessarily.
      if (currentStatus != 'ended') {
        batch.update(doc.reference, {'status': 'ended'});
      }
    }
    await batch.commit();

    // Also clear playing children sub-collections.
    for (final gameDoc in snapshot.docs) {
      final playingSnap =
          await gameDoc.reference.collection('playing_children').get();
      if (playingSnap.docs.isEmpty) continue;
      final playingBatch = _db.batch();
      for (final childDoc in playingSnap.docs) {
        playingBatch.delete(childDoc.reference);
      }
      await playingBatch.commit();
    }
  }

  // ── Coin Transactions ────────────────────────────────────────────────────

  Stream<List<CoinTransaction>> coinTransactionsStream(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('coin_transactions')
        .orderBy('timestamp', descending: true)
        .limit(50) // cap to avoid unbounded growth in the event loop
        .snapshots()
        .map((s) => s.docs.map(CoinTransaction.fromFirestore).toList());
  }

  // ── Live child coins (for real-time BUG 3 fix) ───────────────────────────

  /// Live coin balance stream.
  /// Firestore persistence ensures this emits even when offline
  /// (from the local cache), then reconciles when reconnected.
  Stream<int> childCoinsStream(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .snapshots(includeMetadataChanges: false)
        .map((doc) =>
            ((doc.data() as Map<String, dynamic>?)?['clubCoins'] as num?)
                ?.toInt() ??
            0);
  }

  // ── Attendance Services ──────────────────────────────────────────────────

  Stream<List<AttendanceService>> attendanceServicesStream() {
    return _db
        .collection('club_attendance_services')
        .snapshots()
        .map((s) => s.docs.map(AttendanceService.fromFirestore).toList());
  }

  Future<void> addAttendanceService(AttendanceService service) =>
      _db.collection('club_attendance_services').add(service.toMap());

  Future<void> updateAttendanceService(AttendanceService service) => _db
      .collection('club_attendance_services')
      .doc(service.id)
      .update(service.toMap());

  Future<void> deleteAttendanceService(String id) =>
      _db.collection('club_attendance_services').doc(id).delete();

  /// Finds a child by shortId, awards attendance coins.
  Future<String?> recordAttendance({
    required String childShortId,
    required int coinsValue,
    required String serviceName,
  }) async {
    final query = await _db
        .collection('users')
        .where('shortId', isEqualTo: childShortId)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    final childDoc = query.docs.first;
    final batch = _db.batch();

    batch.update(
        childDoc.reference, {'clubCoins': FieldValue.increment(coinsValue)});

    final txRef = childDoc.reference.collection('coin_transactions').doc();
    batch.set(txRef, {
      'amount': coinsValue,
      'type': 'added',
      'reason': 'حضور: $serviceName',
      'timestamp': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    return childDoc.id;
  }

  // ── Child lookup ─────────────────────────────────────────────────────────

  /// Looks up a child by shortId.
  /// Strategy: try local Firestore cache first (works offline), then server.
  Future<UserModel?> findChildByShortId(String shortId) async {
    // 1. Cache lookup — instant and works offline.
    try {
      final cacheSnap = await _db
          .collection('users')
          .where('shortId', isEqualTo: shortId)
          .limit(1)
          .get(const GetOptions(source: Source.cache));
      if (cacheSnap.docs.isNotEmpty) {
        return UserModel.fromDocumentSnapshot(cacheSnap.docs.first);
      }
    } catch (_) {
      // Cache miss or persistence not ready — fall through to server.
    }

    // 2. Server fallback (requires connectivity).
    try {
      final serverSnap = await _db
          .collection('users')
          .where('shortId', isEqualTo: shortId)
          .limit(1)
          .get(const GetOptions(source: Source.server));
      if (serverSnap.docs.isEmpty) return null;
      return UserModel.fromDocumentSnapshot(serverSnap.docs.first);
    } catch (_) {
      return null;
    }
  }

  Future<List<dynamic>> findUsersByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    // Cache-first: try local cache for each doc, fall back to server.
    final futures = ids.map((id) async {
      try {
        final cached = await _db
            .collection('users')
            .doc(id)
            .get(const GetOptions(source: Source.cache));
        if (cached.exists) return cached;
      } catch (_) { /* cache miss — fall through */ }
      return _db.collection('users').doc(id).get();
    });
    final snaps = await Future.wait(futures);
    return snaps
        .where((s) => s.exists)
        .map((s) => UserModel.fromDocumentSnapshot(s))
        .toList();
  }

  // ── Legacy booking queue (stored in game doc array) ──────────────────────

  Future<bool> bookGame({
    required String gameId,
    required String childUserId,
  }) async {
    final ref = _db.collection('club_games').doc(gameId);
    final snap = await ref.get();
    final data = snap.data();
    if (data == null) return false;

    final queue = List<String>.from(data['bookingQueue'] ?? []);
    if (queue.contains(childUserId)) return false;

    queue.add(childUserId);
    await ref.update({'bookingQueue': queue});
    return true;
  }

  Future<void> cancelBooking({
    required String gameId,
    required String childUserId,
  }) async {
    final ref = _db.collection('club_games').doc(gameId);
    await ref.update({
      'bookingQueue': FieldValue.arrayRemove([childUserId]),
    });
  }

  // ── Day-scoped booking queue (new architecture) ───────────────────────────

  Stream<List<BookingQueueEntry>> bookingQueueStream(
      String date, String gameId) {
    return _bookingQueueRef(date, gameId)
        .orderBy('bookedAt', descending: false)
        .snapshots()
        .map((s) => s.docs.map(BookingQueueEntry.fromFirestore).toList());
  }

  Stream<List<PlayedQueueEntry>> playedQueueStream(
      String date, String gameId) {
    return _playedQueueRef(date, gameId)
        .orderBy('playedAt', descending: false)
        .snapshots()
        .map((s) => s.docs.map(PlayedQueueEntry.fromFirestore).toList());
  }

  /// Returns true if the child is already in today's booking queue for this game.
  Future<bool> isAlreadyInBookingQueue({
    required String date,
    required String gameId,
    required String childId,
  }) async {
    // Try cache first so duplicate-check works offline.
    try {
      final cacheSnap = await _bookingQueueRef(date, gameId)
          .where('childId', isEqualTo: childId)
          .limit(1)
          .get(const GetOptions(source: Source.cache));
      if (cacheSnap.docs.isNotEmpty) return true;
    } catch (_) {
      // Cache miss — fall through to server check.
    }
    final snap = await _bookingQueueRef(date, gameId)
        .where('childId', isEqualTo: childId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  /// Validates coins, deducts them, and adds child to booking_queue.
  /// Returns null on success, or an Arabic error string on failure.
  Future<String?> addToBookingQueue({
    required String date,
    required String gameId,
    required String gameName,
    required String childShortId,
    required int coinCost,
  }) async {
    // 1. Look up child
    final child = await findChildByShortId(childShortId);
    if (child == null) return 'لم يتم العثور على الطفل بالرمز: $childShortId';

    // 2. Validate coins (BUG 1)
    final currentCoins = child.clubCoins;
    if (currentCoins < coinCost) {
      return 'رصيد العملات غير كافٍ للحجز (المتوفر: $currentCoins، المطلوب: $coinCost)';
    }

    // 3. Check duplicate (same game, same day)
    final alreadyBooked = await isAlreadyInBookingQueue(
      date: date,
      gameId: gameId,
      childId: child.id,
    );
    if (alreadyBooked) return 'هذا الطفل محجوز بالفعل في هذه اللعبة اليوم';

    // 4. Batch: deduct coins + add to queue
    final batch = _db.batch();

    final userRef = _db.collection('users').doc(child.id);
    batch.update(userRef, {'clubCoins': FieldValue.increment(-coinCost)});

    final txRef = userRef.collection('coin_transactions').doc();
    batch.set(txRef, {
      'amount': coinCost,
      'type': 'subtracted',
      'reason': 'حجز لعبة: $gameName',
      'timestamp': FieldValue.serverTimestamp(),
    });

    final queueDoc = _bookingQueueRef(date, gameId).doc();
    final entry = BookingQueueEntry(
      id: queueDoc.id,
      childId: child.id,
      childName: child.fullName.isNotEmpty ? child.fullName : child.username,
      childShortId: childShortId,
      bookedAt: DateTime.now(),
    );
    batch.set(queueDoc, entry.toMap());

    await batch.commit();
    return null; // success
  }

  /// Moves a booking entry from booking_queue → played_queue.
  Future<void> markAsPlayed({
    required String date,
    required String gameId,
    required BookingQueueEntry entry,
  }) async {
    final batch = _db.batch();

    // Remove from booking queue
    batch.delete(_bookingQueueRef(date, gameId).doc(entry.id));

    // Add to played queue
    final playedDoc = _playedQueueRef(date, gameId).doc();
    final played = PlayedQueueEntry(
      id: playedDoc.id,
      childId: entry.childId,
      childName: entry.childName,
      playedAt: DateTime.now(),
    );
    batch.set(playedDoc, played.toMap());

    await batch.commit();
  }

  /// Removes a child from the booking queue (without playing).
  Future<void> removeFromBookingQueue({
    required String date,
    required String gameId,
    required String docId,
  }) async {
    await _bookingQueueRef(date, gameId).doc(docId).delete();
  }

  // ── Playing children (legacy) ────────────────────────────────────────────

  Stream<List<PlayingChild>> playingChildrenStream(String gameId) {
    return _db
        .collection('club_games')
        .doc(gameId)
        .collection('playing_children')
        .orderBy('startedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(PlayingChild.fromFirestore).toList());
  }

  Future<void> removePlayingChild({
    required String gameId,
    required String childUserId,
  }) async {
    await _db
        .collection('club_games')
        .doc(gameId)
        .collection('playing_children')
        .doc(childUserId)
        .delete();
  }

  Future<void> clearPlayingChildren(String gameId) async {
    final snap = await _db
        .collection('club_games')
        .doc(gameId)
        .collection('playing_children')
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ── Matches & Teams ──────────────────────────────────────────────────────

  Stream<List<GameMatch>> matchesStream(String gameId) {
    return _db
        .collection('club_games')
        .doc(gameId)
        .collection('matches')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((s) => s.docs.map(GameMatch.fromFirestore).toList());
  }

  Future<void> createMatch({
    required String gameId,
    required GameMatch match,
  }) async {
    final data = match.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    await _db
        .collection('club_games')
        .doc(gameId)
        .collection('matches')
        .add(data);
  }

  Future<void> updateMatch({
    required String gameId,
    required GameMatch match,
  }) async {
    await _db
        .collection('club_games')
        .doc(gameId)
        .collection('matches')
        .doc(match.id)
        .update(match.toMap());
  }

  Future<void> deleteMatch({
    required String gameId,
    required String matchId,
  }) async {
    await _db
        .collection('club_games')
        .doc(gameId)
        .collection('matches')
        .doc(matchId)
        .delete();
  }

  // ── Club subscription info ──────────────────────────────────────────────

  Stream<ClubSubscriptionInfo?> clubSubscriptionInfoStream() {
    final ref = _db.collection('club_subscription_info').doc(ClubSubscriptionInfo.docId);
    return ref.snapshots().map((doc) {
      if (!doc.exists) return null;
      return ClubSubscriptionInfo.fromFirestore(doc);
    });
  }

  Future<void> upsertClubSubscriptionInfo(ClubSubscriptionInfo info) {
    return _db
        .collection('club_subscription_info')
        .doc(ClubSubscriptionInfo.docId)
        .set(info.toMap(), SetOptions(merge: true));
  }

  Stream<ClubSubscriptionRequest?> subscriptionRequestForChild(String childId) {
    final ref = _db.collection('club_subscription_requests').doc(childId);
    return ref.snapshots().map((doc) {
      if (!doc.exists) return null;
      return ClubSubscriptionRequest.fromFirestore(doc);
    });
  }

  Stream<List<ClubSubscriptionRequest>> subscriptionRequestsStream({
    SubscriptionRequestStatus? status,
  }) {
    Query query = _db.collection('club_subscription_requests');
    if (status != null) {
      query = query.where('status', isEqualTo: status.code);
    }
    return query
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(ClubSubscriptionRequest.fromFirestore).toList());
  }

  Future<bool> createSubscriptionRequest({required UserModel child}) async {
    final ref = _db.collection('club_subscription_requests').doc(child.id);
    final existing = await ref.get();
    if (existing.exists) return false;

    final request = ClubSubscriptionRequest(
      id: child.id,
      childId: child.id,
      childName: child.username,
      childFullName: child.fullName,
      childClass: child.userClass,
      childShortId: child.shortId,
      status: SubscriptionRequestStatus.pending,
      requestedAt: DateTime.now(),
    );

    final data = request.toMap();
    data['requestedAt'] = FieldValue.serverTimestamp();
    await ref.set(data);
    return true;
  }

  Future<void> approveSubscriptionRequest({
    required ClubSubscriptionRequest request,
    required String approvedBy,
  }) async {
    final ref = _db.collection('club_subscription_requests').doc(request.childId);
    await ref.update({
      'status': SubscriptionRequestStatus.approved.code,
      'approvedAt': FieldValue.serverTimestamp(),
      'approvedBy': approvedBy,
    });
  }
}
