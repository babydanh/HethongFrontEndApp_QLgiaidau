class ClubMatchSessionModel {
  final String id;
  final String communityId;
  final String resolvedName;
  final String? description;
  final String status;
  final String registrationMode;
  final bool isRanked;
  final int maxParticipants;
  final bool isRecurring;
  final String? recurringFrequency;
  final int? recurringDayOfWeek;
  final List<int> recurringDaysOfWeek;
  final String? recurringTimeOfDay;
  final int? recurringAdvanceDays;
  final DateTime? startAt;
  final DateTime? endAt;
  final int? participantCount;
  final int? matchCount;
  final int version;
  final bool canManage;
  final bool canJoin;
  final bool canWithdraw;
  final bool canCreateMatch;
  final String? viewerUserId;
  final bool viewerIsActive;
  final List<String> preferredPartnerUserIds;
  final List<String> preferredOpponentUserIds;
  final List<String> avoidUserIds;
  final int preferenceVersion;

  const ClubMatchSessionModel({
    required this.id,
    required this.communityId,
    required this.resolvedName,
    required this.status,
    required this.registrationMode,
    required this.isRanked,
    this.maxParticipants = 16,
    this.startAt,
    this.endAt,
    this.participantCount,
    this.matchCount,
    this.isRecurring = false,
    this.recurringFrequency,
    this.recurringDayOfWeek,
    this.recurringDaysOfWeek = const [],
    this.recurringTimeOfDay,
    this.recurringAdvanceDays,
    required this.version,
    required this.canManage,
    this.canJoin = false,
    this.canWithdraw = false,
    this.canCreateMatch = false,
    this.viewerUserId,
    this.viewerIsActive = false,
    this.preferredPartnerUserIds = const [],
    this.preferredOpponentUserIds = const [],
    this.avoidUserIds = const [],
    this.preferenceVersion = 0,
    this.description,
  });

  factory ClubMatchSessionModel.fromJson(
    Map<String, dynamic> json,
  ) => ClubMatchSessionModel(
    id: json['id']?.toString() ?? '',
    communityId: json['communityId']?.toString() ?? '',
    resolvedName:
        json['resolvedName']?.toString() ?? json['name']?.toString() ?? '',
    description: json['description']?.toString(),
    status: json['status']?.toString() ?? 'OPEN',
    registrationMode: json['registrationMode']?.toString() ?? 'MIXED',
    isRanked: json['isRanked'] != false,
    maxParticipants: (json['maxParticipants'] as num?)?.toInt() ?? 16,
    startAt: json['startAt'] != null
        ? DateTime.tryParse(json['startAt'].toString())
        : null,
    endAt: json['endAt'] != null
        ? DateTime.tryParse(json['endAt'].toString())
        : null,
    participantCount: (json['participantCount'] as num?)?.toInt(),
    matchCount: (json['matchCount'] as num?)?.toInt(),
    isRecurring: json['isRecurring'] == true,
    recurringFrequency: json['recurringFrequency']?.toString(),
    recurringDayOfWeek: (json['recurringDayOfWeek'] as num?)?.toInt(),
    recurringDaysOfWeek:
        (json['recurringDaysOfWeek'] as List<dynamic>? ?? const [])
            .whereType<num>()
            .map((value) => value.toInt())
            .toList(),
    recurringTimeOfDay: json['recurringTimeOfDay']?.toString(),
    recurringAdvanceDays: (json['recurringAdvanceDays'] as num?)?.toInt(),
    version: (json['version'] as num?)?.toInt() ?? 1,
    canManage: (json['capabilities'] as Map?)?['canManage'] == true,
    canJoin: (json['capabilities'] as Map?)?['canJoin'] == true,
    canWithdraw: (json['capabilities'] as Map?)?['canWithdraw'] == true,
    canCreateMatch: (json['capabilities'] as Map?)?['canCreateMatch'] == true,
    viewerUserId: (json['viewerParticipant'] as Map?)?['userId']?.toString(),
    viewerIsActive:
        (json['viewerParticipant'] as Map?)?['status']?.toString() == 'ACTIVE',
    preferredPartnerUserIds:
        ((json['viewerPreferences'] as Map?)?['preferredPartnerUserIds']
                    as List<dynamic>? ??
                const [])
            .map((value) => value.toString())
            .toList(),
    preferredOpponentUserIds:
        ((json['viewerPreferences'] as Map?)?['preferredOpponentUserIds']
                    as List<dynamic>? ??
                const [])
            .map((value) => value.toString())
            .toList(),
    avoidUserIds:
        ((json['viewerPreferences'] as Map?)?['avoidUserIds']
                    as List<dynamic>? ??
                const [])
            .map((value) => value.toString())
            .toList(),
    preferenceVersion:
        ((json['viewerPreferences'] as Map?)?['version'] as num?)?.toInt() ?? 0,
  );
}

