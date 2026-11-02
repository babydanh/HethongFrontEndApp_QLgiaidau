import 'package:app_quanly_giaidau/core/participants/match_side_players.dart';
import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/features/match/widgets/viewer/live_match_details_sheet.dart';
import 'package:app_quanly_giaidau/features/match/widgets/viewer/live_side_avatars.dart';

/// Doubles when either side has two athletes (roster or players list).
bool isDoublesMatch(MatchModel match) =>
    matchSidePlayers(match, 1).length >= 2 ||
    matchSidePlayers(match, 2).length >= 2 ||
    match.team1MemberInfos.length >= 2 ||
    match.team2MemberInfos.length >= 2;

/// One side of the head-to-head card, following the team-label contract:
/// a team name is the headline with the athletes under it; with no (distinct)
/// team name the athletes are the headline. Doubles show the pair's ELO,
/// singles the athlete's own ELO (falling back to the side's ELO). `elo` is
/// null when there is no number.
LiveEloSideData buildLiveEloSide(
  MatchModel match,
  int side, {
  required bool isDoubles,
  required String undetermined,
}) {
  final players = matchSidePlayers(match, side);
  final display = resolveParticipantDisplay(
    teamName: matchSideTeamName(match, side),
    players: players,
    teamOnly: isFootballMatch(match),
  );
  final infos = side == 1 ? match.team1MemberInfos : match.team2MemberInfos;
  final sideElo = side == 1 ? match.team1EloPoints : match.team2EloPoints;
  final memberElo = infos
      .where((m) => m.fullName.trim().isNotEmpty)
      .map((m) => m.eloPoints)
      .firstOrNull;
  final elo = isDoubles ? sideElo : (memberElo ?? sideElo);
  final label = matchSideLabel(match, side);
  return LiveEloSideData(
    name: label.isEmpty ? undetermined : label,
    athletes: display.isTeam ? players.map((p) => p.fullName).join(' / ') : '',
    elo: elo?.toString(),
    avatars: matchSideAvatars(match, side),
  );
}

/// Avatars of one side: one per athlete (two for a pair), or a single one for
/// a named team / an unknown side (initials of the label).
List<LiveAvatarData> matchSideAvatars(MatchModel match, int side) {
  final players = matchSidePlayers(match, side);
  final display = resolveParticipantDisplay(
    teamName: matchSideTeamName(match, side),
    players: players,
    teamOnly: isFootballMatch(match),
  );
  if (!display.isTeam && display.players.isNotEmpty) {
    return [
      for (final p in display.players.take(LiveSideAvatars.maxShown))
        LiveAvatarData(name: p.fullName, url: p.avatarUrl),
    ];
  }
  return [LiveAvatarData(name: matchSideLabel(match, side))];
}
