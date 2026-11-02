import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/features/match/widgets/viewer/live_match_sides.dart';
import 'package:app_quanly_giaidau/features/match/widgets/viewer/live_side_avatars.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

MatchModel _match({
  String team1Name = 'TBD',
  List<MatchMemberInfo> team1 = const [],
}) {
  return MatchModel(
    id: 'm1',
    tournamentId: 't1',
    round: 1,
    matchNumber: 1,
    team1Id: 'a',
    team2Id: 'b',
    team1Name: team1Name,
    team2Name: 'TBD',
    team1MemberInfos: team1,
    status: 'SCHEDULED',
    bracketPosition: const BracketPosition(round: 1, position: 1),
    updatedAt: DateTime.utc(2026, 11, 1),
  );
}

void main() {
  testWidgets('TC-LIVEAV-01 a single-word username shows one initial', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const LiveSideAvatars(
          avatars: [LiveAvatarData(name: 'odi695')],
          diameter: 28,
        ),
      ),
    );

    expect(find.text('O'), findsOneWidget);
    expect(tester.getSize(find.byType(LiveSideAvatars)).width, 28);
  });

  testWidgets('TC-LIVEAV-02 a pair draws two overlapped avatars', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const LiveSideAvatars(
          avatars: [
            LiveAvatarData(name: 'An Nguyễn'),
            LiveAvatarData(name: 'Bình Trần'),
          ],
          diameter: 30,
        ),
      ),
    );

    expect(find.text('AN'), findsOneWidget);
    expect(find.text('BT'), findsOneWidget);
    // Second circle overlaps the first by 40%: 30 + 0.6 * 30.
    expect(
      tester.getSize(find.byType(LiveSideAvatars)).width,
      closeTo(48, 0.01),
    );
  });

  testWidgets('TC-LIVEAV-03 never draws more than two avatars', (tester) async {
    await tester.pumpWidget(
      _host(
        const LiveSideAvatars(
          avatars: [
            LiveAvatarData(name: 'A One'),
            LiveAvatarData(name: 'B Two'),
            LiveAvatarData(name: 'C Three'),
          ],
          diameter: 24,
        ),
      ),
    );

    expect(find.text('AO'), findsOneWidget);
    expect(find.text('BT'), findsOneWidget);
    expect(find.text('CT'), findsNothing);
  });

  test('TC-LIVEAV-04 matchSideAvatars: singles one, doubles two, team one', () {
    const photo = 'https://x/a.png';
    final single = _match(
      team1: [const MatchMemberInfo(fullName: 'odi695', avatarUrl: photo)],
    );
    final pair = _match(
      team1: [
        const MatchMemberInfo(fullName: 'An Nguyễn'),
        const MatchMemberInfo(fullName: 'Bình Trần', avatarUrl: photo),
      ],
    );
    final team = _match(
      team1Name: 'CLB Sài Gòn',
      team1: [
        const MatchMemberInfo(fullName: 'An Nguyễn'),
        const MatchMemberInfo(fullName: 'Bình Trần'),
      ],
    );

    final a = matchSideAvatars(single, 1);
    final b = matchSideAvatars(pair, 1);
    final c = matchSideAvatars(team, 1);

    expect(a.map((e) => e.name), ['odi695']);
    expect(a.single.url, photo);
    expect(b.map((e) => e.name), ['An Nguyễn', 'Bình Trần']);
    expect(b.last.url, photo);
    expect(c.map((e) => e.name), ['CLB Sài Gòn']);
  });

  test('TC-LIVEAV-05 matchSideAvatars: an unknown side has no photo', () {
    final a = matchSideAvatars(_match(), 1);

    expect(a.length, 1);
    expect(a.single.url, isNull);
  });
}
