import 'package:app_quanly_giaidau/core/participants/match_side_players.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/entities/standing.dart';

/// Standings for groups the API has not ranked yet: one row per participant
/// found in the matches, no stats.
List<Standing> buildFallbackStandingsFromMatches(
  List<MatchModel> matches,
  String defaultGroup,
) {
  final standingsMap = <String, Standing>{};
  for (final m in matches) {
    final grp = (m.groupName != null && m.groupName!.isNotEmpty)
        ? m.groupName!
        : defaultGroup;
    for (final side in const [1, 2]) {
      final teamId = side == 1 ? m.team1Id : m.team2Id;
      final name = matchSideTeamName(m, side);
      final players = matchSidePlayers(m, side);
      if (teamId.isEmpty ||
          name == 'BYE' ||
          (name == null && players.isEmpty)) {
        continue;
      }
      standingsMap.putIfAbsent(
        teamId,
        () => Standing(
          id: teamId,
          teamName: name ?? '',
          group: grp,
          players: players,
        ),
      );
    }
  }
  return standingsMap.values.toList();
}

/// Groups standings by group name, keeping the API rank order inside a group.
Map<String, List<Standing>> groupStandings(
  List<Standing> standings,
  String defaultGroup,
) {
  final grouped = <String, List<Standing>>{};
  for (final standing in standings) {
    final groupName = standing.group.trim().isNotEmpty
        ? standing.group.trim()
        : defaultGroup;
    grouped.putIfAbsent(groupName, () => []).add(standing);
  }
  return grouped;
}

bool isKnockoutMatch(MatchModel match) {
  final stage = '${match.stageName ?? ''} ${match.stageType ?? ''}'
      .toLowerCase();
  return stage.contains('knockout') ||
      stage.contains('playoff') ||
      stage.contains('elimination') ||
      stage.contains('loại trực tiếp') ||
      stage.contains('nhánh thắng') ||
      stage.contains('nhánh thua') ||
      stage.contains('grand final') ||
      stage.contains('semi') ||
      stage.contains('quarter');
}

/// Group-stage matches of one group, sorted by round then match number.
List<MatchModel> matchesForGroup(
  List<Standing> standings,
  String groupName,
  bool allowLegacyParticipantFallback,
  List<MatchModel> matches,
) {
  final participantIds = standings.map((s) => s.id).toSet();
  final normalizedGroupName = groupName.trim().toLowerCase();

  return matches.where((match) {
    if (match.isBye) return false;
    if (isKnockoutMatch(match)) return false;

    final matchGroup = (match.groupName ?? '').trim().toLowerCase();
    final sameGroupByName = matchGroup == normalizedGroupName;
    final sameGroupByParticipant =
        participantIds.contains(match.team1Id) &&
        participantIds.contains(match.team2Id);

    return sameGroupByName ||
        (allowLegacyParticipantFallback &&
            matchGroup.isEmpty &&
            sameGroupByParticipant);
  }).toList()..sort((a, b) {
    final roundCompare = a.round.compareTo(b.round);
    return roundCompare != 0
        ? roundCompare
        : a.matchNumber.compareTo(b.matchNumber);
  });
}

int _roundsPerLeg(int participantCount) {
  final slots = participantCount.isOdd
      ? participantCount + 1
      : participantCount;
  return (slots - 1).clamp(1, 1000);
}

int legForMatch(MatchModel match, int participantCount) {
  // Prefer the persisted encounter leg. The round-based calculation remains
  // only for legacy payloads that predate the leg field.
  if (match.leg != null && match.leg! > 0) return match.leg!;

  // Backend stores roundNumber continuously across legs (for example rounds
  // 1..3 are leg 1 and 4..6 are leg 2).
  final round = match.round < 1 ? 1 : match.round;
  return ((round - 1) ~/ _roundsPerLeg(participantCount)) + 1;
}

/// Round number restarting at 1 inside each leg ("Vòng 2" of leg 2).
int roundInLeg(MatchModel match, int participantCount) {
  final round = match.round < 1 ? 1 : match.round;
  return ((round - 1) % _roundsPerLeg(participantCount)) + 1;
}

/// "Bảng A" for a bare group code ("A"); names that already say it stay as is.
String groupDisplayName(String name, String prefix) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return prefix;
  final lower = trimmed.toLowerCase();
  if (lower.startsWith(prefix.toLowerCase()) || trimmed.length > 3) {
    return trimmed;
  }
  return '$prefix $trimmed';
}

/// Cell of the cross matrix seen from the row team: one line per set
/// ("mine-theirs"), or a single goals line for football.
class GroupMatrixCell {
  const GroupMatrixCell(this.lines, this.match);

  final List<String> lines;
  final MatchModel match;
}

(int, int)? _footballGoals(MatchModel match) {
  final football = match.scoreDetails?['football'];
  if (football is! Map) return null;
  final p1 = football['team1Goals'] ?? football['p1Goals'];
  final p2 = football['team2Goals'] ?? football['p2Goals'];
  final a = p1 is num ? p1.toInt() : int.tryParse(p1?.toString() ?? '');
  final b = p2 is num ? p2.toInt() : int.tryParse(p2?.toString() ?? '');
  if (a == null || b == null || a < 0 || b < 0) return null;
  return (a, b);
}

/// Score lines of a finished [match] from the view of the team on [side]
/// (1 | 2). Empty when the match is not finished.
List<String> matchScoreLines(MatchModel match, int side) {
  if (!match.isCompleted) return const [];
  final goals = _footballGoals(match);
  if (goals != null) {
    return [side == 1 ? '${goals.$1}-${goals.$2}' : '${goals.$2}-${goals.$1}'];
  }
  if (match.sets.isNotEmpty) {
    return [
      for (final s in match.sets)
        side == 1 ? '${s.score1}-${s.score2}' : '${s.score2}-${s.score1}',
    ];
  }
  return [
    side == 1
        ? '${match.score1}-${match.score2}'
        : '${match.score2}-${match.score1}',
  ];
}

/// `'rowId_colId'` → cell, for every match with two known sides (finished or
/// not, so unplayed cells can still open the match popup).
Map<String, GroupMatrixCell> buildMatrixCells(List<MatchModel> matches) {
  final cells = <String, GroupMatrixCell>{};
  for (final match in matches) {
    if (match.team1Id.isEmpty || match.team2Id.isEmpty) continue;
    cells['${match.team1Id}_${match.team2Id}'] = GroupMatrixCell(
      matchScoreLines(match, 1),
      match,
    );
    cells['${match.team2Id}_${match.team1Id}'] = GroupMatrixCell(
      matchScoreLines(match, 2),
      match,
    );
  }
  return cells;
}

/// The team that sits out a round in an odd-sized group, else null.
Standing? restingTeam(List<Standing> standings, List<MatchModel> roundMatches) {
  if (standings.length.isEven) return null;
  final playing = {
    for (final m in roundMatches) ...[m.team1Id, m.team2Id],
  };
  final resting = standings.where((s) => !playing.contains(s.id)).toList();
  return resting.length == 1 ? resting.first : null;
}
