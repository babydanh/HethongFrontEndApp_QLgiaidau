import 'dart:async';

import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/entities/standing.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/stage_operations_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_repository.dart';
import 'package:app_quanly_giaidau/features/bracket/screens/bracket_view_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/stage_operations_provider.dart';
import 'package:app_quanly_giaidau/providers/standings_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _tournamentId = 't-1';
const _divisionId = 'd-1';

class _GuestAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState();
}

MatchModel _match(String id) => MatchModel.fromJson({
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

/// Shared state of the fake backend: the division's matches.
class _Backend {
  _Backend(this.matches);

  List<MatchModel> matches;
  int loads = 0;
  final calls = <String>[];
  Object? error;
  Completer<void>? gate;
}

class _FakeTournamentRepo extends Fake implements ITournamentRepository {
  _FakeTournamentRepo(this.backend);

  final _Backend backend;

  @override
  Future<Map<String, dynamic>> generateBracket(
    String tournamentId, {
    String? divisionId,
    required String seedingType,
    bool allowReset = false,
  }) async {
    backend.calls.add('generate:$tournamentId:$divisionId:$seedingType');
    await backend.gate?.future;
    if (backend.error != null) throw backend.error!;
    backend.matches = [_match('m-1')];
    return <String, dynamic>{};
  }
}

class _FakeStageOpsRepo extends Fake implements IStageOperationsRepository {
  _FakeStageOpsRepo(this.backend);

  final _Backend backend;

  @override
  Future<List<StageOpsStage>> getStages(
    String tournamentId, {
    required String divisionId,
  }) async => const [];

  @override
  Future<StageOpsCancelResult> cancelDivisionBracket(
    String tournamentId,
    String divisionId,
  ) async {
    backend.calls.add('cancel:$tournamentId:$divisionId');
    await backend.gate?.future;
    if (backend.error != null) throw backend.error!;
    backend.matches = const [];
    return const StageOpsCancelResult(cancelledStages: 2, cancelledMatches: 9);
  }
}

Tournament _tournament({
  int participants = 4,
  String bracketType = 'single_elimination',
}) => Tournament(
  id: _tournamentId,
  name: 'Fixture',
  sport: 'pickleball',
  format: 'DOUBLES',
  bracketType: bracketType,
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
      bracketType: bracketType,
      maxParticipants: 16,
      participantCount: participants,
    ),
  ],
);

