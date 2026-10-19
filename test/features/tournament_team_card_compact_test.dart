import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/entities/team.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_team_card.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// gon-danh-sach-doi 3.1 / 3.2: doubles rows show their members up front as
// compact chips, without an expand step, and flag a missing partner.

Future<void> _pump(
  WidgetTester tester,
  Team team, {
  void Function(String? userId, String name)? onMemberTap,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('vi'),
      home: Scaffold(
        body: ListView(
          children: [
            TournamentTeamCard(
              team: team,
              isDoublesDivision: true,
              onMemberTap: onMemberTap,
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Team _pair() => Team(
  id: 'team-pair',
  name: 'Đà Nẵng Pickleball Club',
  members: const ['Võ Thành Đạt', 'Đặng Gia Khánh'],
  memberInfos: const [
    MatchMemberInfo(userId: 'user-dat', fullName: 'Võ Thành Đạt', eloPoints: 1000),
    MatchMemberInfo(userId: 'user-khanh', fullName: 'Đặng Gia Khánh', eloPoints: 1000),
  ],
  approvalStatus: 'APPROVED',
  createdAt: DateTime(2026, 1, 1),
);

void main() {
  testWidgets('doubles members show as chips without expanding', (tester) async {
    String? tappedUserId;
    await _pump(
      tester,
      _pair(),
      onMemberTap: (userId, _) => tappedUserId = userId,
    );

    expect(find.text('Võ Thành Đạt'), findsOneWidget);
    expect(find.text('Đặng Gia Khánh'), findsOneWidget);
    expect(find.textContaining('Elo'), findsNothing);
    expect(find.textContaining('Thành viên'), findsNothing);
    expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsNothing);
    expect(find.byIcon(Icons.person_add_alt_1_rounded), findsNothing);

    await tester.tap(find.text('Đặng Gia Khánh'));
    await tester.pump();
    expect(tappedUserId, 'user-khanh');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a doubles entry with one member shows an icon-only waiting slot', (
    tester,
  ) async {
    await _pump(
      tester,
      Team(
        id: 'team-solo',
        name: 'Đội của danh',
        members: const ['danh'],
        memberInfos: const [MatchMemberInfo(userId: 'user-danh', fullName: 'danh')],
        approvalStatus: 'APPROVED',
        createdAt: DateTime(2026, 1, 1),
      ),
    );

    expect(find.text('danh'), findsOneWidget);
    expect(find.byIcon(Icons.person_add_alt_1_rounded), findsOneWidget);
    expect(find.byTooltip('Chờ đồng đội'), findsOneWidget);
    expect(find.text('Chờ đồng đội'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PENDING_PARTNER status shows the waiting slot', (tester) async {
    await _pump(
      tester,
      Team(
        id: 'team-pending',
        name: 'Nguyễn A',
        members: const ['Nguyễn A'],
        approvalStatus: 'PENDING_PARTNER',
        createdAt: DateTime(2026, 1, 1),
      ),
    );

    expect(find.byIcon(Icons.person_add_alt_1_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a team without roster data shows no member chips', (
    tester,
  ) async {
    // The participants API returned `members: []`; the repository only keeps
    // a synthetic info built from the team name.
    await _pump(
      tester,
      Team(
        id: 'team-no-roster',
        name: 'Hà Nội Pickleball Team',
        memberInfos: const [
          MatchMemberInfo(fullName: 'Hà Nội Pickleball Team'),
        ],
        approvalStatus: 'COMPLETE',
        createdAt: DateTime(2026, 1, 1),
      ),
    );

    expect(find.text('Hà Nội Pickleball Team'), findsOneWidget);
    expect(find.byIcon(Icons.person_add_alt_1_rounded), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a guest chip passes no profile id', (tester) async {
    String? tapped = 'unset';
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: Scaffold(
          body: TournamentTeamCard(
            team: Team(
              id: 'team-guest',
              name: 'Hà Nội Pickleball Team',
              userId: 'organizer-1',
              members: const ['Lê Hoàng Nam', 'Phạm Đức Huy'],
              memberInfos: const [
                MatchMemberInfo(fullName: 'Lê Hoàng Nam'),
                MatchMemberInfo(fullName: 'Phạm Đức Huy'),
              ],
              approvalStatus: 'COMPLETE',
              createdAt: DateTime(2026, 1, 1),
            ),
            isTeamSport: true,
            isDoublesDivision: true,
            onMemberTap: (userId, _) => tapped = userId,
          ),
        ),
      ),
    );

    expect(find.text('Hà Nội Pickleball Team'), findsOneWidget);
    await tester.tap(find.text('Phạm Đức Huy'));
    expect(tapped, isNull);
    expect(find.byIcon(Icons.person_add_alt_1_rounded), findsNothing);
  });
}
