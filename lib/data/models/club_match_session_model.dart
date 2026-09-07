class ClubMatchSessionModel {
  final String id;
  final String communityId;
  final String resolvedName;
  final String? description;
  final String status;
  final String registrationMode;
  final bool isRanked;
  final int version;
  final bool canManage;

  const ClubMatchSessionModel({
    required this.id,
    required this.communityId,
    required this.resolvedName,
    required this.status,
    required this.registrationMode,
    required this.isRanked,
    required this.version,
    required this.canManage,
    this.description,
  });

  factory ClubMatchSessionModel.fromJson(Map<String, dynamic> json) =>
      ClubMatchSessionModel(
        id: json['id']?.toString() ?? '',
        communityId: json['communityId']?.toString() ?? '',
        resolvedName:
            json['resolvedName']?.toString() ?? json['name']?.toString() ?? '',
        description: json['description']?.toString(),
        status: json['status']?.toString() ?? 'OPEN',
        registrationMode: json['registrationMode']?.toString() ?? 'MIXED',
        isRanked: json['isRanked'] != false,
        version: (json['version'] as num?)?.toInt() ?? 1,
        canManage:
            (json['capabilities'] as Map?)?['canManage'] == true,
      );
}

class ClubMatchParticipantModel {
  final String id;
  final String userId;
  final String displayName;
  final String source;
  final String status;

  const ClubMatchParticipantModel({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.source,
    required this.status,
  });

  factory ClubMatchParticipantModel.fromJson(Map<String, dynamic> json) {
    final participant =
        json['participant'] as Map<String, dynamic>? ?? json;
    return ClubMatchParticipantModel(
      id: participant['id']?.toString() ?? '',
      userId: participant['userId']?.toString() ?? '',
      displayName: json['fullName']?.toString() ?? '',
      source: participant['source']?.toString() ?? 'SELF',
      status: participant['status']?.toString() ?? 'ACTIVE',
    );
  }
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

  const ClubSessionMatchModel({
    required this.id,
    required this.status,
    required this.sideAUserIds,
    required this.sideBUserIds,
    required this.sideAScore,
    required this.sideBScore,
    required this.revision,
    required this.eloStatus,
  });

  factory ClubSessionMatchModel.fromJson(Map<String, dynamic> json) =>
      ClubSessionMatchModel(
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
      );
}
