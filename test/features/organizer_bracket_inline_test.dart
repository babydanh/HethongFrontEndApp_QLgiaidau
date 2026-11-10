import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/entities/standing.dart';
import 'package:app_quanly_giaidau/domain/entities/team.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_repository.dart';
import 'package:app_quanly_giaidau/features/bracket/screens/bracket_view_screen.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/group_stage_view.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/match_table_row.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/playoff_double_elim_view.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/standings_provider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

const _tournamentId = 'organizer-bracket-fixture';
const _divisionId = 'division-a';

class _MockTournamentRepository extends Mock implements ITournamentRepository {}

class _MockManagementRepository extends Mock
    implements TournamentManagementRepository {}

class _GuestAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState();
}

Tournament _tournament(
  String bracketType, {
  Map<String, dynamic>? roundConfig,
}) => Tournament(
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
      roundConfig: roundConfig,
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
  bool canEdit = true,
  List<Standing> standings = const [],
  List<Team> teams = const [],
  Map<String, dynamic>? roundConfig,
  List<Override> extraOverrides = const [],
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tournamentProvider.overrideWith(
          (ref, id) =>
              Stream.value(_tournament(bracketType, roundConfig: roundConfig)),
        ),
        teamsProvider.overrideWith((ref, id) => Stream.value(teams)),
        bracketMatchesWithDivisionProvider.overrideWith(
          (ref, params) => Stream.value(matches),
        ),
        standingsWithDivisionProvider.overrideWith(
          (ref, params) => Stream.value(standings),
        ),
        ...extraOverrides,
        authProvider.overrideWith(_GuestAuthNotifier.new),
      ],
      child: MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: BracketViewScreen(
          tournamentId: _tournamentId,
          divisionId: _divisionId,
          canEditBracket: canEdit,
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
  testWidgets('TC-BRK-SCR-03 knockout: sơ đồ playoff mới, không danh sách', (
    tester,
  ) async {
    await _pumpOrganizer(
      tester,
      bracketType: 'single_elimination',
      matches: [_knockout('k1'), _knockout('k2', position: 1)],
    );

    expect(find.byType(MatchTableRow), findsNothing);
    final diagram = find.byType(PlayoffDoubleElimView);
    expect(diagram, findsOneWidget);
    expect(_diagramFrame(diagram), findsNothing);
    expect(
      tester.widget<PlayoffDoubleElimView>(diagram).matches.map((m) => m.id),
      containsAll(['k1', 'k2']),
    );
  });

  testWidgets('TC-BRK-SCR-04 double elimination: sơ đồ playoff mới đủ nhánh', (
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
    final diagram = find.byType(PlayoffDoubleElimView);
    expect(diagram, findsOneWidget);
    expect(_diagramFrame(diagram), findsNothing);
    expect(
      tester.widget<PlayoffDoubleElimView>(diagram).matches.map((m) => m.id),
      containsAll(['w1', 'l1']),
    );
  });

  testWidgets(
    'group_stage_knockout: trận vòng bảng vẫn là hàng, sơ đồ chỉ nhận knockout',
    (tester) async {
      await _pumpOrganizer(
        tester,
        bracketType: 'group_stage_knockout',
        matches: [_groupMatch('g1'), _groupMatch('g2'), _knockout('k1')],
        canEdit: false,
      );

      final scheduleTab = lookupAppLocalizations(
        const Locale('vi'),
      ).bracketView_schedule;
      await tester.tap(find.text(scheduleTab).first);
      await tester.pumpAndSettle();

      expect(find.byType(MatchTableRow), findsNWidgets(2));
      final diagram = find.byType(PlayoffDoubleElimView);
      expect(diagram, findsOneWidget);
      expect(
        tester.widget<PlayoffDoubleElimView>(diagram).matches.map((m) => m.id),
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
          .widget<PlayoffDoubleElimView>(find.byType(PlayoffDoubleElimView))
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
        canEdit: false,
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
            .widget<PlayoffDoubleElimView>(find.byType(PlayoffDoubleElimView))
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
      canEdit: false,
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
          .widget<PlayoffDoubleElimView>(find.byType(PlayoffDoubleElimView))
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
      canEdit: false,
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
  testWidgets('hiện lối quản lý phân bảng trước khi tạo sơ đồ', (tester) async {
    await _pumpOrganizer(
      tester,
      bracketType: 'group_stage_knockout',
      matches: [],
    );

    expect(
      find.byKey(const Key('group-stage-assignment-entry')),
      findsOneWidget,
    );
  });

  group('group stage management view (TC-GROUP-DND)', () {
    const standings = [
      Standing(id: 'a1', teamName: 'Đội A1', group: 'A'),
      Standing(id: 'a2', teamName: 'Đội A2', group: 'A'),
      Standing(id: 'b1', teamName: 'Đội B1', group: 'B'),
    ];
    final teams = [
      for (final id in ['a1', 'a2', 'b1'])
        Team(
          id: id,
          name: 'Đội $id',
          divisionId: _divisionId,
          approvalStatus: 'COMPLETE',
          createdAt: DateTime.utc(2026),
        ),
    ];
    const roundConfig = {
      'groupsConfig': {
        'numGroups': 2,
        'groups': [
          {
            'name': 'A',
            'participantIds': ['a1', 'a2'],
          },
          {
            'name': 'B',
            'participantIds': ['b1'],
          },
        ],
      },
    };
    final matches = [_groupMatch('g1'), _knockout('k1')];

    testWidgets(
      'TC-GROUP-DND-04 manager sees the shared view, no old tab bar',
      (tester) async {
        await _pumpOrganizer(
          tester,
          bracketType: 'group_stage_knockout',
          matches: matches,
          standings: standings,
          teams: teams,
          roundConfig: roundConfig,
        );

        final l10n = lookupAppLocalizations(const Locale('vi'));
        expect(find.byType(GroupStageView), findsOneWidget);
        expect(find.text(l10n.publicBracketTabPlayoff), findsOneWidget);
        expect(find.text(l10n.bracketView_schedule), findsNothing);
        expect(
          find.byKey(const Key('group-stage-assignment-entry')),
          findsNothing,
        );
        expect(find.byType(LongPressDraggable<String>), findsWidgets);
      },
    );

    testWidgets('TC-GROUP-DND-04b non-editor keeps the read-only tab bar', (
      tester,
    ) async {
      await _pumpOrganizer(
        tester,
        bracketType: 'group_stage_knockout',
        matches: matches,
        standings: standings,
        teams: teams,
        roundConfig: roundConfig,
        canEdit: false,
      );

      final l10n = lookupAppLocalizations(const Locale('vi'));
      expect(find.byType(GroupStageView), findsNothing);
      expect(find.text(l10n.bracketView_schedule), findsOneWidget);
    });

    testWidgets('TC-GROUP-DND-07 dropping a team saves the config', (
      tester,
    ) async {
      final tournamentRepo = _MockTournamentRepository();
      final managementRepo = _MockManagementRepository();
      registerFallbackValue(<String, dynamic>{});
      Map<String, dynamic>? patch;
      when(
        () => managementRepo.updateDivisionConfig(any(), any(), any()),
      ).thenAnswer((invocation) async {
        patch = invocation.positionalArguments[2] as Map<String, dynamic>;
        return patch!;
      });
      when(
        () => tournamentRepo.generateBracket(
          any(),
          divisionId: any(named: 'divisionId'),
          seedingType: any(named: 'seedingType'),
          allowReset: any(named: 'allowReset'),
        ),
      ).thenAnswer((_) async => {});
      await _pumpOrganizer(
        tester,
        bracketType: 'group_stage_knockout',
        matches: matches,
        standings: standings,
        teams: teams,
        roundConfig: roundConfig,
        extraOverrides: [
          tournamentRepositoryProvider.overrideWithValue(tournamentRepo),
          tournamentManagementRepositoryProvider.overrideWithValue(
            managementRepo,
          ),
        ],
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Đội A1')),
      );
      await tester.pump(kLongPressTimeout);
      await gesture.moveTo(tester.getCenter(find.text('Bảng B')));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      verify(
        () => managementRepo.updateDivisionConfig(
          _tournamentId,
          _divisionId,
          any(),
        ),
      ).called(1);
      expect(patch.toString(), contains('b1, a1'));
      verify(
        () => tournamentRepo.generateBracket(
          _tournamentId,
          divisionId: _divisionId,
          seedingType: 'RANDOM',
          allowReset: true,
        ),
      ).called(1);
    });
  });
}
