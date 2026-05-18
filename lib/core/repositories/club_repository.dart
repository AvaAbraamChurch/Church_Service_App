import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/club/attendance_service_model.dart';
import '../models/club/coin_transaction_model.dart';
import '../models/club/game_model.dart';
import '../models/club/game_match_model.dart';
import '../models/club/playing_child_model.dart';
import '../models/user/user_model.dart';


class ClubRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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

  Future<void> endAllGames() async {
    final snapshot = await _db.collection('club_games').get();

    final statusBatch = _db.batch();
    for (final doc in snapshot.docs) {
      statusBatch.update(doc.reference, {'status': 'active'});
    }
    await statusBatch.commit();

    for (final gameDoc in snapshot.docs) {
      final playingSnap = await gameDoc.reference
          .collection('playing_children')
          .get();
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
        .snapshots()
        .map((s) => s.docs.map(CoinTransaction.fromFirestore).toList());
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

    if (query.docs.isEmpty) return null; // child not found

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

  // ── Child lookup by shortId ──────────────────────────────────────────────

  Future<UserModel?> findChildByShortId(String shortId) async {
    final q = await _db
        .collection('users')
        .where('shortId', isEqualTo: shortId)
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    return UserModel.fromDocumentSnapshot(q.docs.first);
  }

  Future<List<dynamic>> findUsersByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final futures = ids.map((id) => _db.collection('users').doc(id).get());
    final snaps = await Future.wait(futures);
    return snaps
        .where((s) => s.exists)
        .map((s) => UserModel.fromDocumentSnapshot(s))
        .toList();
  }

  // ── Booking queue ────────────────────────────────────────────────────────

  /// Adds [childUserId] to the game's booking queue.
  /// Returns false if the child is already in the queue.
  Future<bool> bookGame({
    required String gameId,
    required String childUserId,
  }) async {
    final ref = _db.collection('club_games').doc(gameId);
    final snap = await ref.get();
    final data = snap.data();
    if (data == null) return false;

    final queue = List<String>.from(data['bookingQueue'] ?? []);
    if (queue.contains(childUserId)) return false; // already booked

    queue.add(childUserId);
    await ref.update({'bookingQueue': queue});
    return true;
  }

  /// Removes [childUserId] from the game's booking queue.
  Future<void> cancelBooking({
    required String gameId,
    required String childUserId,
  }) async {
    final ref = _db.collection('club_games').doc(gameId);
    await ref.update({
      'bookingQueue': FieldValue.arrayRemove([childUserId]),
    });
  }

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
}
