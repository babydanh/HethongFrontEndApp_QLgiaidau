import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:app_quanly_giaidau/domain/entities/team.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_team_card.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/ranking_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// public-team-roster / tab-vdv-giong-web:
// Danh sách VĐV hiển thị trực tiếp trong dòng (flat layout, không accordion),
// không có nhãn vai trò, có huy hiệu tier, bấm trực tiếp vào VĐV để mở hồ sơ.

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
    // Members without ELO in the payload look up their ranking by user id.
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        userRankingsSummaryProvider.overrideWith(
          (ref, userId) async => const <PlayerRanking>[],
        ),
      ],
      child: MaterialApp(
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
  testWidgets('doubles members show directly without expansion and open profile on tap', (
    tester,
  ) async {
    String? tappedUserId;
    await _pump(
      tester,
      _pair(),
      onMemberTap: (userId, _) => tappedUserId = userId,
    );

    // Tên đội và danh sách VĐV hiện thẳng trong thẻ, không cần mở rộng
    expect(find.text('Đà Nẵng Pickleball Club'), findsOneWidget);
    expect(find.text('Võ Thành Đạt'), findsOneWidget);
    expect(find.text('Đặng Gia Khánh'), findsOneWidget);

    // Không còn nhãn vai trò Trưởng nhóm / Thành viên
    expect(find.text('Trưởng nhóm'), findsNothing);
    expect(find.text('Thành viên'), findsNothing);

    // Bấm trực tiếp vào VĐV mở hồ sơ
    await tester.tap(find.text('Đặng Gia Khánh'));
    await tester.pump();
    expect(tappedUserId, 'user-khanh');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a doubles entry with one member shows waiting partner slot', (
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
    expect(find.text('Chờ đồng đội tham gia'), findsOneWidget);
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
    expect(find.text('Chờ đồng đội tham gia'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a team without roster data shows team title', (
    tester,
  ) async {
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

  testWidgets('tapping a guest passes no profile id', (tester) async {
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
    expect(find.text('Phạm Đức Huy'), findsOneWidget);

    // Bấm trực tiếp vào VĐV khách: không có userId nên null
    await tester.tap(find.text('Phạm Đức Huy'));
    expect(tapped, isNull);
    expect(find.byIcon(Icons.person_add_alt_1_rounded), findsNothing);
  });
}