class ClubMatchParticipantModel {
  final String id;
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String source;
  final String status;
  final bool isMock;
  final int version;

  const ClubMatchParticipantModel({
    required this.id,
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.source,
    required this.status,
    this.isMock = false,
    required this.version,
  });

  factory ClubMatchParticipantModel.fromJson(Map<String, dynamic> json) {
    final participant = json['participant'] as Map<String, dynamic>? ?? json;
    return ClubMatchParticipantModel(
      id: participant['id']?.toString() ?? '',
      userId: participant['userId']?.toString() ?? '',
      displayName: json['fullName']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString(),
      source: participant['source']?.toString() ?? 'SELF',
      status: participant['status']?.toString() ?? 'ACTIVE',
      isMock: json['isMock'] == true || participant['isMock'] == true,
      version: (participant['version'] as num?)?.toInt() ?? 1,
    );
  }
}

class ClubSessionMatchMemberModel {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final bool isMock;

  const ClubSessionMatchMemberModel({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    this.isMock = false,
  });

  factory ClubSessionMatchMemberModel.fromJson(Map<String, dynamic> json) =>
      ClubSessionMatchMemberModel(
        userId: json['userId']?.toString() ?? json['id']?.toString() ?? '',
        displayName: json['fullName']?.toString().trim() ?? '',
        avatarUrl: json['avatarUrl']?.toString(),
        isMock: json['isMock'] == true,
      );
}

/// The web activity timeline accepts both the current `sets` payload and the
/// legacy `set1`/`game1` string payload. Keep the app timeline on the same
/// contract so `p1SetsWon`/`p2SetsWon` are never rendered as point scores.
class ClubSessionScoreModel {
  final int sideAScore;
  final int sideBScore;

  const ClubSessionScoreModel({
    required this.sideAScore,
    required this.sideBScore,
  });
}

List<ClubSessionScoreModel> parseClubSessionScoreDetails(
  Map<String, dynamic> scoreDetails,
) {
  int? parseScore(dynamic value) {
    if (value is num) return value.isFinite ? value.toInt() : null;
    final parsed = int.tryParse(value?.toString().trim() ?? '');
    return parsed;
  }

  ClubSessionScoreModel? parsePair(dynamic sideA, dynamic sideB) {
    final scoreA = parseScore(sideA);
    final scoreB = parseScore(sideB);
    if (scoreA == null || scoreB == null || scoreA < 0 || scoreB < 0) {
      return null;
    }
    return ClubSessionScoreModel(sideAScore: scoreA, sideBScore: scoreB);
  }

  ClubSessionScoreModel? parseSet(dynamic rawSet) {
    if (rawSet is! Map) return null;
    return parsePair(
      rawSet['team1Score'] ?? rawSet['score1'] ?? rawSet['p1'],
      rawSet['team2Score'] ?? rawSet['score2'] ?? rawSet['p2'],
    );
  }

  final rawSets = scoreDetails['sets'];
  if (rawSets is List) {
    final parsedSets = rawSets
        .map(parseSet)
        .whereType<ClubSessionScoreModel>()
        .toList(growable: false);
    if (parsedSets.isNotEmpty)
      return parsedSets.take(10).toList(growable: false);
  }

  final football = scoreDetails['football'];
  if (football is Map) {
    final parsedFootball = parsePair(
      football['team1Goals'],
      football['team2Goals'],
    );
    if (parsedFootball != null) return [parsedFootball];
  }

  final legacyKeys =
      scoreDetails.keys
          .where(
            (key) =>
                RegExp(r'^(set|game)\d+$', caseSensitive: false).hasMatch(key),
          )
          .toList()
        ..sort((left, right) {
          final leftNumber =
              int.tryParse(RegExp(r'\d+$').firstMatch(left)?.group(0) ?? '') ??
              0;
          final rightNumber =
              int.tryParse(RegExp(r'\d+$').firstMatch(right)?.group(0) ?? '') ??
              0;
          return leftNumber.compareTo(rightNumber);
        });

  return legacyKeys
      .map((key) {
        final value = scoreDetails[key];
        if (value is! String) return null;
        final parts = value.split('-');
        if (parts.length != 2) return null;
        return parsePair(parts[0], parts[1]);
      })
      .whereType<ClubSessionScoreModel>()
      .take(10)
      .toList(growable: false);
}

class ClubSessionMatchModel {
  final String id;
  final String status;
  final String sessionId;
  final String? standaloneMatchId;
  final String? communityId;
  final String sportKey;
  final List<String> sideAUserIds;
  final List<String> sideBUserIds;
  final int sideAScore;
  final int sideBScore;
  final int revision;
  final String eloStatus;
  final Map<String, dynamic> scoreDetails;
  final Map<String, dynamic> sportRules;
  final Map<String, dynamic> tournamentConfig;
  final bool isRanked;
  final Map<String, int> eloDelta;
  final List<ClubSessionMatchMemberModel> sideAMembers;
  final List<ClubSessionMatchMemberModel> sideBMembers;
  final DateTime? scheduledAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  List<String> get sideANames => sideAMembers
      .map((member) => member.displayName)
      .where((name) => name.isNotEmpty)
      .toList();

