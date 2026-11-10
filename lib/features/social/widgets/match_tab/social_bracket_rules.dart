/// Bracket types accepted by POST /social-sessions/:id/bracket (Lite engine).
const List<String> socialBracketTypes = [
  'SINGLE_ELIMINATION',
  'DOUBLE_ELIMINATION',
  'ROUND_ROBIN',
  'GROUP_STAGE_KNOCKOUT',
];

const int _minSinglesPlayers = 2;
const int _minDoublesPlayers = 4;

/// Cautious client check only; the Backend engine decides the real minimum per bracket type.
bool canSubmitBracket({
  required String matchType,
  required int selectedCount,
  required bool busy,
}) {
  if (busy) return false;
  if (matchType == 'SINGLES') return selectedCount >= _minSinglesPlayers;
  return selectedCount >= _minDoublesPlayers && selectedCount.isEven;
}
