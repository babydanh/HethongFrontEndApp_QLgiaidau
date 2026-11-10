import 'package:app_quanly_giaidau/data/models/club_match_session_model.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';

/// Maps a social-session match to the [MatchModel] the live scoring screen and
/// the quick result dialog read. Both pick their rules from the match itself
/// (`sportKey`, `sportRules`, `tournamentConfig`), so leaving those out scores
/// every sport with the default rules. The club tab builds the same fields.
MatchModel socialSessionMatchToMatchModel(ClubSessionMatchModel sm) {
  final sideAMembers = _toMemberInfos(sm.sideAMembers);
  final sideBMembers = _toMemberInfos(sm.sideBMembers);
  final sideAName = sm.sideANames.join(' · ').trim();
  final sideBName = sm.sideBNames.join(' · ').trim();
  final status = sm.status.toUpperCase();
  final winnerId = switch (status) {
    'COMPLETED' when sm.sideAScore > sm.sideBScore => 'SIDE_A',
    'COMPLETED' when sm.sideBScore > sm.sideAScore => 'SIDE_B',
    _ => '',
  };
  final kind = sm.sportKey.isNotEmpty ? sm.sportKey : 'pickleball';
  // The API can include a placeholder for the next set: keep the current set
  // but drop trailing empty ones until somebody scores in them.
  final parsedSets = parseClubSessionScoreDetails(
    sm.scoreDetails,
  ).take(10).toList(growable: true);
  while (parsedSets.length > 1 &&
      parsedSets.last.sideAScore == 0 &&
      parsedSets.last.sideBScore == 0) {
    parsedSets.removeLast();
  }
  final displaySets = parsedSets
      .map((score) => SetScore(score1: score.sideAScore, score2: score.sideBScore))
      .toList(growable: false);

  return MatchModel(
    id: sm.id,
    isStandaloneMatch: true,
    round: 0,
    matchNumber: 1,
    team1Id: 'SIDE_A',
    team2Id: 'SIDE_B',
    team1Name: sideAName.isEmpty ? 'Đội A' : sideAName,
    team2Name: sideBName.isEmpty ? 'Đội B' : sideBName,
    score1: sm.sideAScore,
    score2: sm.sideBScore,
    sets: displaySets.isNotEmpty
        ? displaySets
        : [
            SetScore(
              score1: status == 'COMPLETED' ? sm.sideAScore : 0,
              score2: status == 'COMPLETED' ? sm.sideBScore : 0,
            ),
          ],
    winnerId: winnerId,
    loserId: switch (winnerId) {
      'SIDE_A' => 'SIDE_B',
      'SIDE_B' => 'SIDE_A',
      _ => '',
    },
    status: sm.status,
    bracketPosition: const BracketPosition(round: 1, position: 1),
    scoreDetails: sm.scoreDetails,
    team1Members: sideAMembers.map((m) => m.fullName).toList(),
    team2Members: sideBMembers.map((m) => m.fullName).toList(),
    team1MemberInfos: sideAMembers,
    team2MemberInfos: sideBMembers,
    team1LogoUrl: sideAMembers.length == 1 ? sideAMembers.first.avatarUrl : null,
    team2LogoUrl: sideBMembers.length == 1 ? sideBMembers.first.avatarUrl : null,
    eloDelta: sm.eloDelta,
    eloStatus: sm.eloStatus,
    sportKey: kind,
    tournamentConfig: sm.tournamentConfig.isNotEmpty
        ? sm.tournamentConfig
        : const {
            'isLite': true,
            'mode': 'LITE',
            'scoringMode': 'FREE',
            'maxSets': 10,
          },
    sportRules: sm.sportRules.isNotEmpty
        ? sm.sportRules
        : {
            'kind': kind,
            'mode': 'LITE',
            'scoringMode': 'FREE',
            'maxSets': 10,
          },
    revision: sm.revision,
    scheduledTime: sm.scheduledAt,
    startedAt: sm.startedAt,
    completedAt: sm.completedAt,
    updatedAt: sm.updatedAt ?? sm.createdAt ?? DateTime.now(),
  );
}

List<MatchMemberInfo> _toMemberInfos(List<ClubSessionMatchMemberModel> members) {
  return members
      .map(
        (m) => MatchMemberInfo(
          userId: m.userId,
          fullName: m.displayName,
          avatarUrl: m.avatarUrl,
          isMock: m.isMock,
        ),
      )
      .toList(growable: false);
}
