import 'package:cloud_firestore/cloud_firestore.dart';

class PlayingChild {
  final String id;
  final String fullName;
  final String username;
  final String shortId;
  final String? userClass;
  final String? profileImageUrl;
  final DateTime? startedAt;

  const PlayingChild({
    required this.id,
    required this.fullName,
    required this.username,
    required this.shortId,
    this.userClass,
    this.profileImageUrl,
    this.startedAt,
  });

  String get displayName {
    if (fullName.trim().isNotEmpty) return fullName;
    if (username.trim().isNotEmpty) return username;
    return shortId;
  }

  factory PlayingChild.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PlayingChild(
      id: doc.id,
      fullName: (data['fullName'] ?? data['name'] ?? '').toString(),
      username: (data['username'] ?? '').toString(),
      shortId: (data['shortId'] ?? '').toString(),
      userClass: data['userClass']?.toString(),
      profileImageUrl: data['profileImageUrl']?.toString(),
      startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'fullName': fullName,
        'username': username,
        'shortId': shortId,
        if (userClass != null) 'userClass': userClass,
        if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
        'startedAt': startedAt,
      };
}
