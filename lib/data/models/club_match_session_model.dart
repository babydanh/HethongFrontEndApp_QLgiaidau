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

class ClubSessionMatchModel {
  final String id;
  final String status;
  final List<String> sideAUserIds;
  final List<String> sideBUserIds;
  final int sideAScore;
  final int sideBScore;
  final int revision;
  final String eloStatus;
  final Map<String, dynamic> scoreDetails;
  final Map<String, int> eloDelta;
  final List<ClubSessionMatchMemberModel> sideAMembers;
  final List<ClubSessionMatchMemberModel> sideBMembers;

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
    required this.sideAUserIds,
    required this.sideBUserIds,
    required this.sideAScore,
    required this.sideBScore,
    required this.revision,
    required this.eloStatus,
    this.scoreDetails = const {},
    this.eloDelta = const {},
    this.sideAMembers = const [],
    this.sideBMembers = const [],
  });

  factory ClubSessionMatchModel.fromJson(Map<String, dynamic> json) {
    List<ClubSessionMatchMemberModel> parseMembers(dynamic participant) {
      if (participant is! Map) return const [];
      final members = participant['members'];
      if (members is! List) return const [];
      return members
          .whereType<Map>()
          .map(
            (member) => ClubSessionMatchMemberModel.fromJson(
              Map<String, dynamic>.from(member),
            ),
          )
          .toList();
    }

    return ClubSessionMatchModel(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'SCHEDULED',
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
      eloDelta: json['eloDelta'] is Map
          ? Map<String, dynamic>.from(
              json['eloDelta'] as Map,
            ).map((key, value) => MapEntry(key, (value as num).toInt()))
          : const {},
      sideAMembers: parseMembers(json['participant1']),
      sideBMembers: parseMembers(json['participant2']),
    );
  }
}
