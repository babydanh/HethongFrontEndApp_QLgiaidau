/// Suggested setup for a new Round Robin / group-stage bracket, from the number
/// of registered teams. Same rule as the Web `getBracketQuickSuggestion`.
class BracketQuickSuggestion {
  const BracketQuickSuggestion({
    this.groups,
    this.teamsPerGroup,
    this.teamsAdvancing,
    this.roundsToPlay,
  });

  final int? groups;
  final int? teamsPerGroup;
  final int? teamsAdvancing;
  final int? roundsToPlay;
}

BracketQuickSuggestion? bracketQuickSuggestion({
  required String bracketType,
  required int participantCount,
}) {
  final count = participantCount < 0 ? 0 : participantCount;
  switch (bracketType.toUpperCase()) {
    case 'ROUND_ROBIN':
      if (count < 2) return null;
      return BracketQuickSuggestion(roundsToPlay: count <= 8 ? 1 : 2);
    case 'GROUP_STAGE_KNOCKOUT':
      if (count < 4) return null;
      final groups = _idealGroups(count);
      // The backend needs teamsAdvancing < floor(count / groups): the smallest
      // group must keep at least one eliminated team.
      final smallestGroup = count ~/ groups;
      return BracketQuickSuggestion(
        groups: groups,
        teamsPerGroup: (count + groups - 1) ~/ groups,
        teamsAdvancing: smallestGroup - 1 < 2 ? smallestGroup - 1 : 2,
      );
    default:
      return null;
  }
}

/// Aims for 4-5 teams per group.
int _idealGroups(int count) {
  if (count <= 11) return 2;
  if (count <= 15) return 3;
  if (count <= 22) return 4;
  if (count <= 30) return 6;
  if (count <= 44) return 8;
  if (count <= 64) return 12;
  return 16;
}
