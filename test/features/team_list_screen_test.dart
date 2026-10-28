import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/team.dart';
import 'package:app_quanly_giaidau/features/teams/screens/team_list_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _tournamentId = 'team-list-fixture';

Team _team(
  String id,
  String name, {
  List<String> members = const [],
  String status = 'COMPLETE',
}) => Team(
  id: id,
  name: name,
  members: members,
  approvalStatus: status,
  createdAt: DateTime(2026, 1, 1),
);

Future<void> _pump(WidgetTester tester, List<Team> teams) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        teamsProvider.overrideWith((ref, id) => Stream.value(teams)),
        tournamentProvider.overrideWith((ref, id) => Stream.value(null)),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const TeamListScreen(tournamentId: _tournamentId),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late AppLocalizations l10n;
  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  final teams = [
    _team('a', 'Alpha Pair', members: ['Alice Alpha', 'Anna Apex']),
    _team('b', 'Beta Pair', members: ['Bob Beta', 'Ben Bolt']),
    _team('c', 'Gamma Pair', members: ['Gus Gamma', 'Gil Gold'], status: 'PENDING'),
  ];

  testWidgets('status chips show counts and filter the list', (tester) async {
    await _pump(tester, teams);

    expect(find.text('${l10n.teamList_filterAll} 3'), findsOneWidget);
    expect(find.text('${l10n.teamList_filterApproved} 2'), findsOneWidget);
    expect(find.text('${l10n.teamList_filterPending} 1'), findsOneWidget);
    expect(find.text('Gamma Pair'), findsOneWidget);

    await tester.tap(find.text('${l10n.teamList_filterPending} 1'));
    await tester.pumpAndSettle();
    expect(find.text('Gamma Pair'), findsOneWidget);
    expect(find.text('Alpha Pair'), findsNothing);

    await tester.tap(find.text('${l10n.teamList_filterApproved} 2'));
    await tester.pumpAndSettle();
    expect(find.text('Gamma Pair'), findsNothing);
    expect(find.text('Alpha Pair'), findsOneWidget);
    expect(find.text('Beta Pair'), findsOneWidget);
  });

  testWidgets('search matches team and member names', (tester) async {
    await _pump(tester, teams);
    final field = find.widgetWithText(TextField, l10n.teamList_searchHint);

    await tester.enterText(field, 'bolt');
    await tester.pumpAndSettle();
    expect(find.text('Beta Pair'), findsOneWidget);
    expect(find.text('Alpha Pair'), findsNothing);

    await tester.enterText(field, 'zzz');
    await tester.pumpAndSettle();
    expect(find.text(l10n.teamList_noMatch), findsOneWidget);
  });

  testWidgets('long team and member names wrap to two lines', (tester) async {
    await _pump(tester, [
      _team(
        'long',
        'Very Long Pair Name That Cannot Fit On One Line Of A Phone Screen',
        members: [
          'Long Member Name One Two Three',
          'Long Member Name Four Five Six',
        ],
      ),
    ]);

    final name = tester.widget<Text>(
      find.text(
        'Very Long Pair Name That Cannot Fit On One Line Of A Phone Screen',
      ),
    );
    expect(name.maxLines, 2);
    final members = tester.widget<Text>(
      find.text(
        'Long Member Name One Two Three, Long Member Name Four Five Six',
      ),
    );
    expect(members.maxLines, 2);
  });

  testWidgets('per-team menu groups edit and delete', (tester) async {
    await _pump(tester, teams);

    expect(find.byIcon(Icons.delete_outline), findsNothing);
    await tester.tap(
      find.descendant(
        of: find.byType(TeamListTile).first,
        matching: find.byType(PopupMenuButton<String>),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(l10n.teamList_edit), findsOneWidget);
    expect(find.text(l10n.teamList_deleteConfirm), findsOneWidget);
  });

  testWidgets('no search bar when there are no teams', (tester) async {
    await _pump(tester, const []);
    expect(find.text(l10n.teamList_empty), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });
}
