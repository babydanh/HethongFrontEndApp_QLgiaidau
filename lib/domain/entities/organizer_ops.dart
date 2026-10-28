import 'package:app_quanly_giaidau/core/participants/participant_display.dart';

class OrganizerOpsMember {
  const OrganizerOpsMember({
    required this.userId,
    required this.fullName,
    this.avatarUrl,
    this.role,
    this.isMock = false,
    this.email,
    this.phoneNumber,
  });

  final String userId;
  final String fullName;
  final String? avatarUrl;
  final String? role;
  final bool isMock;

  /// Chỉ màn quản lý BTC mới thấy email/SĐT thành viên (DTO organizer).
  final String? email;
  final String? phoneNumber;

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
      email: _textOrNull(json['email']),
      phoneNumber: _textOrNull(json['phoneNumber'] ?? json['phone_number']),
    );
  }
}

class OrganizerOpsParticipant {
  const OrganizerOpsParticipant({
    required this.id,
    this.teamName = '',
    required this.teamStatus,
    required this.isPaid,
    required this.members,
    this.players = const [],
    this.registeredByUserId,
    this.footballTeamId,
    this.divisionId,
    this.seed,
    this.entryFee,
    this.registeredAt,
    this.customResponses = const {},
    this.canUnpair = false,
    this.canOrganizerEdit = false,
    this.rosterLockedAt,
    this.isWildcard = false,
    this.isPresent = false,
    this.teamInviteToken,
    this.payment,
  });

  final String id;
  final String teamName;
  final String teamStatus;
  final bool isPaid;
  final List<OrganizerOpsMember> members;
  final List<ParticipantPlayer> players;
  final String? registeredByUserId;
  final String? divisionId;
  final String? footballTeamId;
  final int? seed;
  final double? entryFee;
  final DateTime? registeredAt;

  /// Câu trả lời form đăng ký + dữ liệu BTC nhập (ghi chú nằm ở `notes`).
  final Map<String, dynamic> customResponses;

  /// BTC tách được cặp này (server quyết định: cặp do BTC ghép/nhập, đang
  /// COMPLETE/PENDING_APPROVAL và giữ đủ 2 VĐV).
  final bool canUnpair;

  /// BTC sửa được hồ sơ do BTC tạo (liên hệ từng thành viên khách).
  final bool canOrganizerEdit;

  final DateTime? rosterLockedAt;
  final bool isWildcard;

  /// Organizer's day-of-event check-in mark (a note only, gates nothing).
  final bool isPresent;
  final String? teamInviteToken;

  /// Thanh toán thô (amount/status/transactionReference/paidAt…).
  final Map<String, dynamic>? payment;

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
    final rawRosterLock = json['rosterLockedAt'] ?? json['roster_locked_at'];
    final rawPayment = json['payment'];

    return OrganizerOpsParticipant(
      id: json['id']?.toString() ?? '',
      teamName: _teamNameOf(
        json['teamName'] ?? json['team_name'] ?? json['name'],
      ),
      teamStatus:
          (json['teamStatus'] ?? json['team_status'])?.toString() ?? 'PENDING',
      isPaid: json['isPaid'] == true || json['is_paid'] == true,
      members: members,
      players: toParticipantPlayers(json),
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
      footballTeamId: (json['footballTeamId'] ?? json['football_team_id'])
          ?.toString(),
      seed: _toInt(json['seed']),
      entryFee: _toDouble(rawFee),
      registeredAt: rawDate is String ? DateTime.tryParse(rawDate) : null,
      customResponses: json['customResponses'] is Map
          ? Map<String, dynamic>.from(json['customResponses'] as Map)
          : const {},
      canUnpair: json['canUnpair'] == true,
      canOrganizerEdit: json['canOrganizerEdit'] == true,
      rosterLockedAt: rawRosterLock is String
          ? DateTime.tryParse(rawRosterLock)
          : null,
      isWildcard: json['isWildcard'] == true || json['is_wildcard'] == true,
      isPresent: json['isPresent'] == true,
      teamInviteToken: _textOrNull(json['teamInviteToken']),
      payment: rawPayment is Map ? Map<String, dynamic>.from(rawPayment) : null,
    );
  }

  /// Có VĐV ảo (mock) trong roster — Web hiện nút "Xoá VĐV ảo" cho hồ sơ này.
  bool get hasMockMember => members.any((member) => member.isMock);

  /// Tên đội đã chuẩn hoá; '' khi chưa có tên (không dựng tên giả, VĐV hiển thị qua ParticipantLabel).
  static String _teamNameOf(Object? value) =>
      normalizeParticipantText(value?.toString());

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

/// Chuỗi đã trim; null khi rỗng (dùng cho trường tuỳ chọn của DTO organizer).
String? _textOrNull(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}
