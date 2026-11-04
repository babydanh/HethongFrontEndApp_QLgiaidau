import 'package:app_quanly_giaidau/domain/entities/match.dart';

/// Returns true only for a match whose two sides are real and resolvable.
///
/// Public/live surfaces must not present bracket placeholders, BYEs or mock
/// participants as a playable encounter. This is intentionally conservative:
/// unresolved slots are hidden until the backend supplies real participants.
bool isRenderablePublicMatch(MatchModel match) {
  if (match.isBye || match.team1IsMock || match.team2IsMock) return false;
  if (match.team1Id.trim().isEmpty || match.team2Id.trim().isEmpty) {
    return false;
  }
  if (match.team1MemberInfos.any((member) => member.isMock) ||
      match.team2MemberInfos.any((member) => member.isMock)) {
    return false;
  }

  return _isResolvedSide(match.team1Name, hasPlayers: _hasPlayers(match, 1)) &&
      _isResolvedSide(match.team2Name, hasPlayers: _hasPlayers(match, 2));
}

bool _hasPlayers(MatchModel match, int side) {
  final players = side == 1 ? match.team1Players : match.team2Players;
  final members = side == 1 ? match.team1MemberInfos : match.team2MemberInfos;
  return players.isNotEmpty || members.isNotEmpty;
}

/// A side with real players is resolved even without a team name: athletes
/// added one by one or by Excel have no team name, and `MatchModel.fromJson`
/// leaves the name empty for them so the players are shown instead.
bool _isResolvedSide(String name, {required bool hasPlayers}) {
  if (name.trim().isEmpty) return hasPlayers;
  return !_isUnresolvedParticipantLabel(name);
}

bool _isUnresolvedParticipantLabel(String value) {
  final normalized = value
      .trim()
      .toUpperCase()
      .replaceAll(RegExp(r'[_-]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ');
  if (normalized.isEmpty) return true;

  const placeholders = <String>{
    'TBD',
    'TBA',
    'BYE',
    'WAITING',
    'PENDING',
    'CHỜ XÁC ĐỊNH',
    'CHO XAC DINH',
    'ĐANG CHỜ',
    'DANG CHO',
    'CHƯA XÁC ĐỊNH',
    'CHUA XAC DINH',
  };
  return placeholders.contains(normalized);
}
