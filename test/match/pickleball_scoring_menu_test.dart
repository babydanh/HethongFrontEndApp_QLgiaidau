import 'dart:async';

import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_repository.dart';
import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/pickleball_court_notifier.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_notifier.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_state.dart';
import 'package:app_quanly_giaidau/features/match/utils/pickleball_court.dart';
import 'package:app_quanly_giaidau/features/match/widgets/pickleball_court_panel.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _params = (tournamentId: 'tournament-1', matchId: 'match-1');

SportConfig _config(SportScoringModel model, {bool open = true}) => SportConfig(
  kind: SportRuleKind.pickleball,
  scoringModel: model,
  isOpenScoring: open,
  bestOf: 3,
  setsToWin: 2,
  pointsPerSet: 11,
  mustWinByTwo: true,
  maxPoints: 0,
  tiebreakAt: 0,
);

ScorePanelState _state({
  bool lite = true,
  SportScoringModel model = SportScoringModel.pickleballSideOut,
  RallySetState rally = const RallySetState(),
  List<SetScoreData> sets = const [],
}) => ScorePanelState(
  config: _config(model, open: lite),
  isLite: lite,
  pickleball: const PickleballServeState(),
  rally: rally,
  finishedSets: sets,
);

MatchModel _savedMatch(Map<String, dynamic> matchConfig) =>
    MatchModel.fromJson({
      'id': 'match-1',
      'tournamentId': 'tournament-1',
      'status': 'LIVE',
      'sportKey': 'pickleball',
      'sportRules': {
        'mode': 'LITE',
        'kind': 'PICKLEBALL',
        'scoringModel': 'PICKLEBALL_SIDE_OUT',
      },
      'matchConfig': matchConfig,
    }, 'match-1');

const _rallyConfig = {
  'kind': 'PICKLEBALL_RALLY',
  'scoringModel': 'RALLY_POINT_SET',
};

class _ScoringRepository extends Fake implements IMatchRepository {
  _ScoringRepository({this.failure, this.gate});

  final Object? failure;
  final Completer<void>? gate;
  final calls = <SportScoringModel>[];

  @override
  Future<MatchModel> setPickleballScoring(
    String matchId,
    SportScoringModel scoringModel,
  ) async {
    calls.add(scoringModel);
    await gate?.future;
    if (failure != null) throw failure!;
    return _savedMatch(_rallyConfig);
  }

  @override
  Future<MatchModel> updateCourtState(
    String matchId,
    Map<String, dynamic> courtState,
  ) async => MatchModel.fromJson({
    'id': matchId,
    'tournamentId': 'tournament-1',
    'status': 'LIVE',
    'scoreDetails': {'courtState': courtState},
  }, matchId);
}

/// The real score panel logic started from a given state.
class _Panel extends ScorePanelNotifier {
  _Panel(super.arg, this.initial);

  final ScorePanelState initial;

  @override
  ScorePanelState build() => initial;
}

/// Records what the court menu asks of the score panel.
class _RecordingPanel extends _Panel {
  _RecordingPanel(super.arg, super.initial, this.log, {this.failure});

  final List<SportScoringModel> log;
  final Object? failure;

  @override
  Future<Object?> setPickleballScoring(SportScoringModel model) async {
    log.add(model);
    return failure;
  }
}

ProviderContainer _container(
  ScorePanelState initial,
  IMatchRepository repository,
) {
  final container = ProviderContainer(
    overrides: [
      matchRepositoryProvider.overrideWithValue(repository),
      scorePanelNotifierProvider.overrideWith2((arg) => _Panel(arg, initial)),
    ],
  );
  addTearDown(container.dispose);
  container.listen(scorePanelNotifierProvider(_params), (_, _) {});
  return container;
}

CourtContext _context() => const CourtContext(
  score1: 0,
  score2: 0,
  isDoubles: true,
  team1PlayerCount: 2,
  team2PlayerCount: 2,
  servingTeam: 1,
  serverNumber: 2,
  scoringMode: CourtScoringMode.sideOut,
  setIndex: 0,
  targetPoints: 11,
  isDecidingSet: false,
);

