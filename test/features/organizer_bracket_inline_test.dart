import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/bracket/screens/bracket_view_screen.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/double_elim_diagram.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/match_table_row.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/single_elim_diagram.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/standings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _tournamentId = 'organizer-bracket-fixture';
const _divisionId = 'division-a';

class _GuestAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState();
}

Tournament _tournament(String bracketType) => Tournament(
  id: _tournamentId,
  name: 'Organizer bracket fixture',
  sport: 'pickleball',
  format: 'DOUBLES',
  bracketType: bracketType,
  status: 'in_progress',
  visibility: 'PUBLIC',
  adminToken: '',
  refereeToken: '',
  viewerToken: '',
  creatorId: 'fixture-owner',
  maxTeams: 16,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
  divisions: [
    TournamentDivision(
      id: _divisionId,
      name: 'Đôi Nam Nữ',
      matchType: 'DOUBLES',
      bracketType: bracketType,
      maxParticipants: 16,
      participantCount: 6,
    ),
  ],
);

MatchModel _knockout(
  String id, {
  String stageType = 'SINGLE_ELIMINATION',
  String bracket = 'winners',
  int position = 0,
}) => MatchModel.fromJson({
  'id': id,
  'tournamentId': _tournamentId,
  'divisionId': _divisionId,
  'round': 1,
  'matchNumber': position + 1,
  'status': 'SCHEDULED',
  'team1Name': 'Đội $id-A',
  'team2Name': 'Đội $id-B',
  'nextMatchId': '',
  'stageType': stageType,
  'bracketPosition': {'bracket': bracket, 'round': 1, 'position': position},
}, id);

MatchModel _groupMatch(String id) => MatchModel.fromJson({
  'id': id,
  'tournamentId': _tournamentId,
  'divisionId': _divisionId,
  'round': 1,
  'matchNumber': 1,
  'status': 'SCHEDULED',
  'team1Name': 'Đội $id-A',
  'team2Name': 'Đội $id-B',
  'nextMatchId': '',
  'stageType': 'GROUP_STAGE',
  'groupName': 'A',
  'leg': 1,
  'bracketPosition': {'bracket': 'group', 'round': 1, 'position': 0},
}, id);

