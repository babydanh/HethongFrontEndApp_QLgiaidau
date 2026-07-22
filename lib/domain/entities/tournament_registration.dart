class TournamentDivisionOption {
  const TournamentDivisionOption({
    required this.id,
    required this.name,
    this.genderRestriction,
    this.matchType,
    this.categoryId,
    this.minElo,
    this.maxElo,
    this.entryFee,
    this.maxParticipants,
  });

  final String id;
  final String name;
  final String? genderRestriction; // 'MALE' | 'FEMALE' | 'MIXED'
  final String? matchType;         // 'SINGLES' | 'DOUBLES' | 'MIXED_DOUBLES'
  final String? categoryId;
  final double? minElo;
  final double? maxElo;
  final double? entryFee;
  final int? maxParticipants;

  factory TournamentDivisionOption.fromJson(Map<String, dynamic> json) {
    return TournamentDivisionOption(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      genderRestriction: json['genderRestriction']?.toString(),
      matchType: json['matchType']?.toString(),
      categoryId: json['categoryId']?.toString(),
      minElo: (json['minElo'] as num?)?.toDouble(),
      maxElo: (json['maxElo'] as num?)?.toDouble(),
      entryFee: (json['entryFee'] as num?)?.toDouble(),
      maxParticipants: json['maxParticipants'] as int?,
    );
  }
}

class TournamentRegistrationResult {
  const TournamentRegistrationResult({
    required this.participantId,
    required this.entryFee,
  });

  final String participantId;
  final double entryFee;

  factory TournamentRegistrationResult.fromJson(Map<String, dynamic> json) {
    return TournamentRegistrationResult(
      participantId: json['id']?.toString() ?? '',
      entryFee: (json['entryFee'] as num?)?.toDouble() ?? 0,
    );
  }
}
