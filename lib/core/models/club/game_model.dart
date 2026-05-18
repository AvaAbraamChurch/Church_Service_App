import 'package:cloud_firestore/cloud_firestore.dart';

import '../../utils/gender_enum.dart';

enum CardStatus { active, busy }

class GameModel {
  final String id;
  final String name;
  final String nameAr;
  final Gender gender;
  final int coins;
  final String icon;
  final CardStatus status;

  /// When true and the game is busy, children can join a queue
  /// instead of seeing a hard "مشغول" lock. e.g. PlayStation.
  final bool allowBooking;

  /// Ordered list of child userIds waiting to play next.
  final List<String> bookingQueue;

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
  });

  factory GameModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GameModel(
      id: doc.id,
      name: data['name'] ?? '',
      nameAr: data['nameAr'] ?? '',
      gender: genderFromJson(data['gender']),
      coins: (data['coins'] as num?)?.toInt() ?? 0,
      icon: data['icon'] ?? '🎮',
      status: (data['status'] == 'busy') ? CardStatus.busy : CardStatus.active,
      allowBooking: data['allowBooking'] ?? false,
      bookingQueue: List<String>.from(data['bookingQueue'] ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'nameAr': nameAr,
        'gender': gender.code,
        'coins': coins,
        'icon': icon,
        'status': status == CardStatus.busy ? 'busy' : 'active',
        'allowBooking': allowBooking,
        'bookingQueue': bookingQueue,
      };

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
      );
}
