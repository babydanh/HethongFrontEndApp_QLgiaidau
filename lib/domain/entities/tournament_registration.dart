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
    this.effectiveRegistrationEndDate,
    this.participantCount,
    this.capacity,
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
  /// Hạn chót hiệu lực do backend tính sẵn: min(hạn nội dung, hạn giải).
  /// null nghĩa là không đặt hạn — server cũng không chặn theo ngày trong
  /// trường hợp đó, nên client không được tự coi là đã hết hạn.
  final DateTime? effectiveRegistrationEndDate;
  final int? participantCount;

  /// Sức chứa do backend tính sẵn. Nội dung đôi dùng suất đội nên có thể
  /// lẻ (một VĐV chưa ghép = 0.5 đội); app không tự chia lại từ số bản ghi.
  final TournamentDivisionCapacity? capacity;

  /// `matchType` chuẩn hoá về `SINGLES`/`DOUBLES`/`MIXED_DOUBLES`; null nghĩa là
  /// app không nhận ra format này nên không được suy bất cứ điều gì từ nó.
  String? get _normalizedMatchType {
    final normalized =
        matchType
            ?.trim()
            .toUpperCase()
            .replaceAll('-', '_')
            .replaceAll(' ', '_');
    return switch (normalized) {
      'SINGLE' || 'SINGLES' || 'DON' => 'SINGLES',
      'DOUBLE' || 'DOUBLES' || 'DOI' => 'DOUBLES',
      'MIXED_DOUBLE' || 'MIXED_DOUBLES' || 'DOI_NAM_NU' => 'MIXED_DOUBLES',
      _ => null,
    };
  }

  /// Số suất đội đã chiếm. null nghĩa là backend chưa gửi projection cho nội
  /// dung mà app không chắc 1 bản ghi = 1 suất → sức chứa CHƯA BIẾT, không
  /// phải bằng 0 cũng không phải bằng số hồ sơ.
  ///
  /// Chỉ `SINGLES` được đếm dòng: đơn (và môn đội, backend cũng gán
  /// `matchType: SINGLES` cho giải bóng đá) đúng là mỗi bản ghi một suất. Đôi
  /// tính theo SUẤT ĐỘI nên 4 hồ sơ có thể chỉ là 2 suất (1 VĐV chưa ghép =
  /// 0.5 suất); format lạ/mất `matchType` thì app không có quy ước nào để
  /// quy đổi. Cả hai trường hợp đó sức chứa phải để ngỏ cho tới khi server gửi
  /// projection — đoán sai rồi báo "đầy" còn tệ hơn là không hiện gì.
  double? get occupiedTeamSlots {
    final projection = capacity?.occupiedTeamSlots;
    if (projection != null) return projection;
    if (_normalizedMatchType != 'SINGLES') return null;
    // Đơn: một bản ghi = một suất, nên đếm dòng vẫn đúng đơn vị.
    return (participantCount ?? 0).toDouble();
  }

  /// `maxParticipants` vẫn là giới hạn số đội.
  int? get effectiveMaxTeamSlots =>
      capacity?.maxTeamSlots ?? maxParticipants;

  bool get isFull => capacity?.isFull ?? _isFullByTeamSlots;

  bool get _isFullByTeamSlots {
    final max = effectiveMaxTeamSlots;
    final occupied = occupiedTeamSlots;
    if (max == null || max <= 0 || occupied == null) return false;
    return occupied >= max;
  }

  /// Nhãn sức chứa theo SUẤT ĐỘI, không phải số hồ sơ: `0.5/4`, `2/4`, `4/4`.
  /// Nội dung không đặt giới hạn đội thì chỉ hiện phần đã chiếm; nội dung thiếu
  /// projection (đôi, format lạ, mất `matchType`) thì không hiện gì thay vì đoán.
  String? get teamSlotsLabel {
    final occupied = occupiedTeamSlots;
    if (occupied == null) return null;
    final text = _formatTeamSlots(occupied);
    final maxTeams = effectiveMaxTeamSlots;
    return maxTeams == null ? text : '$text/$maxTeams';
  }

  /// Giữ một chữ số thập phân cho suất đội lẻ (0.5), bỏ `.0` khi là số nguyên.
  static String _formatTeamSlots(double value) {
    final rounded = (value * 10).round() / 10;
    return rounded == rounded.roundToDouble()
        ? rounded.toInt().toString()
        : rounded.toStringAsFixed(1);
  }

  factory TournamentDivisionOption.fromJson(Map<String, dynamic> json) {
    final minElo = json['minElo'] ?? json['min_elo'];
    final maxElo = json['maxElo'] ?? json['max_elo'];
    final entryFee = json['entryFee'] ?? json['entry_fee'];
    final maxParticipants = json['maxParticipants'] ?? json['max_participants'];
    final rawEndDate =
        json['registrationEndDate'] ?? json['registration_end_date'];
    final rawEffectiveEnd =
        json['effectiveRegistrationEndDate'] ??
        json['effective_registration_end_date'];
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
      effectiveRegistrationEndDate: rawEffectiveEnd is String
          ? DateTime.tryParse(rawEffectiveEnd)
          : null,
      participantCount: _parseInt(rawCount),
      capacity: json['capacity'] is Map
          ? TournamentDivisionCapacity.fromJson(
              Map<String, dynamic>.from(json['capacity'] as Map),
            )
          : null,
    );
  }
}

/// Projection sức chứa do backend tính sẵn cho một nội dung thi đấu.
class TournamentDivisionCapacity {
  const TournamentDivisionCapacity({
    required this.occupiedTeamSlots,
    this.occupiedMemberSlots,
    this.maxTeamSlots,
    this.isFull,
  });

  /// Số suất đội đã chiếm; nội dung đôi có thể lẻ (1 VĐV = 0.5 đội).
  final double occupiedTeamSlots;
  final double? occupiedMemberSlots;

  /// null nghĩa là nội dung không đặt giới hạn số đội.
  final int? maxTeamSlots;
  final bool? isFull;

  factory TournamentDivisionCapacity.fromJson(Map<String, dynamic> json) {
    return TournamentDivisionCapacity(
      occupiedTeamSlots: _parseDouble(json['occupiedTeamSlots']) ?? 0,
      occupiedMemberSlots: _parseDouble(json['occupiedMemberSlots']),
      maxTeamSlots: _parseInt(json['maxTeamSlots']),
      isFull: json['isFull'] is bool ? json['isFull'] as bool : null,
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
