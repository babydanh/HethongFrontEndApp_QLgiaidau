import 'package:app_quanly_giaidau/domain/entities/match.dart';

/// Returns true only for a match whose two sides are resolvable.
///
/// Public surfaces must not present bracket placeholders or BYEs as a
/// playable encounter. Mock participants are normally hidden because they can
/// represent unresolved bracket slots, but the backend also uses the same
/// flag for concrete display names (for example `9 - 10`).
bool isRenderablePublicMatch(
  MatchModel match, {
  bool allowMockParticipants = false,
}) {
  if (match.isBye) return false;
  if (!allowMockParticipants && (match.team1IsMock || match.team2IsMock)) {
    return false;
  }
  if (match.team1Id.trim().isEmpty || match.team2Id.trim().isEmpty) {
    return false;
  }
  if (!allowMockParticipants &&
      (match.team1MemberInfos.any((member) => member.isMock) ||
          match.team2MemberInfos.any((member) => member.isMock))) {
    return false;
  }

  return !_isUnresolvedParticipantLabel(match.team1Name) &&
      !_isUnresolvedParticipantLabel(match.team2Name);
}

/// Web public-feed parity for live matches. Concrete mock-labelled teams stay
/// visible while BYE/TBD/missing-participant rows remain hidden.
bool isRenderablePublicLiveMatch(MatchModel match) =>
    isRenderablePublicMatch(match, allowMockParticipants: true);

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