Future<void> _pumpOrganizer(
  WidgetTester tester, {
  required String bracketType,
  required List<MatchModel> matches,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tournamentProvider.overrideWith(
          (ref, id) => Stream.value(_tournament(bracketType)),
        ),
        bracketMatchesWithDivisionProvider.overrideWith(
          (ref, params) => Stream.value(matches),
        ),
        standingsWithDivisionProvider.overrideWith(
          (ref, params) => Stream.value(const []),
        ),
        authProvider.overrideWith(_GuestAuthNotifier.new),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: const BracketViewScreen(
          tournamentId: _tournamentId,
          divisionId: _divisionId,
          canEditBracket: true,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _diagramFrame(Finder diagram) => find.ancestor(
  of: diagram,
  matching: find.byWidgetPredicate((w) => w is SizedBox && w.height == 420),
);

void main() {
  testWidgets('knockout: không còn danh sách trận, sơ đồ nằm trong khung 420', (
    tester,
  ) async {
    await _pumpOrganizer(
      tester,
      bracketType: 'single_elimination',
      matches: [_knockout('k1'), _knockout('k2', position: 1)],
    );

    expect(find.byType(MatchTableRow), findsNothing);
    final diagram = find.byType(SingleElimDiagram);
    expect(diagram, findsOneWidget);
    expect(_diagramFrame(diagram), findsOneWidget);
    expect(
      tester.widget<SingleElimDiagram>(diagram).matches.map((m) => m.id),
      containsAll(['k1', 'k2']),
    );
  });

  testWidgets('double elimination: dùng DoubleElimDiagram trong khung 420', (
    tester,
  ) async {
    await _pumpOrganizer(
      tester,
      bracketType: 'double_elimination',
      matches: [
        _knockout('w1', stageType: 'DOUBLE_ELIMINATION', bracket: 'winners'),
        _knockout(
          'l1',
          stageType: 'DOUBLE_ELIMINATION',
          bracket: 'losers',
          position: 1,
        ),
      ],
    );

    expect(find.byType(MatchTableRow), findsNothing);
    expect(find.byType(SingleElimDiagram), findsNothing);
    final diagram = find.byType(DoubleElimDiagram);
    expect(diagram, findsOneWidget);
    expect(_diagramFrame(diagram), findsOneWidget);
  });

  testWidgets(
    'group_stage_knockout: trận vòng bảng vẫn là hàng, sơ đồ chỉ nhận knockout',
    (tester) async {
      await _pumpOrganizer(
        tester,
        bracketType: 'group_stage_knockout',
        matches: [_groupMatch('g1'), _groupMatch('g2'), _knockout('k1')],
      );

      final scheduleTab = lookupAppLocalizations(
        const Locale('vi'),
      ).bracketView_schedule;
      await tester.tap(find.text(scheduleTab).first);
      await tester.pumpAndSettle();

      expect(find.byType(MatchTableRow), findsNWidgets(2));
      final diagram = find.byType(SingleElimDiagram);
      expect(diagram, findsOneWidget);
      expect(
        tester.widget<SingleElimDiagram>(diagram).matches.map((m) => m.id),
        ['k1'],
      );
    },
  );

  testWidgets('tìm kiếm không lọc trận trong sơ đồ knockout', (tester) async {
    await _pumpOrganizer(
      tester,
      bracketType: 'single_elimination',
      matches: [_knockout('k1'), _knockout('k2', position: 1)],
    );

    await tester.enterText(find.byType(TextField).first, 'Đội k2-A');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<SingleElimDiagram>(find.byType(SingleElimDiagram))
          .matches
          .map((m) => m.id),
      unorderedEquals(['k1', 'k2']),
    );
  });

  testWidgets(
    'tìm kiếm không khớp trận nào: knockout vẫn đủ, không có empty state',
    (tester) async {
      await _pumpOrganizer(
        tester,
        bracketType: 'group_stage_knockout',
        matches: [
          _groupMatch('g1'),
          _knockout('k1'),
          _knockout('k2', position: 1),
        ],
      );

      final l10n = lookupAppLocalizations(const Locale('vi'));
      await tester.tap(find.text(l10n.bracketView_schedule).first);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'không có đội này');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.byType(MatchTableRow), findsNothing);
      expect(
        tester
            .widget<SingleElimDiagram>(find.byType(SingleElimDiagram))
            .matches
            .map((m) => m.id),
        unorderedEquals(['k1', 'k2']),
      );
      expect(find.text(l10n.bracketView_noMatchingMatches), findsNothing);
    },
  );

  testWidgets('tìm kiếm chỉ lọc hàng vòng bảng, sơ đồ giữ đủ knockout', (
    tester,
  ) async {
    await _pumpOrganizer(
      tester,
      bracketType: 'group_stage_knockout',
      matches: [
        _groupMatch('g1'),
        _groupMatch('g2'),
        _knockout('k1'),
        _knockout('k2', position: 1),
      ],
    );

    final scheduleTab = lookupAppLocalizations(
      const Locale('vi'),
    ).bracketView_schedule;
    await tester.tap(find.text(scheduleTab).first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Đội g2-A');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.byType(MatchTableRow), findsOneWidget);
    expect(
      tester
          .widget<SingleElimDiagram>(find.byType(SingleElimDiagram))
          .matches
          .map((m) => m.id),
      unorderedEquals(['k1', 'k2']),
    );
  });

  testWidgets('không khớp và không có knockout: hiện trạng thái rỗng', (
    tester,
  ) async {
    await _pumpOrganizer(
      tester,
      bracketType: 'group_stage_knockout',
      matches: [_groupMatch('g1')],
    );

    final l10n = lookupAppLocalizations(const Locale('vi'));
    await tester.tap(find.text(l10n.bracketView_schedule).first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'không có đội này');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.byType(MatchTableRow), findsNothing);
    expect(find.text(l10n.bracketView_noMatchingMatches), findsOneWidget);
  });
}
