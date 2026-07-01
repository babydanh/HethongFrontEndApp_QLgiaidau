class PlayerRanking {
  final String id;
  final String userId;
  final String fullName;
  final String? avatarUrl;
  final int eloPoints;
  final String tierName;
  final int rank;
  final int matchesPlayed;
  final int matchesWon;
  final String? categoryId;

  const PlayerRanking({
    required this.id,
    required this.userId,
    required this.fullName,
    this.avatarUrl,
    this.eloPoints = 0,
    this.tierName = '',
    this.rank = 0,
    this.matchesPlayed = 0,
    this.matchesWon = 0,
    this.categoryId,
  });

  factory PlayerRanking.fromJson(Map<String, dynamic> json) {
    // Backend PUBLIC scope trả về:
    //   { id, userId, categoryId, eloPoints, matchesPlayed, matchesWon,
    //     winStreak, updatedAt, tier: { id, name }, user: { id, fullName, avatarUrl } }
    final user = json['user'] as Map<String, dynamic>?;
    final tier = json['tier'] as Map<String, dynamic>?;
    return PlayerRanking(
      id: json['id'] as String? ?? '',
      userId: user?['id'] as String? ?? json['userId'] as String? ?? '',
      fullName:
          user?['fullName'] as String? ?? json['fullName'] as String? ?? json['playerName'] as String? ?? '',
      avatarUrl: user?['avatarUrl'] as String? ?? json['avatarUrl'] as String?,
      eloPoints: ((json['eloPoints'] ?? json['elo_points'] ?? 0) as num).toInt(),
      tierName: tier?['name'] as String? ?? json['tierName'] as String? ?? '',
      rank: ((json['rank'] ?? 0) as num).toInt(),
      matchesPlayed: ((json['matchesPlayed'] ?? json['totalMatches'] ?? 0) as num).toInt(),
      matchesWon: ((json['matchesWon'] ?? json['wins'] ?? 0) as num).toInt(),
      categoryId: json['categoryId'] as String? ?? json['category']?['id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'fullName': fullName,
      'avatarUrl': avatarUrl,
      'eloPoints': eloPoints,
      'tierName': tierName,
      'rank': rank,
      'matchesPlayed': matchesPlayed,
      'matchesWon': matchesWon,
      if (categoryId != null) 'categoryId': categoryId,
    };
  }

  PlayerRanking copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? avatarUrl,
    int? eloPoints,
    String? tierName,
    int? rank,
    int? matchesPlayed,
    int? matchesWon,
  }) {
    return PlayerRanking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      eloPoints: eloPoints ?? this.eloPoints,
      tierName: tierName ?? this.tierName,
      rank: rank ?? this.rank,
      matchesPlayed: matchesPlayed ?? this.matchesPlayed,
      matchesWon: matchesWon ?? this.matchesWon,
    );
  }

  int get matchesLost => matchesPlayed - matchesWon;
  double get winRate =>
      matchesPlayed > 0 ? (matchesWon / matchesPlayed) * 100 : 0;

  @override
  String toString() =>
      'PlayerRanking(id: $id, name: $fullName, rank: $rank, elo: $eloPoints)';
}

class UserRankResponse {
  final int? eloPoints;
  final String? tierName;
  final String? categoryId;

  const UserRankResponse({
    this.eloPoints,
    this.tierName,
    this.categoryId,
  });

  factory UserRankResponse.fromJson(Map<String, dynamic> json) {
    return UserRankResponse(
      eloPoints: json['eloPoints'],
      tierName: json['tierName'],
      categoryId: json['categoryId'],
    );
  }
}
