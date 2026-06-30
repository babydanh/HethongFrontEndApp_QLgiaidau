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
    return PlayerRanking(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      fullName: json['fullName'] ?? json['playerName'] ?? '',
      avatarUrl: json['avatarUrl'],
      eloPoints: json['eloPoints'] ?? 0,
      tierName: json['tierName'] ?? json['tier']?['name'] ?? '',
      rank: json['rank'] ?? 0,
      matchesPlayed: json['matchesPlayed'] ?? json['totalMatches'] ?? 0,
      matchesWon: json['matchesWon'] ?? json['wins'] ?? 0,
      categoryId: json['categoryId'] ?? json['category']?['id'],
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
