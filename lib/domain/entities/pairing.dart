import 'package:app_quanly_giaidau/core/participants/participant_display.dart';

/// Kiểu dữ liệu ghép cặp nội dung đôi cho màn quản lý giải
/// (OpenSpec `quan-ly-giai-web-parity` task 3.6/3.7, đối chiếu Web
/// `PairingParticipantsModal` + Backend DTO `pair-lite-participants*.ts`).

/// Chiến lược ghép tự động của `POST /tournaments/:id/pairing/generate`
/// (`LITE_PAIR_STRATEGIES` của Backend; Web `LitePairStrategy`).
enum PairingStrategy {
  /// Xáo trộn rồi ghép cặp, không xét trình độ.
  random,

  /// Mạnh ghép yếu; chưa có điểm thì ghép ngẫu nhiên.
  eloBalanced,

  /// Ghép người có điểm gần nhau; chưa có điểm thì ghép ngẫu nhiên.
  sameLevel;

  /// Giá trị gửi lên API.
  String get wire => switch (this) {
    PairingStrategy.random => 'RANDOM',
    PairingStrategy.eloBalanced => 'ELO_BALANCED',
    PairingStrategy.sameLevel => 'SAME_LEVEL',
  };
}

/// Một cặp ghép thủ công gửi lên `POST /tournaments/:id/pairing/batch`
/// (Web `PairSelection` = `PairLiteParticipantsDto` của Backend).
class PairInput {
  const PairInput({
    required this.participant1Id,
    required this.participant2Id,
    this.teamName,
  });

  /// ID participant thứ nhất (giữ lại).
  final String participant1Id;

  /// ID participant thứ hai (sẽ được gộp vào p1).
  final String participant2Id;

  /// Tên đội/cặp thi đấu, tuỳ chọn; bỏ trống Backend tự đặt theo tên VĐV.
  final String? teamName;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'participant1Id': participant1Id,
    'participant2Id': participant2Id,
    if (teamName != null && teamName!.trim().isNotEmpty)
      'teamName': teamName!.trim(),
  };
}

/// Một VĐV đang chờ ghép trong danh sách của sheet ghép cặp
/// (`GET /tournaments/:id/pairing/participants` — cùng shape với
/// `getLiteParticipants` của Web; Backend trả MỌI participant trừ
/// WITHDRAWN/KICKED/REJECTED nên sheet phải tự lọc "đang chờ" như Web).
class PairingCandidate {
  const PairingCandidate({
    required this.id,
    required this.name,
    this.divisionId,
    this.avatarUrl,
    this.teamStatus,
    this.teamInviteToken,
    this.holdsSingleAthlete = true,
  });

  final String id;

  /// Tên hiển thị: roster profile ưu tiên như Web `pairingParticipantName`,
  /// thiếu thì rơi về nhãn `players`/`teamName` (`participantTitle`).
  final String name;

  final String? divisionId;
  final String? avatarUrl;

  /// Trạng thái đăng ký (`tournamentParticipants.teamStatus`); người chờ ghép
  /// là `PENDING_PARTNER` (Web lọc chính xác giá trị này).
  final String? teamStatus;

  /// Link mời đồng đội đang giữ (`teamInviteToken`) — có token thì không thể
  /// ghép hộ (Web: `!participant.teamInviteToken`).
  final String? teamInviteToken;

  /// Entry giữ đúng 1 VĐV (port `holdsSingleAthlete` của Web
  /// `registration-identity.ts:244`: entry do BTC thêm/import có thể ghi tên
  /// VĐV 2 trong `customResponses.player2Name/player2Email` dù roster trống).
  final bool holdsSingleAthlete;

  /// Đúng bộ lọc "VĐV đang chờ ghép" của Web `handleOpenPairing`
  /// (RegistrationTab.tsx:755-758): PENDING_PARTNER + không giữ link mời +
  /// giữ đúng 1 VĐV.
  bool get isWaitingForPartner =>
      teamStatus == 'PENDING_PARTNER' &&
      teamInviteToken == null &&
      holdsSingleAthlete;

  factory PairingCandidate.fromJson(Map<dynamic, dynamic> json) {
    var rosterName = '';
    String? rosterAvatar;
    final rosters = json['rosters'];
    var rosterCount = 0;
    if (rosters is List) {
      rosterCount = rosters.length;
      if (rosters.isNotEmpty && rosters.first is Map) {
        final profile = (rosters.first as Map)['profile'];
        if (profile is Map) {
          rosterName = normalizeParticipantText(
            profile['fullName']?.toString(),
          );
          final avatar = profile['avatarUrl']?.toString();
          rosterAvatar = (avatar == null || avatar.isEmpty) ? null : avatar;
        }
      }
    }
    final name = rosterName.isNotEmpty
        ? rosterName
        : participantLabel(
            teamName: json['teamName']?.toString(),
            players: toParticipantPlayers(json),
            teamOnly: json['footballTeamId'] != null,
          );
    final divisionId = json['tournamentDivisionId']?.toString();
    final customResponses = json['customResponses'] is Map
        ? json['customResponses'] as Map
        : null;
    return PairingCandidate(
      id: json['id']?.toString() ?? '',
      name: name,
      divisionId: (divisionId == null || divisionId.isEmpty)
          ? null
          : divisionId,
      avatarUrl: rosterAvatar,
      teamStatus: _nullableText(json['teamStatus']),
      teamInviteToken: _nullableText(json['teamInviteToken']),
      holdsSingleAthlete: _holdsSingleAthlete(rosterCount, customResponses),
    );
  }

  /// Port `holdsSingleAthlete` của Web (`registration-identity.ts:244-254`):
  /// entry do BTC thêm/import ghi nguồn trong `customResponses.importedFrom`
  /// (năm nguồn Backend ghi) và có thể nêu sẵn VĐV 2 qua `player2Name`/
  /// `player2Email`; entry khác thì giữ đúng bằng số roster.
  static bool _holdsSingleAthlete(
    int rosterCount,
    Map<dynamic, dynamic>? responses,
  ) {
    const knownSources = {
      'ORGANIZER_DIRECT',
      'MANUAL_EMAIL',
      'EXCEL',
      'AI_EXCEL',
      'GOOGLE_FORM',
    };
    final source = _nullableText(responses?['importedFrom']);
    if (source == null || !knownSources.contains(source)) {
      return rosterCount == 1;
    }
    final namesAthlete2 =
        _nullableText(responses?['player2Name']) != null ||
        _nullableText(responses?['player2Email']) != null;
    final extraFromResponses = namesAthlete2 ? 2 : 1;
    final memberCount = rosterCount > extraFromResponses
        ? rosterCount
        : extraFromResponses;
    return memberCount == 1;
  }
}

String? _nullableText(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

/// Kết quả `POST /tournaments/:id/pairing/generate`
/// (Web `LiteGeneratePairsResponse` — App chỉ dùng số cặp đã ghép và số VĐV
/// còn chờ để báo kết quả, giống `handleGenerateRandomPairs` của Web).
class PairGenerateResult {
  const PairGenerateResult({
    required this.pairedCount,
    required this.unpairedCount,
  });

  final int pairedCount;
  final int unpairedCount;
}
