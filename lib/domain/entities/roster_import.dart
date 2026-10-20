/// Hợp đồng import roster (Excel) dùng chung cho parser, màn import và repository.
/// Khớp kiểu `RosterImportBatch*` trong web `src/features/tournaments/api.ts`.
library;

/// Một dòng gửi lên server. `source` là `EXCEL` cho dòng đọc từ file.
class RosterImportBatchItem {
  const RosterImportBatchItem({
    required this.clientRowIndex,
    required this.player1Name,
    this.source = 'EXCEL',
    this.player1Email,
    this.player1Phone,
    this.player2Name,
    this.player2Email,
    this.player2Phone,
    required this.teamName,
    this.elo,
    this.isPaid,
    this.autoApprove,
    this.sourceRowIndex,
    this.sourceSheetName,
    this.customResponses,
    this.confirmedPlayer1UserId,
    this.confirmedPlayer2UserId,
  });

  final int clientRowIndex;
  final String source;
  final String player1Name;
  final String? player1Email;
  final String? player1Phone;
  final String? player2Name;
  final String? player2Email;
  final String? player2Phone;
  /// Tên đội từ file; rỗng khi file không có. Không bao giờ ghép tên VĐV.
  final String teamName;
  final num? elo;
  final bool? isPaid;
  final bool? autoApprove;
  final int? sourceRowIndex;
  final String? sourceSheetName;
  final Map<String, dynamic>? customResponses;

  /// Tài khoản đã được người dùng xác nhận. Chỉ gửi khi khác rỗng; rỗng nghĩa là
  /// để chưa liên kết (giống web).
  final String? confirmedPlayer1UserId;
  final String? confirmedPlayer2UserId;

  Map<String, dynamic> toJson() => {
    'clientRowIndex': clientRowIndex,
    'source': source,
    'player1Name': player1Name,
    if (_present(player1Email)) 'player1Email': player1Email,
    if (_present(player1Phone)) 'player1Phone': player1Phone,
    if (_present(player2Name)) 'player2Name': player2Name,
    if (_present(player2Email)) 'player2Email': player2Email,
    if (_present(player2Phone)) 'player2Phone': player2Phone,
    'teamName': teamName,
    if (elo != null) 'elo': elo,
    if (isPaid != null) 'isPaid': isPaid,
    if (autoApprove != null) 'autoApprove': autoApprove,
    if (sourceRowIndex != null) 'sourceRowIndex': sourceRowIndex,
    if (_present(sourceSheetName)) 'sourceSheetName': sourceSheetName,
    if (customResponses != null) 'customResponses': customResponses,
    if (_present(confirmedPlayer1UserId))
      'confirmedPlayer1UserId': confirmedPlayer1UserId,
    if (_present(confirmedPlayer2UserId))
      'confirmedPlayer2UserId': confirmedPlayer2UserId,
  };
}

class RosterImportBatchGroup {
  const RosterImportBatchGroup({
    required this.divisionId,
    required this.participants,
  });

  /// null khi giải không có nội dung (division) nào khớp.
  final String? divisionId;
  final List<RosterImportBatchItem> participants;

  Map<String, dynamic> toJson() => {
    'divisionId': divisionId,
    'participants': participants.map((p) => p.toJson()).toList(growable: false),
  };
}

class RosterImportBatchRequest {
  const RosterImportBatchRequest({required this.groups});

  final List<RosterImportBatchGroup> groups;

  Map<String, dynamic> toJson() => {
    'groups': groups.map((g) => g.toJson()).toList(growable: false),
  };
}

class RosterImportBatchCandidate {
  const RosterImportBatchCandidate({
    required this.userId,
    required this.email,
    required this.fullName,
  });

  final String userId;
  final String email;
  final String fullName;

  factory RosterImportBatchCandidate.fromJson(Map<String, dynamic> json) {
    return RosterImportBatchCandidate(
      userId: _string(json['userId']),
      email: _string(json['email']),
      fullName: _string(json['fullName']),
    );
  }
}

class RosterImportBatchPreviewRow {
  const RosterImportBatchPreviewRow({
    required this.clientRowIndex,
    required this.rowIndex,
    required this.player1Email,
    required this.player2Email,
    required this.status,
    required this.isEligible,
    required this.capacityDelta,
    required this.customResponses,
    required this.customResponseError,
    required this.player1Candidates,
    required this.player2Candidates,
    required this.confirmedPlayer1UserId,
    required this.confirmedPlayer2UserId,
    this.sourceRowIndex,
    this.sourceSheetName,
  });

  final int clientRowIndex;
  final int rowIndex;
  final int? sourceRowIndex;
  final String? sourceSheetName;
  final String player1Email;
  final String? player2Email;

  /// Mã trạng thái từ server, ví dụ `FOUND`, `NOT_FOUND`, `INVALID_EMAIL`,
  /// `MISSING_EMAIL`, `MISSING_NAME`, `DUPLICATE_IN_FILE`,
  /// `DUPLICATE_IN_TOURNAMENT`, `PLAYER2_REQUIRED`, `PLAYER2_NOT_ALLOWED`,
  /// `DIVISION_UNKNOWN`.
  final List<String> status;

