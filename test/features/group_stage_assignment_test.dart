import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/entities/team.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_repository.dart';
import 'package:app_quanly_giaidau/features/bracket/screens/group_stage_assignment_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

const _tournamentId = 'assignment-tournament';
const _divisionId = 'division-a';

class _MockTournamentRepository extends Mock implements ITournamentRepository {}

class _MockManagementRepository extends Mock
    implements TournamentManagementRepository {}

Tournament _tournament() => Tournament.fromJson({
  'name': 'Giải',
  'sport': 'badminton',
  'format': 'SINGLES',
  'bracketType': 'group_stage_knockout',
  'status': 'upcoming',
  'maxTeams': 8,
  'divisions': [
    {
      'id': _divisionId,
      'name': 'Open',
      'tournamentConfig': {
        'roundConfig': {
          'groupsConfig': {
            'numGroups': 4,
            'groups': [
              {
                'name': 'A',
                'participantIds': ['team-1'],
              },
              {
                'name': 'B',
                'participantIds': ['team-2'],
              },
              {
                'name': 'C',
                'participantIds': ['team-3'],
              },
              {
                'name': 'D',
                'participantIds': ['team-4'],
              },
            ],
          },
        },
      },
    },
  ],
  'createdAt': '2026-01-01T00:00:00.000Z',
  'updatedAt': '2026-01-01T00:00:00.000Z',
}, _tournamentId);
List<Team> _teams() => [
  for (var i = 1; i <= 4; i++)
    Team(
      id: 'team-$i',
      name: 'Team $i',
      divisionId: _divisionId,
      approvalStatus: 'COMPLETE',
      createdAt: DateTime.utc(2026),
    ),
];
MatchModel _match({String status = 'scheduled'}) => MatchModel(
  id: 'match-1',
  tournamentId: _tournamentId,
  round: 1,
  matchNumber: 1,
  team1Id: 'team-1',
  team2Id: 'team-2',
  team1Name: 'Team 1',
  team2Name: 'Team 2',
  status: status,
  bracketPosition: const BracketPosition(round: 1, position: 0),
  updatedAt: DateTime.utc(2026),
  stageType: 'GROUP_STAGE',
  divisionId: _divisionId,
);
void main() {
  late _MockTournamentRepository tournamentRepo;
  late _MockManagementRepository managementRepo;
  late Map<String, dynamic> patch;
  late List<MatchModel> matches;
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });
  setUp(() {
    tournamentRepo = _MockTournamentRepository();
    managementRepo = _MockManagementRepository();
    patch = {};
    matches = [];
    when(
      () => managementRepo.updateDivisionConfig(any(), any(), any()),
    ).thenAnswer((invocation) async {
      patch = invocation.positionalArguments[2] as Map<String, dynamic>;
      return patch;
    });
    when(
      () => tournamentRepo.generateBracket(
        any(),
        divisionId: any(named: 'divisionId'),
        seedingType: any(named: 'seedingType'),
        allowReset: any(named: 'allowReset'),
      ),
    ).thenAnswer((_) async => {});
  });
  Future<void> pump(
    WidgetTester tester, {
    bool disableAnimations = false,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tournamentRepositoryProvider.overrideWithValue(tournamentRepo),
          tournamentManagementRepositoryProvider.overrideWithValue(
            managementRepo,
          ),
          tournamentProvider(
            _tournamentId,
          ).overrideWith((ref) => Stream.value(_tournament())),
          teamsProvider(
            _tournamentId,
          ).overrideWith((ref) => Stream.value(_teams())),
          bracketMatchesWithDivisionProvider((
            tournamentId: _tournamentId,
            divisionId: _divisionId,
          )).overrideWith((ref) => Stream.value(matches)),
        ],
        child: MaterialApp(
          theme: ThemeData(splashFactory: NoSplash.splashFactory),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(disableAnimations: disableAnimations),
            child: child!,
          ),
          home: const GroupStageAssignmentScreen(
            tournamentId: _tournamentId,
            divisionId: _divisionId,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  String groupLabel(WidgetTester tester, String name) => AppLocalizations.of(
    tester.element(find.byType(GroupStageAssignmentScreen)),
  )!.groupAssignmentGroupLabel(name);
  testWidgets(
    'reads saved assignment and supports reducing four groups to two',
    (tester) async {
      await pump(tester);
      expect(find.text('Team 1'), findsOneWidget);
      expect(find.text(groupLabel(tester, 'D')), findsOneWidget);
      await tester.tap(find.byKey(const Key('group-count-2')));
      await tester.pumpAndSettle();
      expect(find.text(groupLabel(tester, 'D')), findsNothing);
      expect(find.text('Team 3'), findsOneWidget);
      expect(find.text('Team 4'), findsOneWidget);
    },
  );
  testWidgets(
    'dragging inserts a team before another team in the target group',
    (tester) async {
      await pump(tester, disableAnimations: true);
      final source = tester.getCenter(find.text('Team 2'));
      final target = tester.getCenter(find.text('Team 1'));
      final gesture = await tester.startGesture(source);
      await tester.pump(kLongPressTimeout);
      await gesture.moveTo(target);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      final tiles = tester.widgetList<ListTile>(
        find.descendant(
          of: find.byKey(const Key('lane-A')),
          matching: find.byType(ListTile),
        ),
      );
      expect(tiles.map((tile) => (tile.title as Text).data), [
        'Team 2',
        'Team 1',
      ]);
    },
  );
  testWidgets('locked when group-stage match is live or completed', (
    tester,
  ) async {
    matches = [_match(status: 'live')];
    await pump(tester);
    expect(find.byKey(const Key('assignment-lock-reason')), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('save-assignment')))
          .onPressed,
      isNull,
    );
  });
  testWidgets('completed group-stage matches also lock all edits', (
    tester,
  ) async {
    matches = [_match(status: 'completed')];
    await pump(tester);
    expect(find.byKey(const Key('assignment-lock-reason')), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('save-assignment')))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<TextButton>(find.byKey(const Key('group-count-2')))
          .onPressed,
      isNull,
    );
  });
  testWidgets('rolls back draft on PATCH failure and does not generate', (
    tester,
  ) async {
    when(
      () => managementRepo.updateDivisionConfig(any(), any(), any()),
    ).thenThrow(StateError('PATCH failed'));
    await pump(tester);
    await tester.tap(find.byKey(const Key('group-count-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-assignment')));
    await tester.pumpAndSettle();
    verifyNever(
      () => tournamentRepo.generateBracket(
        any(),
        divisionId: any(named: 'divisionId'),
        seedingType: any(named: 'seedingType'),
        allowReset: any(named: 'allowReset'),
      ),
    );
    expect(find.text(groupLabel(tester, 'D')), findsOneWidget);
  });
  testWidgets(
    'PATCHes then generates for selected division when group matches are unplayed',
    (tester) async {
      matches = [_match()];
      await pump(tester);
      await tester.tap(find.byKey(const Key('save-assignment')));
      await tester.pumpAndSettle();
      verify(
        () => tournamentRepo.generateBracket(
          _tournamentId,
          divisionId: _divisionId,
          seedingType: 'RANDOM',
          allowReset: true,
        ),
      ).called(1);
      verify(
        () => managementRepo.updateDivisionConfig(
          _tournamentId,
          _divisionId,
          any(),
        ),
      ).called(1);
    },
  );
  testWidgets('keeps saved assignment when regeneration fails after PATCH', (
    tester,
  ) async {
    matches = [_match()];
    when(
      () => tournamentRepo.generateBracket(
        any(),
        divisionId: any(named: 'divisionId'),
        seedingType: any(named: 'seedingType'),
        allowReset: any(named: 'allowReset'),
      ),
    ).thenThrow(StateError('generation failed'));
    await pump(tester);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(GroupStageAssignmentScreen)),
    )!;
    await tester.tap(find.byKey(const Key('group-count-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-assignment')));
    await tester.pumpAndSettle();
    verifyInOrder([
      () => managementRepo.updateDivisionConfig(
        _tournamentId,
        _divisionId,
        any(),
      ),
      () => tournamentRepo.generateBracket(
        _tournamentId,
        divisionId: _divisionId,
        seedingType: 'RANDOM',
        allowReset: true,
      ),
    ]);
    expect(find.text(groupLabel(tester, 'D')), findsNothing);
    expect(
      find.text(
        l10n.groupAssignmentRegenerateError('Bad state: generation failed'),
      ),
      findsOneWidget,
    );
  });
  testWidgets('does not generate when no group matches exist at 360px width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pump(tester);
    await tester.tap(find.byKey(const Key('save-assignment')));
    await tester.pumpAndSettle();
    verifyNever(
      () => tournamentRepo.generateBracket(
        any(),
        divisionId: any(named: 'divisionId'),
        seedingType: any(named: 'seedingType'),
        allowReset: any(named: 'allowReset'),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
