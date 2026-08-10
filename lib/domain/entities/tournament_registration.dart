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
    this.bracketType,
    this.registrationEndDate,
    this.participantCount,
  });

  final String id;
  final String name;
  final String? genderRestriction; // 'MALE' | 'FEMALE' | 'MIXED'
  final String? matchType; // 'SINGLES' | 'DOUBLES' | 'MIXED_DOUBLES'
  final String? categoryId;
  final double? minElo;
  final double? maxElo;
  final double? entryFee;
  final int? maxParticipants;
  final String? bracketType;
  final DateTime? registrationEndDate;
  final int? participantCount;

  factory TournamentDivisionOption.fromJson(Map<String, dynamic> json) {
    final minElo = json['minElo'] ?? json['min_elo'];
    final maxElo = json['maxElo'] ?? json['max_elo'];
    final entryFee = json['entryFee'] ?? json['entry_fee'];
    final maxParticipants =
        json['maxParticipants'] ?? json['max_participants'];
    final rawEndDate =
        json['registrationEndDate'] ?? json['registration_end_date'];
    final rawCount = json['_count'] is Map
        ? (json['_count'] as Map)['participants']
        : (json['participantCount'] ?? json['participant_count']);
    return TournamentDivisionOption(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      genderRestriction: (json['genderRestriction'] ??
              json['gender_restriction'])
          ?.toString(),
      matchType: (json['matchType'] ?? json['match_type'])?.toString(),
      categoryId: (json['categoryId'] ?? json['category_id'])?.toString(),
      minElo: (minElo as num?)?.toDouble(),
      maxElo: (maxElo as num?)?.toDouble(),
      entryFee: (entryFee as num?)?.toDouble(),
      maxParticipants: (maxParticipants as num?)?.toInt(),
      bracketType: (json['bracketType'] ?? json['bracket_type'])?.toString(),
      registrationEndDate: rawEndDate is String
          ? DateTime.tryParse(rawEndDate)
          : null,
      participantCount: (rawCount as num?)?.toInt(),
    );
  }
}

class TournamentRegistrationResult {
  const TournamentRegistrationResult({
    required this.participantId,
    required this.entryFee,
    required this.teamStatus,
    required this.isWaitlisted,
  });

  final String participantId;
  final double entryFee;
  final String teamStatus;
  final bool isWaitlisted;

  factory TournamentRegistrationResult.fromJson(Map<String, dynamic> json) {
    // Backend trả participantId trong participant.id, fallback top-level id
    String extractId(Map<String, dynamic> j) {
      final participant = j['participant'];
      if (participant is Map) {
        final pid = participant['id']?.toString();
        if (pid != null && pid.isNotEmpty) return pid;
      }
      final tid = j['id']?.toString();
      if (tid != null && tid.isNotEmpty) return tid;
      return '';
    }

    return TournamentRegistrationResult(
      participantId: extractId(json),
      entryFee: (json['entryFee'] as num?)?.toDouble() ?? 0,
      teamStatus: json['participant'] is Map
          ? (json['participant']['teamStatus']?.toString() ?? '')
          : '',
      isWaitlisted:
          json['isWaitlisted'] == true ||
          (json['participant'] is Map &&
              json['participant']['teamStatus']?.toString() == 'WAITLISTED'),
    );
  }
}
