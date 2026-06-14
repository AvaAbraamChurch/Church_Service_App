import 'package:cloud_firestore/cloud_firestore.dart';

/// Warms the Firestore local cache with all children documents on app launch,
/// so that QR-scan / short-ID lookups work offline.
class ClubCacheService {
  static final ClubCacheService _instance = ClubCacheService._internal();
  factory ClubCacheService() => _instance;
  ClubCacheService._internal();

  bool _preloaded = false;

  /// Call once from main() after Firebase is initialised.
  /// Fetches all users with userType == 'CH' and stores them in the
  /// Firestore local cache.  Errors are swallowed – preload is best-effort.
  Future<void> preloadChildren() async {
    if (_preloaded) return;
    try {
      // Fetch from server-and-cache so the local SQLite store is populated.
      await FirebaseFirestore.instance
          .collection('users')
          .where('userType', isEqualTo: 'CH')
          .get(const GetOptions(source: Source.serverAndCache));
      _preloaded = true;
    } catch (_) {
      // Network may be unavailable; the cache will warm progressively.
    }
  }

  /// Re-triggers preload (e.g. on connectivity restored).
  void invalidate() => _preloaded = false;
}
