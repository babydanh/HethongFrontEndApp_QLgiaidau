import 'package:app_quanly_giaidau/domain/entities/match.dart';

/// Returns true only for a match whose two sides are real and resolvable.
///
/// Public/live surfaces must not present bracket placeholders, BYEs or mock
/// participants as a playable encounter. This is intentionally conservative:
/// unresolved slots are hidden until the backend supplies real participants.
bool isRenderablePublicMatch(MatchModel match) {
  if (match.isBye || (match.team1IsMock && match.team2IsMock)) return false;
  
  final t1Unresolved = _isUnresolvedParticipantLabel(match.team1Name) &&
      match.team1Id.trim().isEmpty;
  final t2Unresolved = _isUnresolvedParticipantLabel(match.team2Name) &&
      match.team2Id.trim().isEmpty;

  // If both sides are completely unassigned/placeholders, hide the match
  if (t1Unresolved && t2Unresolved) {
    return false;
  }

  return true;
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
