import 'package:app_quanly_giaidau/core/participants/match_side_players.dart';
import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/features/match/widgets/viewer/live_match_details_sheet.dart';

/// Doubles when either side has two athletes (roster or players list).
bool isDoublesMatch(MatchModel match) =>
    matchSidePlayers(match, 1).length >= 2 ||
    matchSidePlayers(match, 2).length >= 2 ||
    match.team1MemberInfos.length >= 2 ||
    match.team2MemberInfos.length >= 2;

/// One side of the head-to-head card, following the team-label contract:
/// a team name is the headline with the athletes under it; with no (distinct)
/// team name the athletes are the headline. Doubles show the pair's ELO,
/// singles the athlete's own ELO (falling back to the side's ELO).
LiveEloSideData buildLiveEloSide(
  MatchModel match,
  int side, {
  required bool isDoubles,
  required String noElo,
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
    elo: elo?.toString() ?? noElo,
  );
}