Future<_Backend> _pump(
  WidgetTester tester, {
  required bool canEdit,
  List<MatchModel> matches = const [],
  int participants = 4,
  String bracketType = 'single_elimination',
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final backend = _Backend(matches);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tournamentProvider.overrideWith(
          (ref, id) => Stream.value(
            _tournament(participants: participants, bracketType: bracketType),
          ),
        ),
        bracketMatchesWithDivisionProvider.overrideWith((ref, params) {
          backend.loads++;
          return Stream.value(List<MatchModel>.of(backend.matches));
        }),
        standingsWithDivisionProvider.overrideWith(
          (ref, params) => Stream.value(const <Standing>[]),
        ),
        tournamentRepositoryProvider.overrideWithValue(
          _FakeTournamentRepo(backend),
        ),
        stageOperationsRepositoryProvider.overrideWithValue(
          _FakeStageOpsRepo(backend),
        ),
        authProvider.overrideWith(_GuestAuthNotifier.new),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: SingleChildScrollView(
            child: BracketViewScreen(
              tournamentId: _tournamentId,
              divisionId: _divisionId,
              isEmbedded: true,
              canEditBracket: canEdit,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  return backend;
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

bool _enabled(WidgetTester tester, String key) {
  final button = tester.widget<ButtonStyleButton>(find.byKey(Key(key)));
  return button.onPressed != null;
}

DioException _dio(int? status) => DioException(
  requestOptions: RequestOptions(path: '/x'),
  response: status == null
      ? null
      : Response<dynamic>(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: status,
        ),
);

void main() {
  group('TC-BRACKET-MGMT-01 create bracket', () {
    testWidgets('shows create for a manager, calls the API and reloads', (
      tester,
    ) async {
      final backend = await _pump(tester, canEdit: true);

      expect(find.byKey(const Key('bracket-mgmt-create')), findsOneWidget);
      expect(find.byKey(const Key('bracket-mgmt-delete')), findsNothing);
      final loadsBefore = backend.loads;

      await tester.tap(find.byKey(const Key('bracket-mgmt-create')));
      await _settle(tester);

      expect(backend.calls, ['generate:$_tournamentId:$_divisionId:RANDOM']);
      expect(backend.loads, greaterThan(loadsBefore));
      expect(find.text('Bracket created.'), findsOneWidget);
      // The reload brought the matches: the action now follows the bracket.
      expect(find.byKey(const Key('bracket-mgmt-delete')), findsOneWidget);
      expect(find.byKey(const Key('bracket-mgmt-create')), findsNothing);
    });

    testWidgets('group stage + knockout is created with seeded draw', (
      tester,
    ) async {
      final backend = await _pump(
        tester,
        canEdit: true,
        bracketType: 'group_stage_knockout',
      );

      await tester.tap(find.byKey(const Key('bracket-mgmt-create')));
      await _settle(tester);

      expect(backend.calls, ['generate:$_tournamentId:$_divisionId:SEEDED']);
    });

    testWidgets('is disabled below 2 participants', (tester) async {
      final backend = await _pump(tester, canEdit: true, participants: 1);

      expect(_enabled(tester, 'bracket-mgmt-create'), isFalse);
      await tester.tap(find.byKey(const Key('bracket-mgmt-create')));
      await _settle(tester);
      expect(backend.calls, isEmpty);
    });
  });

  group('TC-BRACKET-MGMT-02 double tap and errors', () {
    testWidgets('locks while the request is in flight', (tester) async {
      final backend = await _pump(tester, canEdit: true);
      backend.gate = Completer<void>();

      await tester.tap(find.byKey(const Key('bracket-mgmt-create')));
      await tester.pump();
      expect(_enabled(tester, 'bracket-mgmt-create'), isFalse);
      await tester.tap(find.byKey(const Key('bracket-mgmt-create')));
      await tester.pump();
      expect(backend.calls, hasLength(1));

      backend.gate!.complete();
      await _settle(tester);
      expect(backend.calls, hasLength(1));
    });

    testWidgets('a failed create shows the error and keeps the button', (
      tester,
    ) async {
      final backend = await _pump(tester, canEdit: true);
      backend.error = _dio(null);

      await tester.tap(find.byKey(const Key('bracket-mgmt-create')));
      await _settle(tester);

      expect(
        find.text('Connection lost or timed out. Please try again.'),
        findsOneWidget,
      );
      expect(_enabled(tester, 'bracket-mgmt-create'), isTrue);
    });
  });

  group('TC-BRACKET-MGMT-03 delete bracket', () {
    testWidgets('asks for confirmation and does nothing on cancel', (
      tester,
    ) async {
      final backend = await _pump(
        tester,
        canEdit: true,
        matches: [_match('m-1')],
      );
      expect(find.byKey(const Key('bracket-mgmt-delete')), findsOneWidget);
      expect(find.byKey(const Key('bracket-mgmt-create')), findsNothing);

      await tester.tap(find.byKey(const Key('bracket-mgmt-delete')));
      await _settle(tester);
      expect(find.text("Delete this division's bracket?"), findsOneWidget);

      await tester.tap(find.byKey(const Key('bracket-mgmt-delete-cancel')));
      await _settle(tester);

      expect(backend.calls, isEmpty);
      expect(find.byKey(const Key('bracket-mgmt-delete')), findsOneWidget);
    });

    testWidgets('deletes after confirming, then reloads to the create state', (
      tester,
    ) async {
      final backend = await _pump(
        tester,
        canEdit: true,
        matches: [_match('m-1')],
      );
      final loadsBefore = backend.loads;

      await tester.tap(find.byKey(const Key('bracket-mgmt-delete')));
      await _settle(tester);
      await tester.tap(find.byKey(const Key('bracket-mgmt-delete-confirm')));
      await _settle(tester);

      expect(backend.calls, ['cancel:$_tournamentId:$_divisionId']);
      expect(backend.loads, greaterThan(loadsBefore));
      expect(
        find.text('Bracket deleted: 2 stages, 9 matches.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('bracket-mgmt-create')), findsOneWidget);
    });

    testWidgets('explains that a started bracket cannot be deleted', (
      tester,
    ) async {
      final backend = await _pump(
        tester,
        canEdit: true,
        matches: [_match('m-1')],
      );
      backend.error = _dio(400);

      await tester.tap(find.byKey(const Key('bracket-mgmt-delete')));
      await _settle(tester);
      await tester.tap(find.byKey(const Key('bracket-mgmt-delete-confirm')));
      await _settle(tester);

      expect(
        find.text('Cannot cancel: a match has already started.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('bracket-mgmt-delete')), findsOneWidget);
    });

    testWidgets('locks while deleting', (tester) async {
      final backend = await _pump(
        tester,
        canEdit: true,
        matches: [_match('m-1')],
      );
      backend.gate = Completer<void>();

      await tester.tap(find.byKey(const Key('bracket-mgmt-delete')));
      await _settle(tester);
      await tester.tap(find.byKey(const Key('bracket-mgmt-delete-confirm')));
      await tester.pump();

      expect(_enabled(tester, 'bracket-mgmt-delete'), isFalse);
      backend.gate!.complete();
      await _settle(tester);
      expect(backend.calls, hasLength(1));
    });
  });

  group('TC-BRACKET-MGMT-04 permissions', () {
    testWidgets('hidden for a viewer without a bracket', (tester) async {
      await _pump(tester, canEdit: false);
      expect(find.byKey(const Key('bracket-mgmt-create')), findsNothing);
      expect(find.byKey(const Key('bracket-mgmt-delete')), findsNothing);
    });

    testWidgets('hidden for a viewer with a bracket', (tester) async {
      await _pump(tester, canEdit: false, matches: [_match('m-1')]);
      expect(find.byKey(const Key('bracket-mgmt-create')), findsNothing);
      expect(find.byKey(const Key('bracket-mgmt-delete')), findsNothing);
    });
  });

  group('TC-BRACKET-MGMT-05 no settings icon', () {
    testWidgets('the bar has no manage icon (divisions have their own tab)', (
      tester,
    ) async {
      await _pump(tester, canEdit: true);

      expect(find.byKey(const Key('bracket-mgmt-manage')), findsNothing);
      expect(find.byIcon(Icons.settings_outlined), findsNothing);
    });
  });
}
