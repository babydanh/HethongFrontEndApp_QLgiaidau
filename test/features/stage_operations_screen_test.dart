import 'dart:async';

import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/entities/standing.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/stage_operations_repository.dart';
import 'package:app_quanly_giaidau/features/bracket/screens/bracket_view_screen.dart';
import 'package:app_quanly_giaidau/features/bracket/screens/stage_operations_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/stage_operations_provider.dart';
import 'package:app_quanly_giaidau/providers/standings_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

const _tournamentId = 't-1';
const _divisionId = 'd-1';

const _groups = StageOpsStage(
  id: 's-1',
  name: 'Groups',
  type: 'ROUND_ROBIN',
  order: 1,
  totalMatches: 6,
  openMatches: 2,
  openGroupMatches: 2,
);
const _knockout = StageOpsStage(
  id: 's-2',
  name: 'Knockout',
  type: 'SINGLE_ELIMINATION',
  order: 2,
  totalMatches: 3,
  openMatches: 3,
);

class _FakeRepo implements IStageOperationsRepository {
  _FakeRepo(this.stages);

  List<StageOpsStage> stages;
  final calls = <String>[];
  int getStagesCalls = 0;
  Object? error;
  Object? loadError;
  Completer<void>? gate;

  Future<void> _mutate(String call) async {
    calls.add(call);
    await gate?.future;
    if (error != null) throw error!;
  }

  @override
  Future<List<StageOpsStage>> getStages(
    String tournamentId, {
    required String divisionId,
  }) async {
    getStagesCalls++;
    if (loadError != null) throw loadError!;
    return stages;
  }

  @override
  Future<void> finalizeStage(String tournamentId, String stageId) =>
      _mutate('finalize:$tournamentId:$stageId');

  @override
  Future<StageOpsAdvanceResult> advanceStandings(
    String tournamentId, {
    required String divisionId,
    required String stageId,
  }) async {
    await _mutate('advance:$tournamentId:$divisionId:$stageId');
    return const StageOpsAdvanceResult(stageCount: 1, totalMatches: 7);
  }

  @override
  Future<void> createPlayoffMatch(
    String tournamentId, {
    required String stageId,
    required String participant1Id,
    required String participant2Id,
  }) => _mutate('playoff:$stageId:$participant1Id:$participant2Id');

  @override
  Future<StageOpsCancelResult> cancelDivisionBracket(
    String tournamentId,
    String divisionId,
  ) async {
    await _mutate('cancel:$tournamentId:$divisionId');
    return const StageOpsCancelResult(
      cancelledStages: 2,
      cancelledMatches: 9,
    );
  }
}

Standing _standing(String id, String name, {int points = 3}) => Standing(
  id: id,
  teamName: name,
  group: 'A',
  played: 2,
  totalPoints: points,
  pointsFor: 5,
  pointsAgainst: 4,
);

Widget _app(Widget home, List<Override> overrides) => ProviderScope(
  overrides: overrides,
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: home,
  ),
);

Future<_FakeRepo> _pumpScreen(
  WidgetTester tester,
  List<StageOpsStage> stages, {
  List<Standing> standings = const [],
  Object? loadError,
}) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final repo = _FakeRepo(stages)..loadError = loadError;
  await tester.pumpWidget(
    _app(
      const StageOperationsScreen(
        tournamentId: _tournamentId,
        divisionId: _divisionId,
      ),
      [
        stageOperationsRepositoryProvider.overrideWithValue(repo),
        standingsWithDivisionProvider.overrideWith(
          (ref, params) => Stream.value(standings),
        ),
      ],
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  return repo;
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

Future<void> _tapKey(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(Key(key)));
  await _settle(tester);
}

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.tap(find.text(text));
  await _settle(tester);
}

bool _enabled(WidgetTester tester, String key) {
  final button = tester.widget<ButtonStyleButton>(find.byKey(Key(key)));
  return button.onPressed != null;
}

