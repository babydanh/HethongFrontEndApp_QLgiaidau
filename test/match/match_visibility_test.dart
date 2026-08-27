import 'package:flutter_test/flutter_test.dart';

import 'package:app_quanly_giaidau/core/utils/match_visibility.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';

MatchModel _match({
  bool isBye = false,
  bool team1IsMock = false,
  bool team2IsMock = false,
  String team1Id = 'team-1',
  String team2Id = 'team-2',
  String team1Name = 'Team One',
  String team2Name = 'Team Two',
  List<MatchMemberInfo> team1MemberInfos = const [],
  List<MatchMemberInfo> team2MemberInfos = const [],
}) {
  return MatchModel(
    id: 'match-1',
    round: 1,
    leg: null,
    matchNumber: 1,
    team1Id: team1Id,
    team2Id: team2Id,
    team1Name: team1Name,
    team2Name: team2Name,
    status: 'live',
    bracketPosition: const BracketPosition(round: 1, position: 0),
    updatedAt: DateTime(2026, 8, 27),
    isBye: isBye,
    team1IsMock: team1IsMock,
    team2IsMock: team2IsMock,
    team1MemberInfos: team1MemberInfos,
    team2MemberInfos: team2MemberInfos,
  );
}

void main() {
  test('keeps a live match with two real participants', () {
    expect(isRenderablePublicMatch(_match()), isTrue);
  });

  test('hides BYE and mock sides even when status is live', () {
    expect(isRenderablePublicMatch(_match(isBye: true)), isFalse);
    expect(isRenderablePublicMatch(_match(team2IsMock: true)), isFalse);
  });

  test('hides mock members even when team flags are absent', () {
    final match = _match(
      team1MemberInfos: const [
        MatchMemberInfo(fullName: 'Placeholder', isMock: true),
      ],
    );
    expect(isRenderablePublicMatch(match), isFalse);
  });

  test('hides unresolved participant ids and labels', () {
    expect(isRenderablePublicMatch(_match(team2Id: '')), isFalse);
    expect(isRenderablePublicMatch(_match(team2Name: 'TBD')), isFalse);
    expect(isRenderablePublicMatch(_match(team1Name: 'CHỜ XÁC ĐỊNH')), isFalse);
  });
}
