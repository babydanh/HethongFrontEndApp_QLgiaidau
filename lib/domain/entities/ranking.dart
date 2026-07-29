class PlayerRanking {
  final String id;
  final String userId;
  final String fullName;
  final String? avatarUrl;
  final String? partnerName;
  final String? partnerAvatarUrl;
  final int eloPoints;
  final String tierName;
  final int rank;
  final int matchesPlayed;
  final int matchesWon;
  final String? categoryId;
  final String? categoryName;
  final String? matchType;
  final String? genderRestriction;
  final int? peakElo;
  final bool? shieldActive;
  final int winStreak;
  final String? updatedAt;

  const PlayerRanking({
    required this.id,
    required this.userId,
    required this.fullName,
    this.avatarUrl,
    this.partnerName,
    this.partnerAvatarUrl,
    this.eloPoints = 0,
    this.tierName = '',
    this.rank = 0,
    this.matchesPlayed = 0,
    this.matchesWon = 0,
    this.categoryId,
    this.categoryName,
    this.matchType,
    this.genderRestriction,
    this.peakElo,
    this.shieldActive,
    this.winStreak = 0,
    this.updatedAt,
  });

  factory PlayerRanking.fromJson(Map<String, dynamic> json) {
    // Backend PUBLIC scope trả về:
    //   { id, userId, categoryId, eloPoints, matchesPlayed, matchesWon,
    //     winStreak, updatedAt, tier: { id, name }, user: { id, fullName, avatarUrl } }
    final user = json['user'] as Map<String, dynamic>?;
    final user1 = json['user1'] as Map<String, dynamic>?;
    final user2 = json['user2'] as Map<String, dynamic>?;
    final tier = json['tier'] as Map<String, dynamic>?;
    final category = json['category'] as Map<String, dynamic>?;
    return PlayerRanking(
      id: json['id'] as String? ?? '',
      userId: user?['id'] as String? ?? user1?['id'] as String? ?? json['userId'] as String? ?? '',
      fullName:
          user1 != null && user2 != null
          ? '${user1['fullName'] ?? 'VĐV'} / ${user2['fullName'] ?? 'VĐV'}'
          : user?['fullName'] as String? ??
          json['fullName'] as String? ??
          json['playerName'] as String? ??
          '',
      avatarUrl: user1?['avatarUrl'] as String? ?? user?['avatarUrl'] as String? ?? json['avatarUrl'] as String?,
      partnerName: user2?['fullName'] as String?,
      partnerAvatarUrl: user2?['avatarUrl'] as String?,
      eloPoints: ((json['eloPoints'] ?? json['elo_points'] ?? 0) as num)
          .toInt(),
      tierName: tier?['name'] as String? ?? json['tierName'] as String? ?? '',
      rank: ((json['rank'] ?? 0) as num).toInt(),
      matchesPlayed:
          ((json['matchesPlayed'] ?? json['totalMatches'] ?? 0) as num).toInt(),
      matchesWon: ((json['matchesWon'] ?? json['wins'] ?? 0) as num).toInt(),
      winStreak: ((json['winStreak'] ?? json['win_streak'] ?? 0) as num).toInt(),
      categoryId: json['categoryId'] as String? ?? category?['id'] as String?,
      categoryName:
          json['categoryName'] as String? ?? category?['name'] as String?,
      matchType: json['matchType'] as String?,
      genderRestriction: json['genderRestriction'] as String?,
      peakElo: ((json['peakElo'] ?? json['peak_elo']) as num?)?.toInt(),
      shieldActive:
          json['shieldActive'] as bool? ?? json['shield_active'] as bool?,
      updatedAt: json['updatedAt'] as String? ?? json['updated_at'] as String?,
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
      if (categoryName != null) 'categoryName': categoryName,
      if (matchType != null) 'matchType': matchType,
      if (genderRestriction != null) 'genderRestriction': genderRestriction,
      if (peakElo != null) 'peakElo': peakElo,
      if (shieldActive != null) 'shieldActive': shieldActive,
      'winStreak': winStreak,
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }

  PlayerRanking copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? avatarUrl,
    String? partnerName,
    String? partnerAvatarUrl,
    int? eloPoints,
    String? tierName,
    int? rank,
    int? matchesPlayed,
    int? matchesWon,
    String? categoryId,
    String? categoryName,
    String? matchType,
    String? genderRestriction,
    int? peakElo,
    bool? shieldActive,
    int? winStreak,
    String? updatedAt,
  }) {
    return PlayerRanking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      partnerName: partnerName ?? this.partnerName,
      partnerAvatarUrl: partnerAvatarUrl ?? this.partnerAvatarUrl,
      eloPoints: eloPoints ?? this.eloPoints,
      tierName: tierName ?? this.tierName,
      rank: rank ?? this.rank,
      matchesPlayed: matchesPlayed ?? this.matchesPlayed,
      matchesWon: matchesWon ?? this.matchesWon,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      matchType: matchType ?? this.matchType,
      genderRestriction: genderRestriction ?? this.genderRestriction,
      peakElo: peakElo ?? this.peakElo,
      shieldActive: shieldActive ?? this.shieldActive,
      winStreak: winStreak ?? this.winStreak,
      updatedAt: updatedAt ?? this.updatedAt,
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

  const UserRankResponse({this.eloPoints, this.tierName, this.categoryId});

  factory UserRankResponse.fromJson(Map<String, dynamic> json) {
    return UserRankResponse(
      eloPoints: json['eloPoints'],
      tierName: json['tierName'],
      categoryId: json['categoryId'],
    );
  }
}
