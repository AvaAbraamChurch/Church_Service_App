import 'package:cloud_firestore/cloud_firestore.dart';

import '../../utils/gender_enum.dart';

enum CardStatus { active, busy, ended }

class GameModel {
  final String id;
  final String name;
  final String nameAr;
  final Gender gender;

  /// Coin cost to play — always fetched from Firestore, never hardcoded.
  final int coins;

  /// Convenience alias used by the booking-queue layer.
  int get coinCost => coins;

  final String icon;
  final CardStatus status;

  /// When true and the game is busy, children can join a queue
  /// instead of seeing a hard "مشغول" lock (e.g. PlayStation).
  final bool allowBooking;

  /// Ordered list of child userIds waiting to play next (legacy queue).
  final List<String> bookingQueue;

  /// Optional cover image URL stored in Firebase Storage.
  final String? imageUrl;

  const GameModel({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.gender,
    required this.coins,
    required this.icon,
    this.status = CardStatus.active,
    this.allowBooking = false,
    this.bookingQueue = const [],
    this.imageUrl,
  });

  bool get isEnded => status == CardStatus.ended;
  bool get isActive => status == CardStatus.active;

  factory GameModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    // Support both 'coins' (old) and 'coinCost' (new) field names.
    final coinValue = ((data['coinCost'] ?? data['coins']) as num?)?.toInt() ?? 0;
    CardStatus parsedStatus;
    switch (data['status']) {
      case 'ended':
        parsedStatus = CardStatus.ended;
        break;
      case 'busy':
        parsedStatus = CardStatus.busy;
        break;
      default:
        parsedStatus = CardStatus.active;
    }
    return GameModel(
      id: doc.id,
      name: data['name'] ?? '',
      nameAr: data['nameAr'] ?? '',
      gender: genderFromJson(data['gender']),
      coins: coinValue,
      icon: data['icon'] ?? '🎮',
      status: parsedStatus,
      allowBooking: data['allowBooking'] ?? false,
      bookingQueue: List<String>.from(data['bookingQueue'] ?? []),
      imageUrl: data['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    String statusStr;
    switch (status) {
      case CardStatus.ended:
        statusStr = 'ended';
        break;
      case CardStatus.busy:
        statusStr = 'busy';
        break;
      case CardStatus.active:
        statusStr = 'active';
        break;
    }
    return {
      'name': name,
      'nameAr': nameAr,
      'gender': gender.code,
      'coins': coins,
      'coinCost': coins,
      'icon': icon,
      'status': statusStr,
      'allowBooking': allowBooking,
      'bookingQueue': bookingQueue,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }

  GameModel copyWith({
    String? id,
    String? name,
    String? nameAr,
    Gender? gender,
    int? coins,
    String? icon,
    CardStatus? status,
    bool? allowBooking,
    List<String>? bookingQueue,
    String? imageUrl,
    bool clearImage = false,
  }) =>
      GameModel(
        id: id ?? this.id,
        name: name ?? this.name,
        nameAr: nameAr ?? this.nameAr,
        gender: gender ?? this.gender,
        coins: coins ?? this.coins,
        icon: icon ?? this.icon,
        status: status ?? this.status,
        allowBooking: allowBooking ?? this.allowBooking,
        bookingQueue: bookingQueue ?? this.bookingQueue,
        imageUrl: clearImage ? null : (imageUrl ?? this.imageUrl),
      );
}
