import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/features/match/widgets/viewer/live_match_sides.dart';
import 'package:flutter_test/flutter_test.dart';

MatchModel _match({
  String team1Name = 'TBD',
  String team2Name = 'TBD',
  List<MatchMemberInfo> team1 = const [],
  List<MatchMemberInfo> team2 = const [],
  int? team1Elo,
  int? team2Elo,
}) {
  return MatchModel(
    id: 'm1',
    tournamentId: 't1',
    round: 1,
    matchNumber: 1,
    team1Id: 'a',
    team2Id: 'b',
    team1Name: team1Name,
    team2Name: team2Name,
    team1MemberInfos: team1,
    team2MemberInfos: team2,
    team1EloPoints: team1Elo,
    team2EloPoints: team2Elo,
    status: 'SCHEDULED',
    bracketPosition: const BracketPosition(round: 1, position: 1),
    updatedAt: DateTime.utc(2026, 11, 1),
  );
}

MatchMemberInfo _p(String name, {int? elo}) =>
    MatchMemberInfo(fullName: name, eloPoints: elo);

void main() {
  test('TC-LIVESIDE-01 doubles with a team name: team headline, pair under it, '
      'pair ELO', () {
    final m = _match(
      team1Name: 'CLB Sài Gòn',
      team1: [_p('An Nguyễn', elo: 1200), _p('Bình Trần', elo: 1300)],
      team1Elo: 1250,
      team2: [_p('C'), _p('D')],
    );

    final a = buildLiveEloSide(
      m,
      1,
      isDoubles: isDoublesMatch(m),
      undetermined: '?',
    );

    expect(isDoublesMatch(m), isTrue);
    expect(a.name, 'CLB Sài Gòn');
    expect(a.athletes, 'An Nguyễn / Bình Trần');
    expect(a.elo, '1250');
  });

  test('TC-LIVESIDE-02 doubles without a team name: pair is the headline, '
      'no repeated line', () {
    final m = _match(team1: [_p('An Nguyễn'), _p('Bình Trần')], team1Elo: 1250);

    final a = buildLiveEloSide(
      m,
      1,
      isDoubles: true,
      undetermined: '?',
    );

    expect(a.name, 'An Nguyễn / Bình Trần');
    expect(a.athletes, isEmpty);
  });

  test('TC-LIVESIDE-03 doubles whose team name is just the joined pair does '
      'not repeat it', () {
    final m = _match(
      team1Name: 'An Nguyễn / Bình Trần',
      team1: [_p('An Nguyễn'), _p('Bình Trần')],
    );

    final a = buildLiveEloSide(
      m,
      1,
      isDoubles: true,
      undetermined: '?',
    );

    expect(a.name, 'An Nguyễn / Bình Trần');
    expect(a.athletes, isEmpty);
    expect(a.elo, isNull);
  });

  test('TC-LIVESIDE-04 singles show the athlete and the athlete own ELO', () {
    final m = _match(
      team1: [_p('An Nguyễn', elo: 1500)],
      team2: [_p('Bình Trần')],
      team2Elo: 1400,
    );

    final a = buildLiveEloSide(
      m,
      1,
      isDoubles: isDoublesMatch(m),
      undetermined: '?',
    );
    final b = buildLiveEloSide(
      m,
      2,
      isDoubles: false,
      undetermined: '?',
    );

    expect(isDoublesMatch(m), isFalse);
    expect(a.name, 'An Nguyễn');
    expect(a.elo, '1500');
    // No own ELO on the athlete: fall back to the side ELO.
    expect(b.elo, '1400');
  });

  test('TC-LIVESIDE-05 an unknown side shows the placeholder and no ELO', () {
    final m = _match();

    final a = buildLiveEloSide(
      m,
      1,
      isDoubles: false,
      undetermined: 'TBD!',
    );

    expect(a.name, 'TBD!');
    expect(a.athletes, isEmpty);
    expect(a.elo, isNull);
  });

  test('TC-LIVESIDE-06 a single athlete keeps the photo, a pair gets two avatars', () {
    final solo = _match(
      team1: [
        const MatchMemberInfo(fullName: 'An Nguyễn', avatarUrl: 'https://x/a.png'),
      ],
    );
    final pair = _match(team1: [_p('An Nguyễn'), _p('Bình Trần')]);

    final a = buildLiveEloSide(solo, 1, isDoubles: false, undetermined: '?');
    final b = buildLiveEloSide(pair, 1, isDoubles: true, undetermined: '?');

    expect(a.avatars.map((e) => e.url), ['https://x/a.png']);
    expect(b.avatars.length, 2);
    expect(b.avatars.every((e) => e.url == null), isTrue);
  });
}
