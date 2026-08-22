class PlayerRanking {
  final String id;
  final String userId;
  final String fullName;
  final String? avatarUrl;
  final String? partnerId;
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
  final String? currentStreakType;
  final int currentStreakCount;
  final String? updatedAt;

  const PlayerRanking({
    required this.id,
    required this.userId,
    required this.fullName,
    this.avatarUrl,
    this.partnerId,
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
    this.currentStreakType,
    this.currentStreakCount = 0,
    this.updatedAt,
  });

  factory PlayerRanking.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map
        ? Map<String, dynamic>.from(json['user'] as Map)
        : null;
    final user1 = json['user1'] is Map
        ? Map<String, dynamic>.from(json['user1'] as Map)
        : null;
    final user2 = json['user2'] is Map
        ? Map<String, dynamic>.from(json['user2'] as Map)
        : null;
    final tier = json['tier'] is Map
        ? Map<String, dynamic>.from(json['tier'] as Map)
        : null;
    final category = json['category'] is Map
        ? Map<String, dynamic>.from(json['category'] as Map)
        : null;

    int asInt(dynamic value, [int fallback = 0]) {
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? fallback;
      return fallback;
    }

    String? asString(dynamic value) => value?.toString();

    final parsedStreakType = asString(
      json['currentStreakType'] ?? json['current_streak_type'],
    )?.toUpperCase();

    return PlayerRanking(
      id: asString(json['id']) ?? '',
      userId:
          user?['id']?.toString() ??
          user1?['id']?.toString() ??
          asString(json['userId']) ??
          '',
      fullName: user1 != null && user2 != null
          ? '${user1['fullName'] ?? 'VĐV'} / ${user2['fullName'] ?? 'VĐV'}'
          : user?['fullName']?.toString() ??
                asString(json['fullName']) ??
                asString(json['playerName']) ??
                '',
      avatarUrl: asString(
        user1?['avatarUrl'] ?? user?['avatarUrl'] ?? json['avatarUrl'],
      ),
      partnerId: asString(
        json['partnerId'] ?? json['partner_id'] ?? user2?['id'],
      ),
      partnerName: asString(
        json['partnerName'] ?? json['partner_name'] ?? user2?['fullName'],
      ),
      partnerAvatarUrl: asString(
        json['partnerAvatarUrl'] ??
            json['partner_avatar_url'] ??
            user2?['avatarUrl'],
      ),
      eloPoints: asInt(json['eloPoints'] ?? json['elo_points']),
      tierName: asString(tier?['name'] ?? json['tierName']) ?? '',
      rank: asInt(json['rank']),
      matchesPlayed: asInt(json['matchesPlayed'] ?? json['totalMatches']),
      matchesWon: asInt(json['matchesWon'] ?? json['wins']),
      categoryId: asString(json['categoryId'] ?? category?['id']),
      categoryName: asString(json['categoryName'] ?? category?['name']),
      matchType: asString(
        json['matchType'] ?? json['match_type'],
      )?.toUpperCase(),
      genderRestriction: asString(
        json['genderRestriction'] ?? json['gender_restriction'],
      )?.toUpperCase(),
      peakElo: json['peakElo'] == null && json['peak_elo'] == null
          ? null
          : asInt(json['peakElo'] ?? json['peak_elo']),
      shieldActive:
          json['shieldActive'] as bool? ?? json['shield_active'] as bool?,
      winStreak: asInt(json['winStreak'] ?? json['win_streak']),
      currentStreakType: parsedStreakType,
      currentStreakCount: asInt(
        json['currentStreakCount'] ?? json['current_streak_count'],
      ),
      updatedAt: asString(json['updatedAt'] ?? json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'fullName': fullName,
      'avatarUrl': avatarUrl,
      if (partnerId != null) 'partnerId': partnerId,
      if (partnerName != null) 'partnerName': partnerName,
      if (partnerAvatarUrl != null) 'partnerAvatarUrl': partnerAvatarUrl,
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
      if (currentStreakType != null) 'currentStreakType': currentStreakType,
      'currentStreakCount': currentStreakCount,
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }

  PlayerRanking copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? avatarUrl,
    String? partnerId,
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
    String? currentStreakType,
    int? currentStreakCount,
    String? updatedAt,
  }) {
    return PlayerRanking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      partnerId: partnerId ?? this.partnerId,
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
      currentStreakType: currentStreakType ?? this.currentStreakType,
      currentStreakCount: currentStreakCount ?? this.currentStreakCount,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  int get matchesLost => (matchesPlayed - matchesWon).clamp(0, 1 << 30);

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
    final rawElo = json['eloPoints'];
    return UserRankResponse(
      eloPoints: rawElo is num ? rawElo.toInt() : int.tryParse('$rawElo'),
      tierName: json['tierName']?.toString(),
      categoryId: json['categoryId']?.toString(),
    );
  }
}