void main() {
  group('TC-STAGEOPS-07 finish a stage early', () {
    testWidgets('asks first, then calls finalize and reloads', (tester) async {
      final repo = await _pumpScreen(tester, [_groups]);

      await _tapKey(tester, 'stage-action-finish-s-1');
      expect(find.text('Finish this stage early?'), findsOneWidget);
      expect(repo.calls, isEmpty);
      expect(
        find.textContaining('2 unfinished matches will be cancelled'),
        findsOneWidget,
      );

      await _tapText(tester, 'Finish early');

      expect(repo.calls, ['finalize:t-1:s-1']);
      expect(find.text('Stage finished.'), findsOneWidget);
      expect(repo.getStagesCalls, 2);
    });

    testWidgets('backing out of the dialog never calls the repository', (
      tester,
    ) async {
      final repo = await _pumpScreen(tester, [_groups]);

      await _tapKey(tester, 'stage-action-finish-s-1');
      await _tapText(tester, 'Go back');

      expect(repo.calls, isEmpty);
    });

    testWidgets('hidden when nothing is left to cancel', (tester) async {
      await _pumpScreen(tester, [
        const StageOpsStage(
          id: 's-1',
          name: 'Groups',
          type: 'ROUND_ROBIN',
          order: 1,
          totalMatches: 6,
        ),
      ]);

      expect(find.byKey(const Key('stage-action-finish-s-1')), findsNothing);
    });

    testWidgets('hidden for a knockout stage', (tester) async {
      await _pumpScreen(tester, [_knockout]);

      expect(find.byKey(const Key('stage-action-finish-s-2')), findsNothing);
    });
  });

  group('TC-STAGEOPS-08 lock groups and advance to knockout', () {
    testWidgets('disabled with a hint while group matches are open', (
      tester,
    ) async {
      await _pumpScreen(tester, [_groups, _knockout]);

      expect(_enabled(tester, 'stage-action-advance-s-1'), isFalse);
      expect(find.text('2 group matches are still unfinished.'), findsOneWidget);
    });

    testWidgets('hidden when the division has no knockout stage', (
      tester,
    ) async {
      await _pumpScreen(tester, [_groups]);

      expect(find.byKey(const Key('stage-action-advance-s-1')), findsNothing);
    });

    testWidgets('confirmed advance posts division and stage', (tester) async {
      final repo = await _pumpScreen(tester, [
        const StageOpsStage(
          id: 's-1',
          name: 'Groups',
          type: 'ROUND_ROBIN',
          order: 1,
          totalMatches: 6,
        ),
        _knockout,
      ]);

      expect(_enabled(tester, 'stage-action-advance-s-1'), isTrue);
      await _tapKey(tester, 'stage-action-advance-s-1');
      expect(repo.calls, isEmpty);
      await _tapText(tester, 'Lock groups');

      expect(repo.calls, ['advance:t-1:d-1:s-1']);
      expect(
        find.text('Qualified teams moved into the knockout stage (7 matches).'),
        findsOneWidget,
      );
    });
  });

  group('TC-STAGEOPS-09 playoff for tied round robin teams', () {
    final tiedStandings = [
      _standing('p-1', 'Alpha'),
      _standing('p-2', 'Bravo'),
      _standing('p-3', 'Charlie', points: 6),
    ];
    const playoffStage = StageOpsStage(
      id: 's-1',
      name: 'Groups',
      type: 'ROUND_ROBIN',
      order: 1,
      playoffTiebreak: true,
      totalMatches: 3,
    );

    testWidgets('creates the match for the tied pair after confirming', (
      tester,
    ) async {
      final repo = await _pumpScreen(
        tester,
        [playoffStage],
        standings: tiedStandings,
      );

      expect(find.text('Alpha - Bravo'), findsOneWidget);
      await _tapKey(tester, 'stage-action-playoff-p-1-p-2');
      expect(repo.calls, isEmpty);
      expect(find.text('Create a playoff match?'), findsOneWidget);
      // The dialog button shares its label with the row button.
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Create playoff'),
        ),
      );
      await _settle(tester);

      expect(repo.calls, ['playoff:s-1:p-1:p-2']);
      expect(find.text('Playoff match created.'), findsOneWidget);
    });

    testWidgets('no playoff rows unless the stage settles ties by playoff', (
      tester,
    ) async {
      await _pumpScreen(
        tester,
        [
          const StageOpsStage(
            id: 's-1',
            name: 'Groups',
            type: 'ROUND_ROBIN',
            order: 1,
            totalMatches: 3,
          ),
        ],
        standings: tiedStandings,
      );

      expect(find.text('Alpha - Bravo'), findsNothing);
    });

    test('three teams level on points are not offered a playoff', () {
      final ties = findStageOpsTies([
        _standing('p-1', 'A'),
        _standing('p-2', 'B'),
        _standing('p-3', 'C'),
      ]);

      expect(ties, isEmpty);
    });
  });

  group('TC-STAGEOPS-10 cancel the division bracket', () {
    testWidgets('confirm text carries the counts, then DELETE is sent', (
      tester,
    ) async {
      final repo = await _pumpScreen(tester, [_groups, _knockout]);

      await _tapKey(tester, 'stage-action-cancel-bracket');
      expect(
        find.textContaining('cancels 2 stages and 9 matches'),
        findsOneWidget,
      );
      expect(repo.calls, isEmpty);
      await _tapText(tester, 'Confirm cancel');

      expect(repo.calls, ['cancel:t-1:d-1']);
      expect(find.text('Cancelled 2 stages and 9 matches.'), findsOneWidget);
    });

    testWidgets('disabled once a match has started', (tester) async {
      await _pumpScreen(tester, [
        const StageOpsStage(
          id: 's-1',
          name: 'Groups',
          type: 'ROUND_ROBIN',
          order: 1,
          totalMatches: 3,
          hasStartedMatch: true,
        ),
      ]);

      expect(_enabled(tester, 'stage-action-cancel-bracket'), isFalse);
      expect(
        find.text('Cannot cancel: a match has already started.'),
        findsOneWidget,
      );
    });
  });

  group('TC-STAGEOPS-11 errors and double tap', () {
    DioException http(int status, Object? data) => DioException(
      requestOptions: RequestOptions(path: '/x'),
      response: Response(
        requestOptions: RequestOptions(path: '/x'),
        statusCode: status,
        data: data,
      ),
    );

    testWidgets('a 409 shows the Backend message and reloads', (tester) async {
      final repo = await _pumpScreen(tester, [_groups]);
      repo.error = http(409, {'message': 'Stage already finished'});

      await _tapKey(tester, 'stage-action-finish-s-1');
      await _tapText(tester, 'Finish early');

      expect(find.text('Stage already finished'), findsOneWidget);
      expect(repo.getStagesCalls, 2);
    });

    testWidgets('a 409 without a message falls back to the conflict text', (
      tester,
    ) async {
      final repo = await _pumpScreen(tester, [_groups]);
      repo.error = http(409, <String, dynamic>{});

      await _tapKey(tester, 'stage-action-finish-s-1');
      await _tapText(tester, 'Finish early');

      expect(
        find.text('The data just changed. Reloaded; please check and try again.'),
        findsOneWidget,
      );
    });

    testWidgets('no response (offline or timeout) shows the network text', (
      tester,
    ) async {
      final repo = await _pumpScreen(tester, [_groups]);
      repo.error = DioException.connectionTimeout(
        timeout: const Duration(seconds: 5),
        requestOptions: RequestOptions(path: '/x'),
      );

      await _tapKey(tester, 'stage-action-finish-s-1');
      await _tapText(tester, 'Finish early');

      expect(
        find.text('Connection lost or timed out. Please try again.'),
        findsOneWidget,
      );
    });

    testWidgets('buttons lock while a request is in flight', (tester) async {
      final repo = await _pumpScreen(tester, [_groups]);
      repo.gate = Completer<void>();

      await _tapKey(tester, 'stage-action-finish-s-1');
      await _tapText(tester, 'Finish early');

      expect(_enabled(tester, 'stage-action-finish-s-1'), isFalse);
      expect(_enabled(tester, 'stage-action-cancel-bracket'), isFalse);
      expect(repo.calls, ['finalize:t-1:s-1']);

      repo.gate!.complete();
      await _settle(tester);

      expect(_enabled(tester, 'stage-action-finish-s-1'), isTrue);
      expect(repo.calls, hasLength(1));
    });

    testWidgets('a failed load offers a retry', (tester) async {
      final repo = await _pumpScreen(
        tester,
        [_groups],
        loadError: Exception('offline'),
      );
      expect(find.byKey(const Key('stage-action-retry')), findsOneWidget);
      expect(find.text('Groups'), findsNothing);

      repo.loadError = null;
      await _tapKey(tester, 'stage-action-retry');

      expect(find.text('Groups'), findsOneWidget);
    });
  });

  group('TC-STAGEOPS-12 entry point on the bracket screen', () {
    MatchModel match(String id) => MatchModel.fromJson({
      'id': id,
      'tournamentId': _tournamentId,
      'divisionId': _divisionId,
      'round': 1,
      'matchNumber': 1,
      'status': 'SCHEDULED',
      'team1Name': 'A',
      'team2Name': 'B',
      'nextMatchId': '',
      'stageType': 'SINGLE_ELIMINATION',
      'bracketPosition': {'bracket': 'winners', 'round': 1, 'position': 0},
    }, id);

    Tournament tournament() => Tournament(
      id: _tournamentId,
      name: 'Fixture',
      sport: 'pickleball',
      format: 'DOUBLES',
      bracketType: 'single_elimination',
      status: 'in_progress',
      visibility: 'PUBLIC',
      adminToken: '',
      refereeToken: '',
      viewerToken: '',
      creatorId: 'owner',
      maxTeams: 16,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      divisions: [
        TournamentDivision(
          id: _divisionId,
          name: 'Doubles',
          matchType: 'DOUBLES',
          bracketType: 'single_elimination',
          maxParticipants: 16,
          participantCount: 4,
        ),
      ],
    );

    Future<void> pumpBracket(
      WidgetTester tester, {
      required bool canEdit,
      List<MatchModel>? matches,
    }) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _app(
          // The hub provides the Scaffold when the screen is embedded.
          Scaffold(
            body: BracketViewScreen(
              tournamentId: _tournamentId,
              divisionId: _divisionId,
              isEmbedded: true,
              canEditBracket: canEdit,
            ),
          ),
          [
            tournamentProvider.overrideWith((ref, id) => Stream.value(tournament())),
            bracketMatchesWithDivisionProvider.overrideWith(
              (ref, params) => Stream.value(matches ?? [match('m-1')]),
            ),
            standingsWithDivisionProvider.overrideWith(
              (ref, params) => Stream.value(const <Standing>[]),
            ),
            stageOperationsRepositoryProvider.overrideWithValue(
              _FakeRepo([_groups]),
            ),
            authProvider.overrideWith(_GuestAuthNotifier.new),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('shown to a manager once the division has a bracket', (
      tester,
    ) async {
      await pumpBracket(tester, canEdit: true);

      expect(find.byKey(const Key('stage-operations-entry')), findsOneWidget);

      await tester.tap(find.byKey(const Key('stage-operations-entry')));
      await _settle(tester);
      expect(find.byType(StageOperationsScreen), findsOneWidget);
    });

    testWidgets('hidden for a viewer', (tester) async {
      await pumpBracket(tester, canEdit: false);

      expect(find.byKey(const Key('stage-operations-entry')), findsNothing);
    });

    testWidgets('hidden while the division has no bracket yet', (tester) async {
      await pumpBracket(tester, canEdit: true, matches: const []);

      expect(find.byKey(const Key('stage-operations-entry')), findsNothing);
    });
  });
}

class _GuestAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState();
}
