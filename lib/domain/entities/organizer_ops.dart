class OrganizerOpsMember {
  const OrganizerOpsMember({
    required this.userId,
    required this.fullName,
    this.avatarUrl,
    this.role,
    this.isMock = false,
  });

  final String userId;
  final String fullName;
  final String? avatarUrl;
  final String? role;
  final bool isMock;

  factory OrganizerOpsMember.fromJson(Map<String, dynamic> json) {
    return OrganizerOpsMember(
      userId:
          (json['userId'] ?? json['user_id'] ?? json['id'])?.toString() ?? '',
      fullName:
          (json['fullName'] ?? json['full_name'] ?? json['name'])?.toString() ??
          'Vận động viên',
      avatarUrl: (json['avatarUrl'] ?? json['avatar_url'])?.toString(),
      role: json['role']?.toString(),
      isMock: json['isMock'] == true || json['is_mock'] == true,
    );
  }
}

class OrganizerOpsParticipant {
  const OrganizerOpsParticipant({
    required this.id,
    required this.teamName,
    required this.teamStatus,
    required this.isPaid,
    required this.members,
    this.registeredByUserId,
    this.divisionId,
    this.seed,
    this.entryFee,
    this.registeredAt,
  });

  final String id;
  final String teamName;
  final String teamStatus;
  final bool isPaid;
  final List<OrganizerOpsMember> members;
  final String? registeredByUserId;
  final String? divisionId;
  final int? seed;
  final double? entryFee;
  final DateTime? registeredAt;

  factory OrganizerOpsParticipant.fromJson(Map<String, dynamic> json) {
    final rawMembers = json['members'];
    final members = rawMembers is List
        ? rawMembers
              .whereType<Map>()
              .map(
                (member) => OrganizerOpsMember.fromJson(
                  Map<String, dynamic>.from(member),
                ),
              )
              .where((member) => member.userId.isNotEmpty)
              .toList(growable: false)
        : const <OrganizerOpsMember>[];
    final rawFee = json['entryFeeAtRegistration'] ?? json['entryFee'];
    final rawDate = json['registeredAt'] ?? json['registered_at'];

    return OrganizerOpsParticipant(
      id: json['id']?.toString() ?? '',
      teamName:
          (json['teamName'] ?? json['team_name'] ?? json['name'])?.toString() ??
          'Chưa đặt tên',
      teamStatus:
          (json['teamStatus'] ?? json['team_status'])?.toString() ?? 'PENDING',
      isPaid: json['isPaid'] == true || json['is_paid'] == true,
      members: members,
      registeredByUserId:
          (json['registeredBy'] is Map
                  ? json['registeredBy']['id']
                  : json['registeredBy'])
              ?.toString() ??
          (json['registeredByUser'] is Map
                  ? json['registeredByUser']['id']
                  : json['registeredByUser'])
              ?.toString(),
      divisionId: (json['tournamentDivisionId'] ?? json['divisionId'])
          ?.toString(),
      seed: _toInt(json['seed']),
      entryFee: _toDouble(rawFee),
      registeredAt: rawDate is String ? DateTime.tryParse(rawDate) : null,
    );
  }

  bool get isKicked => teamStatus.toUpperCase() == 'KICKED';
  bool get isDisciplined =>
      teamStatus.toUpperCase() == 'DISQUALIFIED' ||
      teamStatus.toUpperCase() == 'DISCIPLINED';
}

class OrganizerOpsReferee {
  const OrganizerOpsReferee({
    required this.id,
    required this.userId,
    required this.fullName,
    this.email,
    this.avatarUrl,
    this.status,
  });

  final String id;
  final String userId;
  final String fullName;
  final String? email;
  final String? avatarUrl;
  final String? status;

  factory OrganizerOpsReferee.fromJson(Map<String, dynamic> json) {
    return OrganizerOpsReferee(
      id: json['id']?.toString() ?? '',
      userId: (json['userId'] ?? json['user_id'])?.toString() ?? '',
      fullName:
          (json['fullName'] ?? json['full_name'] ?? json['name'])?.toString() ??
          'Trọng tài',
      email: json['email']?.toString(),
      avatarUrl: (json['avatarUrl'] ?? json['avatar_url'])?.toString(),
      status: json['status']?.toString(),
    );
  }
}

class OrganizerOpsAuditEntry {
  const OrganizerOpsAuditEntry({
    required this.id,
    required this.tableName,
    required this.recordId,
    required this.action,
    required this.createdAt,
    this.actorName,
  });

  final String id;
  final String tableName;
  final String recordId;
  final String action;
  final DateTime createdAt;
  final String? actorName;

  factory OrganizerOpsAuditEntry.fromJson(Map<String, dynamic> json) {
    final rawCreatedAt = json['createdAt'] ?? json['created_at'];
    final user = json['user'];
    final actorName = user is Map
        ? (user['fullName'] ?? user['full_name'] ?? user['email'])?.toString()
        : null;
    return OrganizerOpsAuditEntry(
      id: json['id']?.toString() ?? '',
      tableName: (json['tableName'] ?? json['table_name'])?.toString() ?? '',
      recordId: (json['recordId'] ?? json['record_id'])?.toString() ?? '',
      action: json['action']?.toString() ?? 'UPDATE',
      createdAt: rawCreatedAt is String
          ? DateTime.tryParse(rawCreatedAt) ??
                DateTime.fromMillisecondsSinceEpoch(0)
          : DateTime.fromMillisecondsSinceEpoch(0),
      actorName: actorName,
    );
  }
}

double? _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int? _toInt(dynamic value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
