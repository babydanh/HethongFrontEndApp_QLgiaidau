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
    final maxParticipants = json['maxParticipants'] ?? json['max_participants'];
    final rawEndDate =
        json['registrationEndDate'] ?? json['registration_end_date'];
    final rawCount = json['_count'] is Map
        ? (json['_count'] as Map)['participants']
        : (json['participantCount'] ?? json['participant_count']);
    return TournamentDivisionOption(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      genderRestriction:
          (json['genderRestriction'] ?? json['gender_restriction'])?.toString(),
      matchType: (json['matchType'] ?? json['match_type'])?.toString(),
      categoryId: (json['categoryId'] ?? json['category_id'])?.toString(),
      minElo: _parseDouble(minElo),
      maxElo: _parseDouble(maxElo),
      entryFee: _parseDouble(entryFee),
      maxParticipants: _parseInt(maxParticipants),
      bracketType: (json['bracketType'] ?? json['bracket_type'])?.toString(),
      registrationEndDate: rawEndDate is String
          ? DateTime.tryParse(rawEndDate)
          : null,
      participantCount: _parseInt(rawCount),
    );
  }
}

/// Parse a numeric value that may arrive as `num` or a numeric `String`.
/// Backend trả các trường tiền như `entryFee`/`minElo`/`maxElo` dưới dạng
/// chuỗi (`"0.00"`) nên cast thẳng `as num?` sẽ ném TypeError và khiến cả
/// danh sách division bị bỏ qua (app chỉ hiện 1 mục "Đôi").
double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

class TournamentRegistrationResult {
  const TournamentRegistrationResult({
    required this.participantId,
    required this.entryFee,
    required this.teamStatus,
    required this.isWaitlisted,
    required this.paymentEligible,
  });

  final String participantId;
  final double entryFee;
  final String teamStatus;
  final bool isWaitlisted;
  final bool paymentEligible;

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
      entryFee: _parseDouble(json['entryFee']) ?? 0,
      teamStatus: json['participant'] is Map
          ? (json['participant']['teamStatus']?.toString() ?? '')
          : '',
      paymentEligible: json['paymentEligible'] == true,
      isWaitlisted:
          json['isWaitlisted'] == true ||
          (json['participant'] is Map &&
              json['participant']['teamStatus']?.toString() == 'WAITLISTED'),
    );
  }
}

class FootballRosterMember {
  const FootballRosterMember({
    required this.id,
    required this.userId,
    required this.role,
    required this.confirmationStatus,
    this.fullName,
    this.avatarUrl,
  });
  final String id;
  final String userId;
  final String role;
  final String confirmationStatus;
  final String? fullName;
  final String? avatarUrl;

  factory FootballRosterMember.fromJson(Map<String, dynamic> json) =>
      FootballRosterMember(
        id: json['id']?.toString() ?? '',
        userId: json['userId']?.toString() ?? json['user_id']?.toString() ?? '',
        role: json['role']?.toString() ?? 'MAIN',
        confirmationStatus:
            json['confirmationStatus']?.toString() ??
            json['confirmation_status']?.toString() ??
            'PENDING',
        fullName: json['fullName']?.toString(),
        avatarUrl:
            json['avatarUrl']?.toString() ?? json['avatar_url']?.toString(),
      );
}

class FootballRosterStatus {
  const FootballRosterStatus({
    required this.entryId,
    required this.entryStatus,
    required this.roster,
    this.currentMember,
  });
  final String? entryId;
  final String? entryStatus;
  final List<FootballRosterMember> roster;
  final FootballRosterMember? currentMember;

  factory FootballRosterStatus.fromJson(Map<String, dynamic> json) {
    final entry = json['entry'] is Map
        ? Map<String, dynamic>.from(json['entry'] as Map)
        : null;
    final roster =
        (json['roster'] is List ? json['roster'] as List : const <dynamic>[])
            .whereType<Map>()
            .map(
              (item) => FootballRosterMember.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList(growable: false);
    final current = json['currentMember'] is Map
        ? FootballRosterMember.fromJson(
            Map<String, dynamic>.from(json['currentMember'] as Map),
          )
        : null;
    return FootballRosterStatus(
      entryId: entry?['id']?.toString(),
      entryStatus: entry?['status']?.toString(),
      roster: roster,
      currentMember: current,
    );
  }
}
