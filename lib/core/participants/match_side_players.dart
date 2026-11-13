import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';

/// VĐV của một bên trận (side 1 | 2), theo thứ tự ưu tiên:
/// `teamNPlayers` → `teamNMemberInfos` → `teamNMembers` (tên khách).
/// Không dựng VĐV từ tên đội.
List<ParticipantPlayer> matchSidePlayers(MatchModel match, int side) {
  final players = side == 1 ? match.team1Players : match.team2Players;
  if (players.isNotEmpty) return players;

  final memberInfos = side == 1
      ? match.team1MemberInfos
      : match.team2MemberInfos;
  final fromInfos = participantPlayersFromMemberInfos(memberInfos);
  if (fromInfos.isNotEmpty) return fromInfos;

  final names =
      (side == 1 ? match.team1Members : match.team2Members) ?? const <String>[];
  return participantPlayersFromNames(names);
}

/// Tên đội để hiển thị. Domain đặt `'TBD'` làm placeholder khi chưa có đội;
/// placeholder đó không phải tên đội nên trả về null (ParticipantLabel sẽ
/// render VĐV hoặc "Chưa xác định").
String? matchSideTeamName(MatchModel match, int side) {
  final name = side == 1 ? match.team1Name : match.team2Name;
  return name.isEmpty || name == 'TBD' ? null : name;
}

/// Bóng đá: tên đội luôn hiển thị là TEAM khi có tên (`teamOnly`).
bool isFootballMatch(MatchModel match) => match.sportKey == 'football';

/// Nhãn hiển thị của một bên trận. Chỉ để render; định danh dùng side.
String matchSideLabel(MatchModel match, int side) => participantLabel(
  teamName: matchSideTeamName(match, side),
  players: matchSidePlayers(match, side),
  teamOnly: isFootballMatch(match),
);

/// Nhãn viết tắt của một bên (bảng điểm nhỏ trên video). Bên chưa có đội/VĐV
/// hiện [undetermined] để ô tên không bị trống.
String matchSideShortLabel(
  MatchModel match,
  int side, {
  required String undetermined,
}) {
  final label = participantLabel(
    teamName: matchSideTeamName(match, side),
    players: matchSidePlayers(match, side),
    teamOnly: isFootballMatch(match),
    abbreviated: true,
  );
  return label.isEmpty ? undetermined : label;
}

/// Tiêu đề "A VS B" của trận. Bên chưa có đội/VĐV ([matchSideLabel] rỗng) hiện
/// [undetermined] để tiêu đề không chỉ còn chữ "VS".
String matchSidesTitle(
  MatchModel match, {
  required String separator,
  required String undetermined,
}) {
  String side(int n) {
    final label = matchSideLabel(match, n);
    return label.isEmpty ? undetermined : label;
  }

  return '${side(1)} $separator ${side(2)}';
}

/// Roster (có userId/ELO/ảnh) của một bên trận cho nơi cần `MatchMemberInfo`.
/// Payload chỉ có `participant.players[]` (không `members`/`rosters`) để
/// `teamNMemberInfos` rỗng, nên rơi về [matchSidePlayers] để người có tài khoản
/// vẫn có avatar và viền hạng.
List<MatchMemberInfo> matchSideMemberInfos(MatchModel match, int side) {
  final infos = side == 1 ? match.team1MemberInfos : match.team2MemberInfos;
  if (infos.isNotEmpty) return infos;
  return [
    for (final p in matchSidePlayers(match, side))
      MatchMemberInfo(
        userId: p.userId,
        fullName: p.fullName,
        avatarUrl: p.avatarUrl,
        eloPoints: p.eloPoints,
        tierName: p.tierName,
      ),
  ];
}