Future<void> _pumpPanel(
  WidgetTester tester, {
  required List<SportScoringModel> log,
  required ScorePanelState state,
  Object? failure,
}) async {
  tester.view.physicalSize = const Size(360, 700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        singleMatchProvider.overrideWith(
          (ref, params) => Stream.value(_savedMatch(const {})),
        ),
        pickleballCourtContextProvider.overrideWith(
          (ref, params) => _context(),
        ),
        scorePanelNotifierProvider.overrideWith2(
          (arg) => _RecordingPanel(arg, state, log, failure: failure),
        ),
        matchRepositoryProvider.overrideWithValue(_ScoringRepository()),
      ],
      child: MaterialApp(
        theme: ThemeData.dark().copyWith(splashFactory: NoSplash.splashFactory),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: PickleballCourtPanel(params: _params, canScore: true),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openMenu(WidgetTester tester) async {
  await tester.tap(find.byTooltip('More actions'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TC-LMT-APP-03 menu item "Scoring rule"', () {
    testWidgets('Lite at 0-0: opens a choice and sends the picked rule', (
      tester,
    ) async {
      final log = <SportScoringModel>[];
      await _pumpPanel(tester, log: log, state: _state());

      await _openMenu(tester);
      expect(find.text('Scoring rule'), findsOneWidget);
      expect(find.text('Side-out scoring'), findsOneWidget);
      await tester.tap(find.text('Scoring rule'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rally scoring'));
      await tester.pumpAndSettle();

      expect(log, [SportScoringModel.rallyPointSet]);
    });

    testWidgets('choosing the rule already in use sends nothing', (
      tester,
    ) async {
      final log = <SportScoringModel>[];
      await _pumpPanel(tester, log: log, state: _state());

      await _openMenu(tester);
      await tester.tap(find.text('Scoring rule'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Side-out scoring'));
      await tester.pumpAndSettle();

      expect(log, isEmpty);
    });

    testWidgets('Lite with a point on the open set: locked with a reason', (
      tester,
    ) async {
      final log = <SportScoringModel>[];
      await _pumpPanel(
        tester,
        log: log,
        state: _state(rally: const RallySetState(currentP1: 1)),
      );

      await _openMenu(tester);
      expect(find.text('Points already scored, cannot change'), findsOneWidget);
      await tester.tap(find.text('Scoring rule'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Rally scoring'), findsNothing);
      expect(log, isEmpty);
    });

    testWidgets('Lite with a closed set that has points: locked', (
      tester,
    ) async {
      await _pumpPanel(
        tester,
        log: <SportScoringModel>[],
        state: _state(
          sets: [SetScoreData(score1: 11, score2: 4, isFinished: true)],
        ),
      );

      await _openMenu(tester);

      expect(find.text('Points already scored, cannot change'), findsOneWidget);
    });

    testWidgets('Strict has no such item, even at 0-0', (tester) async {
      await _pumpPanel(
        tester,
        log: <SportScoringModel>[],
        state: _state(lite: false),
      );

      await _openMenu(tester);

      expect(find.text('Scoring rule'), findsNothing);
    });

    testWidgets('a failed save shows the error', (tester) async {
      await _pumpPanel(
        tester,
        log: <SportScoringModel>[],
        state: _state(),
        failure: Exception('Trận đã có điểm'),
      );

      await _openMenu(tester);
      await tester.tap(find.text('Scoring rule'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rally scoring'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });
  });

  group('TC-LMT-APP-04 ScorePanelNotifier.setPickleballScoring', () {
    test('success: the panel switches to the saved rule at once', () async {
      final repository = _ScoringRepository();
      final container = _container(_state(), repository);
      final panel = container.read(
        scorePanelNotifierProvider(_params).notifier,
      );

      final error = await panel.setPickleballScoring(
        SportScoringModel.rallyPointSet,
      );

      expect(error, isNull);
      expect(repository.calls, [SportScoringModel.rallyPointSet]);
      final state = container.read(scorePanelNotifierProvider(_params));
      expect(state.config.scoringModel, SportScoringModel.rallyPointSet);
      expect(state.isPickleballSideOut, isFalse);
      expect(state.isOpenScoring, isTrue);
    });

    test('failure: returns the error and keeps the old rule', () async {
      final repository = _ScoringRepository(failure: Exception('boom'));
      final container = _container(_state(), repository);
      final panel = container.read(
        scorePanelNotifierProvider(_params).notifier,
      );

      final error = await panel.setPickleballScoring(
        SportScoringModel.rallyPointSet,
      );

      expect(error, isA<Exception>());
      final state = container.read(scorePanelNotifierProvider(_params));
      expect(state.config.scoringModel, SportScoringModel.pickleballSideOut);
    });

    test('a second tap while sending does not send twice', () async {
      final gate = Completer<void>();
      final repository = _ScoringRepository(gate: gate);
      final container = _container(_state(), repository);
      final panel = container.read(
        scorePanelNotifierProvider(_params).notifier,
      );

      final first = panel.setPickleballScoring(SportScoringModel.rallyPointSet);
      final second = await panel.setPickleballScoring(
        SportScoringModel.rallyPointSet,
      );
      gate.complete();
      await first;

      expect(second, isNull);
      expect(repository.calls, hasLength(1));
    });

    test('once points exist the call is refused without any request', () async {
      final repository = _ScoringRepository();
      final container = _container(
        _state(rally: const RallySetState(currentP2: 2)),
        repository,
      );
      final panel = container.read(
        scorePanelNotifierProvider(_params).notifier,
      );

      await panel.setPickleballScoring(SportScoringModel.rallyPointSet);

      expect(repository.calls, isEmpty);
      expect(
        container.read(scorePanelNotifierProvider(_params)).isPickleballSideOut,
        isTrue,
      );
    });
  });

  group('TC-LMT-APP-05 ScorePanelState.hasNoPoints', () {
    test('only true when every set, open set included, is 0-0', () {
      expect(_state().hasNoPoints, isTrue);
      expect(
        _state(rally: const RallySetState(currentP1: 1)).hasNoPoints,
        isFalse,
      );
      expect(
        _state(
          sets: [SetScoreData(score1: 0, score2: 3, isFinished: true)],
        ).hasNoPoints,
        isFalse,
      );
    });
  });
}