  List<String> get sideBNames => sideBMembers
      .map((member) => member.displayName)
      .where((name) => name.isNotEmpty)
      .toList();

  const ClubSessionMatchModel({
    required this.id,
    required this.status,
    this.sessionId = '',
    this.standaloneMatchId,
    this.communityId,
    this.sportKey = '',
    required this.sideAUserIds,
    required this.sideBUserIds,
    required this.sideAScore,
    required this.sideBScore,
    required this.revision,
    required this.eloStatus,
    this.scoreDetails = const {},
    this.sportRules = const {},
    this.tournamentConfig = const {},
    this.isRanked = true,
    this.eloDelta = const {},
    this.sideAMembers = const [],
    this.sideBMembers = const [],
    this.scheduledAt,
    this.startedAt,
    this.completedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory ClubSessionMatchModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseTimestamp(dynamic value) {
      if (value is DateTime) return value;
      final raw = value?.toString().trim();
      return raw == null || raw.isEmpty ? null : DateTime.tryParse(raw);
    }

    List<ClubSessionMatchMemberModel> parseMemberList(dynamic raw) {
      if (raw is! List) return const [];
      return raw
          .map((member) {
            if (member is Map) {
              return ClubSessionMatchMemberModel.fromJson(
                Map<String, dynamic>.from(member),
              );
            }
            final name = member?.toString().trim() ?? '';
            return ClubSessionMatchMemberModel(userId: '', displayName: name);
          })
          .where(
            (member) =>
                member.displayName.isNotEmpty || member.userId.isNotEmpty,
          )
          .toList();
    }

    List<ClubSessionMatchMemberModel> parseMembers(
      dynamic participant,
      List<dynamic> explicitMembers,
    ) {
      final participantMap = participant is Map ? participant : null;
      final raw = explicitMembers.firstWhere(
        (candidate) => candidate is List && candidate.isNotEmpty,
        orElse: () => participantMap?['members'] ?? participantMap?['rosters'],
      );
      return parseMemberList(raw);
    }

    return ClubSessionMatchModel(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'SCHEDULED',
      sessionId:
          (json['sessionId'] ??
                  json['session_id'] ??
                  json['clubMatchSessionId'])
              ?.toString() ??
          '',
      standaloneMatchId:
          (json['standaloneMatchId'] ?? json['standalone_match_id'])
              ?.toString(),
      communityId:
          (json['communityId'] ?? json['community_id'])?.toString() ??
          (json['community'] is Map
              ? (json['community'] as Map)['id']?.toString()
              : null),
      sportKey:
          (json['sport'] ?? json['sportKey'] ?? json['categorySlug'])
              ?.toString() ??
          '',
      sideAUserIds: (json['sideAUserIds'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList(),
      sideBUserIds: (json['sideBUserIds'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList(),
      sideAScore: (json['p1SetsWon'] as num?)?.toInt() ?? 0,
      sideBScore: (json['p2SetsWon'] as num?)?.toInt() ?? 0,
      revision: (json['revision'] as num?)?.toInt() ?? 1,
      eloStatus: json['eloStatus']?.toString() ?? 'PENDING',
      scoreDetails: json['scoreDetails'] is Map
          ? Map<String, dynamic>.from(json['scoreDetails'] as Map)
          : const {},
      sportRules: json['effectiveSportRules'] is Map
          ? Map<String, dynamic>.from(json['effectiveSportRules'] as Map)
          : json['sportRules'] is Map
          ? Map<String, dynamic>.from(json['sportRules'] as Map)
          : const {},
      tournamentConfig: json['tournamentConfig'] is Map
          ? Map<String, dynamic>.from(json['tournamentConfig'] as Map)
          : const {},
      isRanked: json['isRanked'] != false && json['is_ranked'] != false,
      eloDelta: json['eloDelta'] is Map
          ? Map<String, dynamic>.from(
              json['eloDelta'] as Map,
            ).map((key, value) => MapEntry(key, (value as num).toInt()))
          : const {},
      sideAMembers: parseMembers(json['participant1'], [
        json['team1MemberInfos'],
        json['team1Members'],
      ]),
      sideBMembers: parseMembers(json['participant2'], [
        json['team2MemberInfos'],
        json['team2Members'],
      ]),
      scheduledAt: parseTimestamp(json['scheduledAt'] ?? json['scheduled_at']),
      startedAt: parseTimestamp(json['startedAt'] ?? json['started_at']),
      completedAt: parseTimestamp(json['completedAt'] ?? json['completed_at']),
      createdAt: parseTimestamp(json['createdAt'] ?? json['created_at']),
      updatedAt: parseTimestamp(json['updatedAt'] ?? json['updated_at']),
    );
  }
}
