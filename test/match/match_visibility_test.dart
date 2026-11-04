import 'package:flutter_test/flutter_test.dart';

import 'package:app_quanly_giaidau/core/utils/match_visibility.dart';
import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
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
  List<ParticipantPlayer> team1Players = const [],
  List<ParticipantPlayer> team2Players = const [],
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
    team1Players: team1Players,
    team2Players: team2Players,
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

  // TC-VIS-01: athletes added one by one or by Excel have no team name; the
  // match JSON then carries an empty name plus the players (see
  // MatchModel.fromJson). They are real and must stay visible.
  test('TC-VIS-01 keeps a side with no team name but real players', () {
    const players = [ParticipantPlayer(slot: 1, fullName: 'Nguyen Van A')];
    final match = _match(
      team1Name: '',
      team2Name: '',
      team1Players: players,
      team2Players: [const ParticipantPlayer(slot: 1, fullName: 'Tran B')],
    );
    expect(isRenderablePublicMatch(match), isTrue);
  });

  test('TC-VIS-02 still hides a side with no name and no players', () {
    final match = _match(team1Name: '');
    expect(isRenderablePublicMatch(match), isFalse);
  });

  // TC-VIS-03/04 go through MatchModel.fromJson, the path real API data takes.
  Map<String, dynamic> side(String id, List<Map<String, dynamic>> members,
          {bool isMock = false}) =>
      {'id': id, 'teamName': null, 'isMock': isMock, 'members': members};

  Map<String, dynamic> matchJson(
    Map<String, dynamic> p1,
    Map<String, dynamic> p2,
  ) => {
    'id': 'm-json',
    'status': 'SCHEDULED',
    'roundNumber': 1,
    'participant1': p1,
    'participant2': p2,
  };

  test('TC-VIS-03 API match of athletes added one by one or by Excel is kept', () {
    final match = MatchModel.fromJson(
      matchJson(
        side('p1', [
          {'fullName': 'Nguyen Van A', 'userId': 'u1'},
        ]),
        // Guest added by Excel: no account.
        side('p2', [
          {'fullName': 'Tran Thi B'},
        ]),
      ),
      'm-json',
    );
    expect(match.team1Name, isEmpty);
    expect(isRenderablePublicMatch(match), isTrue);
  });

  test('TC-VIS-04 API match with a real mock participant stays hidden', () {
    final match = MatchModel.fromJson(
      matchJson(
        side('p1', [
          {'fullName': 'Mock A', 'userId': 'u1', 'isMock': true},
        ], isMock: true),
        side('p2', [
          {'fullName': 'Tran Thi B'},
        ]),
      ),
      'm-json',
    );
    expect(isRenderablePublicMatch(match), isFalse);
  });
}
