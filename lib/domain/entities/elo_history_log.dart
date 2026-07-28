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
  bool get isGain => eloDiff >= 0;

  factory EloHistoryLog.fromJson(Map<String, dynamic> json) {
    final matchJson = json['match'] as Map<String, dynamic>?;
    return EloHistoryLog(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      categoryId: json['categoryId'] as String?,
      matchId: json['matchId'] as String?,
      reason: json['reason'] as String?,
      previousElo: ((json['previousElo'] ?? json['previous_elo'] ?? 0) as num).toInt(),
      newElo: ((json['newElo'] ?? json['new_elo'] ?? 0) as num).toInt(),
      changedPoints: ((json['changedPoints'] ?? json['changed_points'] ?? 0) as num).toInt(),
      createdAt: json['createdAt'] as String? ?? json['created_at'] as String? ?? '',
      match: matchJson != null ? EloHistoryMatch.fromJson(matchJson) : null,
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

  const EloHistoryMatch({
    this.id,
    this.tournamentId,
    this.tournamentName,
    this.tournamentType,
  });

  factory EloHistoryMatch.fromJson(Map<String, dynamic> json) {
    return EloHistoryMatch(
      id: json['id'] as String?,
      tournamentId: json['tournamentId'] as String?,
      tournamentName: json['tournamentName'] as String?,
      tournamentType: json['tournamentType'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (tournamentId != null) 'tournamentId': tournamentId,
    if (tournamentName != null) 'tournamentName': tournamentName,
    if (tournamentType != null) 'tournamentType': tournamentType,
  };
}
