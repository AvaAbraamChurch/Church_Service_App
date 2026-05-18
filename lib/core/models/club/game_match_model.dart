import 'package:cloud_firestore/cloud_firestore.dart';

class MatchPlayer {
  final String id;
  final String fullName;
  final String shortId;

  const MatchPlayer({
    required this.id,
    required this.fullName,
    required this.shortId,
  });

  factory MatchPlayer.fromMap(Map<String, dynamic> map) {
    return MatchPlayer(
      id: (map['id'] ?? '').toString(),
      fullName: (map['fullName'] ?? '').toString(),
      shortId: (map['shortId'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'fullName': fullName,
        'shortId': shortId,
      };
}

enum MatchStatus { pending, finished }

class GameMatch {
  final String id;
  final String gameId;
  final int sizePerTeam;
  final int durationSeconds;
  final int elapsedSeconds;
  final bool isRunning;
  final DateTime? startedAt;
  final List<MatchPlayer> teamA;
  final List<MatchPlayer> teamB;
  final MatchStatus status;
  final int? scoreA;
  final int? scoreB;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const GameMatch({
    required this.id,
    required this.gameId,
    required this.sizePerTeam,
    required this.durationSeconds,
    required this.elapsedSeconds,
    required this.isRunning,
    required this.startedAt,
    required this.teamA,
    required this.teamB,
    this.status = MatchStatus.pending,
    this.scoreA,
    this.scoreB,
    this.createdAt,
    this.updatedAt,
  });

  factory GameMatch.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final created = data['createdAt'];
    final updated = data['updatedAt'];
    final started = data['startedAt'];
    return GameMatch(
      id: doc.id,
      gameId: (data['gameId'] ?? '').toString(),
      sizePerTeam: (data['sizePerTeam'] as num?)?.toInt() ?? 1,
      durationSeconds: (data['durationSeconds'] as num?)?.toInt() ?? 0,
      elapsedSeconds: (data['elapsedSeconds'] as num?)?.toInt() ?? 0,
      isRunning: (data['isRunning'] as bool?) ?? false,
      startedAt: started is Timestamp ? started.toDate() : null,
      teamA: (data['teamA'] as List<dynamic>? ?? [])
          .map((p) => MatchPlayer.fromMap(Map<String, dynamic>.from(p)))
          .toList(),
      teamB: (data['teamB'] as List<dynamic>? ?? [])
          .map((p) => MatchPlayer.fromMap(Map<String, dynamic>.from(p)))
          .toList(),
      status: (data['status'] == 'finished')
          ? MatchStatus.finished
          : MatchStatus.pending,
      scoreA: (data['scoreA'] as num?)?.toInt(),
      scoreB: (data['scoreB'] as num?)?.toInt(),
      createdAt: created is Timestamp ? created.toDate() : null,
      updatedAt: updated is Timestamp ? updated.toDate() : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'gameId': gameId,
        'sizePerTeam': sizePerTeam,
        'durationSeconds': durationSeconds,
        'elapsedSeconds': elapsedSeconds,
        'isRunning': isRunning,
        if (startedAt != null) 'startedAt': Timestamp.fromDate(startedAt!),
        'teamA': teamA.map((p) => p.toMap()).toList(),
        'teamB': teamB.map((p) => p.toMap()).toList(),
        'status': status == MatchStatus.finished ? 'finished' : 'pending',
        if (scoreA != null) 'scoreA': scoreA,
        if (scoreB != null) 'scoreB': scoreB,
        if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
        if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      };

  GameMatch copyWith({
    String? id,
    String? gameId,
    int? sizePerTeam,
    int? durationSeconds,
    int? elapsedSeconds,
    bool? isRunning,
    DateTime? startedAt,
    List<MatchPlayer>? teamA,
    List<MatchPlayer>? teamB,
    MatchStatus? status,
    int? scoreA,
    int? scoreB,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GameMatch(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      sizePerTeam: sizePerTeam ?? this.sizePerTeam,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      isRunning: isRunning ?? this.isRunning,
      startedAt: startedAt ?? this.startedAt,
      teamA: teamA ?? this.teamA,
      teamB: teamB ?? this.teamB,
      status: status ?? this.status,
      scoreA: scoreA ?? this.scoreA,
      scoreB: scoreB ?? this.scoreB,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
