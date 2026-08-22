class EloHistoryLog {
  final String id;
  final String userId;
  final String? categoryId;
  final String? matchId;
  final String? reason;
  final int previousElo;
  final int newElo;
  final int changedPoints;
  final String createdAt;
  final EloHistoryMatch? match;

  const EloHistoryLog({
    required this.id,
    required this.userId,
    this.categoryId,
    this.matchId,
    this.reason,
    required this.previousElo,
    required this.newElo,
    required this.changedPoints,
    required this.createdAt,
    this.match,
  });

  int get eloDiff => newElo - previousElo;
  bool get isGain => eloDiff > 0;

  factory EloHistoryLog.fromJson(Map<String, dynamic> json) {
    final matchJson = json['match'] is Map
        ? Map<String, dynamic>.from(json['match'] as Map)
        : null;

    int asInt(dynamic value, [int fallback = 0]) {
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? fallback;
      return fallback;
    }

    return EloHistoryLog(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      categoryId: json['categoryId']?.toString(),
      matchId: json['matchId']?.toString(),
      reason: json['reason']?.toString(),
      previousElo: asInt(json['previousElo'] ?? json['previous_elo']),
      newElo: asInt(json['newElo'] ?? json['new_elo']),
      changedPoints: asInt(json['changedPoints'] ?? json['changed_points']),
      createdAt:
          json['createdAt']?.toString() ?? json['created_at']?.toString() ?? '',
      match: matchJson == null ? null : EloHistoryMatch.fromJson(matchJson),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    if (categoryId != null) 'categoryId': categoryId,
    if (matchId != null) 'matchId': matchId,
    if (reason != null) 'reason': reason,
    'previousElo': previousElo,
    'newElo': newElo,
    'changedPoints': changedPoints,
    'createdAt': createdAt,
    if (match != null) 'match': match!.toJson(),
  };
}

class EloHistoryMatch {
  final String? id;
  final String? tournamentId;
  final String? tournamentName;
  final String? tournamentType;
  final String? status;
  final String? completedAt;
  final String? result;
  final String? opponentId;
  final String? opponentName;
  final int? p1SetsWon;
  final int? p2SetsWon;
  final Map<String, dynamic>? scoreDetails;

  const EloHistoryMatch({
    this.id,
    this.tournamentId,
    this.tournamentName,
    this.tournamentType,
    this.status,
    this.completedAt,
    this.result,
    this.opponentId,
    this.opponentName,
    this.p1SetsWon,
    this.p2SetsWon,
    this.scoreDetails,
  });

  factory EloHistoryMatch.fromJson(Map<String, dynamic> json) {
    int? asNullableInt(dynamic value) {
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    final opponent = json['opponent'] is Map
        ? Map<String, dynamic>.from(json['opponent'] as Map)
        : null;
    final score = json['scoreDetails'] is Map
        ? Map<String, dynamic>.from(json['scoreDetails'] as Map)
        : null;
    final result = json['result']?.toString().toUpperCase();

    return EloHistoryMatch(
      id: json['id']?.toString(),
      tournamentId: json['tournamentId']?.toString(),
      tournamentName: json['tournamentName']?.toString(),
      tournamentType: json['tournamentType']?.toString(),
      status: json['status']?.toString(),
      completedAt: json['completedAt']?.toString(),
      result: result,
      opponentId: opponent?['id']?.toString(),
      opponentName:
          opponent?['name']?.toString() ?? opponent?['fullName']?.toString(),
      p1SetsWon: asNullableInt(json['p1SetsWon'] ?? json['p1_sets_won']),
      p2SetsWon: asNullableInt(json['p2SetsWon'] ?? json['p2_sets_won']),
      scoreDetails: score,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (tournamentId != null) 'tournamentId': tournamentId,
    if (tournamentName != null) 'tournamentName': tournamentName,
    if (tournamentType != null) 'tournamentType': tournamentType,
    if (status != null) 'status': status,
    if (completedAt != null) 'completedAt': completedAt,
    if (result != null) 'result': result,
    if (opponentId != null || opponentName != null)
      'opponent': {
        if (opponentId != null) 'id': opponentId,
        if (opponentName != null) 'name': opponentName,
      },
    if (p1SetsWon != null) 'p1SetsWon': p1SetsWon,
    if (p2SetsWon != null) 'p2SetsWon': p2SetsWon,
    if (scoreDetails != null) 'scoreDetails': scoreDetails,
  };
}