  /// Quyết định của server. Dòng không đủ điều kiện không được gửi khi commit.
  final bool isEligible;
  final num capacityDelta;
  final Map<String, dynamic> customResponses;
  final String? customResponseError;
  final List<RosterImportBatchCandidate> player1Candidates;
  final List<RosterImportBatchCandidate> player2Candidates;
  final String? confirmedPlayer1UserId;
  final String? confirmedPlayer2UserId;

  factory RosterImportBatchPreviewRow.fromJson(Map<String, dynamic> json) {
    final accounts = _map(json['accountCandidates']);
    return RosterImportBatchPreviewRow(
      clientRowIndex: _int(json['clientRowIndex']),
      rowIndex: _int(json['rowIndex']),
      sourceRowIndex: _nullableInt(json['sourceRowIndex']),
      sourceSheetName: _nullableString(json['sourceSheetName']),
      player1Email: _string(json['player1Email']),
      player2Email: _nullableString(json['player2Email']),
      status: _stringList(json['status']),
      isEligible: json['isEligible'] == true,
      capacityDelta: _num(json['capacityDelta']),
      customResponses: _map(json['customResponses']),
      customResponseError: _nullableString(json['customResponseError']),
      player1Candidates: _candidates(accounts['player1']),
      player2Candidates: _candidates(accounts['player2']),
      confirmedPlayer1UserId: _nullableString(json['confirmedPlayer1UserId']),
      confirmedPlayer2UserId: _nullableString(json['confirmedPlayer2UserId']),
    );
  }
}

class RosterImportBatchPreviewGroup {
  const RosterImportBatchPreviewGroup({
    required this.divisionId,
    required this.divisionName,
    required this.divisionMatched,
    required this.rows,
    required this.requestedTeamSlots,
    required this.capacityRemaining,
    required this.capacityRemainingAfterBatch,
    required this.capacityFits,
  });

  final String? divisionId;
  final String? divisionName;
  final bool divisionMatched;
  final List<RosterImportBatchPreviewRow> rows;
  final num requestedTeamSlots;
  final num? capacityRemaining;
  final num? capacityRemainingAfterBatch;
  final bool capacityFits;

  factory RosterImportBatchPreviewGroup.fromJson(Map<String, dynamic> json) {
    return RosterImportBatchPreviewGroup(
      divisionId: _nullableString(json['divisionId']),
      divisionName: _nullableString(json['divisionName']),
      divisionMatched: json['divisionMatched'] == true,
      rows: _list(json['rows'])
          .map((row) => RosterImportBatchPreviewRow.fromJson(_map(row)))
          .toList(growable: false),
      requestedTeamSlots: _num(json['requestedTeamSlots']),
      capacityRemaining: _nullableNum(json['capacityRemaining']),
      capacityRemainingAfterBatch: _nullableNum(
        json['capacityRemainingAfterBatch'],
      ),
      capacityFits: json['capacityFits'] == true,
    );
  }
}

class RosterImportBatchPreview {
  const RosterImportBatchPreview({
    required this.totalParticipants,
    required this.groups,
  });

  final int totalParticipants;
  final List<RosterImportBatchPreviewGroup> groups;

  factory RosterImportBatchPreview.fromJson(Map<String, dynamic> json) {
    return RosterImportBatchPreview(
      totalParticipants: _int(json['totalParticipants']),
      groups: _list(json['groups'])
          .map((group) => RosterImportBatchPreviewGroup.fromJson(_map(group)))
          .toList(growable: false),
    );
  }
}

class RosterImportBatchResult {
  const RosterImportBatchResult({
    required this.importedCount,
    required this.replayed,
    this.message,
  });

  final int importedCount;

  /// true khi server trả kết quả của lần commit trước cùng Idempotency-Key.
  final bool replayed;
  final String? message;

  factory RosterImportBatchResult.fromJson(Map<String, dynamic> json) {
    return RosterImportBatchResult(
      importedCount: _int(json['importedCount']),
      replayed: json['replayed'] == true,
      message: _nullableString(json['message']),
    );
  }
}

bool _present(String? value) => value != null && value.trim().isNotEmpty;

String _string(Object? value) => value?.toString() ?? '';

String? _nullableString(Object? value) {
  if (value == null) return null;
  final text = value.toString();
  return text.isEmpty ? null : text;
}

int _int(Object? value) => value is num ? value.toInt() : 0;

int? _nullableInt(Object? value) => value is num ? value.toInt() : null;

num _num(Object? value) => value is num ? value : 0;

num? _nullableNum(Object? value) => value is num ? value : null;

Map<String, dynamic> _map(Object? value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}

List<Object?> _list(Object? value) => value is List ? value : const [];

List<String> _stringList(Object? value) =>
    _list(value).map((item) => item.toString()).toList(growable: false);

List<RosterImportBatchCandidate> _candidates(Object? value) => _list(value)
    .map((item) => RosterImportBatchCandidate.fromJson(_map(item)))
    .toList(growable: false);
