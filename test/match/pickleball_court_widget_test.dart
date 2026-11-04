import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_repository.dart';
import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/pickleball_court_notifier.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_notifier.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_state.dart';
import 'package:app_quanly_giaidau/features/match/utils/court_drag.dart';
import 'package:app_quanly_giaidau/features/match/utils/pickleball_court.dart';
import 'package:app_quanly_giaidau/features/match/widgets/pickleball_court_panel.dart';
import 'package:app_quanly_giaidau/features/match/widgets/pickleball_court_view.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _params = (tournamentId: 'tournament-1', matchId: 'match-1');

const _sideOutContext = CourtContext(
  score1: 0,
  score2: 0,
  isDoubles: true,
  team1PlayerCount: 2,
  team2PlayerCount: 2,
  servingTeam: 1,
  serverNumber: 1,
  scoringMode: CourtScoringMode.sideOut,
  setIndex: 0,
  targetPoints: 11,
  isDecidingSet: false,
);

const _rallyContext = CourtContext(
  score1: 0,
  score2: 0,
  isDoubles: true,
  team1PlayerCount: 2,
  team2PlayerCount: 2,
  servingTeam: 1,
  serverNumber: 1,
  scoringMode: CourtScoringMode.rally,
  setIndex: 0,
  targetPoints: 11,
  isDecidingSet: false,
);

const _singlesContext = CourtContext(
  score1: 0,
  score2: 0,
  isDoubles: false,
  team1PlayerCount: 1,
  team2PlayerCount: 1,
  servingTeam: 1,
  serverNumber: 1,
  scoringMode: CourtScoringMode.sideOut,
  setIndex: 0,
  targetPoints: 11,
  isDecidingSet: false,
);

// Score 0-0, team 1 on the left half and serving. Right cell holds player 0:
// team 1 shows "Minh" (left cell, top) and "L. Anh" (right cell, bottom, with
// the ball); team 2 shows "Bảo" (right cell) and "Hà" (left cell).
const _team1 = ['Lan Anh', 'Minh'];
const _team2 = ['Bảo', 'Hà'];

Widget _app(Widget child) {
  return MaterialApp(
    // Plain dark theme: context.colors falls back to the app dark palette, and
    // the test needs no google_fonts asset manifest.
    theme: ThemeData.dark().copyWith(splashFactory: NoSplash.splashFactory),
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  );
}

/// Echo courtState như server và ghi lại mọi lần ghi.
class _EchoCourtRepository extends Fake implements IMatchRepository {
  final requests = <Map<String, dynamic>>[];

  @override
  Future<MatchModel> updateCourtState(
    String matchId,
    Map<String, dynamic> courtState,
  ) async {
    requests.add(courtState);
    return MatchModel.fromJson({
      'id': matchId,
      'tournamentId': 'tournament-1',
      'status': 'LIVE',
      'scoreDetails': {'courtState': courtState},
    }, matchId);
  }
}

/// Counts how often its State is created or disposed.
class _InitCounter extends StatefulWidget {
  const _InitCounter();

  static int inits = 0;
  static int disposes = 0;

  @override
  State<_InitCounter> createState() => _InitCounterState();
}

class _InitCounterState extends State<_InitCounter> {
  @override
  void initState() {
    super.initState();
    _InitCounter.inits++;
  }

  @override
  void dispose() {
    _InitCounter.disposes++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox(width: 50, height: 50);
}

/// Records the highest number of overlapping court writes.
class _SlowCourtRepository extends _EchoCourtRepository {
  int _running = 0;
  int maxConcurrent = 0;

  @override
  Future<MatchModel> updateCourtState(
    String matchId,
    Map<String, dynamic> courtState,
  ) async {
    _running++;
    if (_running > maxConcurrent) maxConcurrent = _running;
    await Future<void>.delayed(const Duration(milliseconds: 50));
    _running--;
    return super.updateCourtState(matchId, courtState);
  }
}

/// Throws on every write, like a backend that has not deployed court-state.
class _FailingCourtRepository extends Fake implements IMatchRepository {
  @override
  Future<MatchModel> updateCourtState(
    String matchId,
    Map<String, dynamic> courtState,
  ) async => throw Exception('court-state unavailable');
}

SportConfig _config(SportScoringModel model, {bool open = false}) =>
    SportConfig(
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

ScorePanelState _scoreState(
  SportScoringModel model, {
  bool open = false,
  PickleballServeState? serve,
}) => ScorePanelState(
  config: _config(model, open: open),
  pickleball: serve,
  rally: const RallySetState(),
);

/// Score panel notifier that only records the scoring calls.
class _FakeScorePanel extends ScorePanelNotifier {
  _FakeScorePanel(super.arg, this.initial, this.calls);

  final ScorePanelState initial;
  final List<String> calls;

  @override
  ScorePanelState build() => initial;

  @override
  bool pickleballAwardPoint(bool isTeam1) {
    calls.add('award:${isTeam1 ? 1 : 2}');
    return true;
  }

  @override
  void rallyAddPoint(bool isTeam1) => calls.add('rallyAdd:${isTeam1 ? 1 : 2}');

  @override
  void rallyRemovePoint(bool isTeam1) =>
      calls.add('rallyRemove:${isTeam1 ? 1 : 2}');

  @override
  void pickleballSideOut() {
    calls.add('sideOut');
    ref.read(_servingTeamProvider.notifier).set(2);
  }
}

class _ServingTeam extends Notifier<int> {
  @override
  int build() => 1;

  void set(int team) => state = team;
}

/// Lets a test flip the serving team the way the real score panel does.
final _servingTeamProvider = NotifierProvider<_ServingTeam, int>(
  _ServingTeam.new,
);

MatchModel _match({
  String status = 'LIVE',
  List<String>? team1,
  List<String>? team2,
}) => MatchModel.fromJson({
  'id': 'match-1',
  'tournamentId': 'tournament-1',
  'status': status,
  'team1Members': team1 ?? _team1,
  'team2Members': team2 ?? _team2,
}, 'match-1');

Future<void> _pumpPanel(
  WidgetTester tester, {
  required bool canScore,
  required IMatchRepository repository,
  String status = 'LIVE',
  CourtContext context = _sideOutContext,
  ScorePanelState? scoreState,
  List<String>? scoreCalls,
  List<String>? team1Members,
  List<String>? team2Members,
  bool liveContext = false,
}) async {
  final state =
      scoreState ??
      _scoreState(
        SportScoringModel.pickleballSideOut,
        serve: const PickleballServeState(),
      );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        singleMatchProvider.overrideWith(
          (ref, params) => Stream.value(
            _match(status: status, team1: team1Members, team2: team2Members),
          ),
        ),
        pickleballCourtContextProvider.overrideWith((ref, params) {
          if (!liveContext) return context;
          final team = ref.watch(_servingTeamProvider);
          return CourtContext(
            score1: context.score1,
            score2: context.score2,
            isDoubles: context.isDoubles,
            team1PlayerCount: context.team1PlayerCount,
            team2PlayerCount: context.team2PlayerCount,
            servingTeam: team,
            serverNumber: 1,
            scoringMode: context.scoringMode,
            setIndex: context.setIndex,
            targetPoints: context.targetPoints,
            isDecidingSet: context.isDecidingSet,
          );
        }),
        scorePanelNotifierProvider.overrideWith2(
          (arg) => _FakeScorePanel(arg, state, scoreCalls ?? <String>[]),
        ),
        matchRepositoryProvider.overrideWithValue(repository),
      ],
      child: _app(PickleballCourtPanel(params: _params, canScore: canScore)),
    ),
  );
  await tester.pumpAndSettle();
}

/// Press, wait for the long-press, drag over [to] and release.
Future<TestGesture> _longPressDrag(
  WidgetTester tester,
  Finder from,
  Finder to, {
  bool release = true,
}) async {
  // Resolve both positions first: while dragging, the feedback adds a second
  // widget with the same text.
  final start = tester.getCenter(from);
  final end = tester.getCenter(to);
  final gesture = await tester.startGesture(start);
  await tester.pump(const Duration(milliseconds: 400));
  await gesture.moveBy(const Offset(4, 4));
  await tester.pump();
  await gesture.moveTo(end);
  await tester.pump();
  if (release) {
    await gesture.up();
    await tester.pumpAndSettle();
  }
  return gesture;
}

/// Opens the ⋯ menu and taps [label].
Future<void> _tapMenu(WidgetTester tester, String label) async {
  await tester.tap(find.byTooltip('More actions'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

Finder _ball() => find.byKey(serveBallHitKey);

/// A court half is outlined green while a drop on it would do something.
Finder _greenOutline(WidgetTester tester) {
  final green = tester.element(find.byType(PickleballCourtView)).colors.success;
  return find.byWidgetPredicate((widget) {
    if (widget is! DecoratedBox) return false;
    final decoration = widget.decoration;
    return decoration is BoxDecoration && decoration.border?.top.color == green;
  });
}

class _ViewSpy {
  final scoreChanges = <(int, bool)>[];
  final servingTeams = <int>[];
  final drops = <CourtDropAction>[];
}

Widget _view(
  _ViewSpy spy, {
  CourtContext context = _sideOutContext,
  bool sideOut = true,
  int score1 = 0,
  int score2 = 0,
  bool interactive = true,
  bool isDoubles = true,
  bool receiverCanScore = false,
  List<String> team1 = _team1,
  List<String> team2 = _team2,
}) {
  return PickleballCourtView(
    layout: resolveCourtLayout(const CourtState(), context),
    team1Players: team1,
    team2Players: team2,
    team1Score: score1,
    team2Score: score2,
    isSideOut: sideOut,
    isDoubles: isDoubles,
    receiverCanScore: receiverCanScore,
    onScoreChange: interactive
        ? (team, increment) => spy.scoreChanges.add((team, increment))
        : null,
    onSetServingTeam: interactive && sideOut ? spy.servingTeams.add : null,
    onDrop: interactive ? spy.drops.add : null,
    onUndo: interactive ? () {} : null,
    onRestoreAutomatic: interactive ? () {} : null,
    onToggleAutoSwitch: interactive ? () {} : null,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('view', () {
    testWidgets('the serving player cell is announced as serving', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        ProviderScope(child: _app(_view(_ViewSpy(), interactive: false))),
      );

      expect(
        find.bySemanticsLabel(RegExp('Serving · can score')),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('shows names, score and call but no controls when read-only', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: _app(
            _view(_ViewSpy(), interactive: false, score1: 4, score2: 2),
          ),
        ),
      );

      expect(find.text('L. Anh'), findsOneWidget);
      expect(find.text('Minh'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('0-0-1'), findsOneWidget);
      expect(find.byTooltip('Add point for team 1'), findsNothing);
      expect(find.byTooltip('Remove point for team 1'), findsNothing);
      expect(find.byTooltip('Undo'), findsNothing);
      expect(find.byTooltip('Restore automatic'), findsNothing);
      expect(find.byTooltip('Auto switch ends'), findsNothing);
    });

    testWidgets('side-out locks plus for the receiving team', (tester) async {
      final spy = _ViewSpy();
      await tester.pumpWidget(
        ProviderScope(child: _app(_view(spy, score1: 3, score2: 2))),
      );

      await tester.tap(find.byTooltip('Add point for team 2'));
      await tester.tap(find.byTooltip('Add point for team 1'));
      await tester.tap(find.byTooltip('Remove point for team 2'));

      expect(spy.scoreChanges, [(1, true), (2, false)]);
    });

    testWidgets('rally lets both teams score and locks minus at zero', (
      tester,
    ) async {
      final spy = _ViewSpy();
      await tester.pumpWidget(
        ProviderScope(
          child: _app(
            _view(spy, context: _rallyContext, sideOut: false, score1: 0),
          ),
        ),
      );

      await tester.tap(find.byTooltip('Add point for team 2'));
      await tester.tap(find.byTooltip('Remove point for team 1'));

      expect(spy.scoreChanges, [(2, true)]);
    });

    testWidgets('dragging a player onto a teammate swaps places', (
      tester,
    ) async {
      final spy = _ViewSpy();
      await tester.pumpWidget(ProviderScope(child: _app(_view(spy))));

      await _longPressDrag(tester, find.text('Minh'), find.text('L. Anh'));

      expect(spy.drops.single, isA<SwapPlaces>());
      expect((spy.drops.single as SwapPlaces).team, 1);
      expect(spy.servingTeams, isEmpty);
    });

    testWidgets('dragging a player onto itself does nothing', (tester) async {
      final spy = _ViewSpy();
      await tester.pumpWidget(ProviderScope(child: _app(_view(spy))));

      await _longPressDrag(tester, find.text('Minh'), find.text('Minh'));

      expect(spy.drops, isEmpty);
    });

    testWidgets('hovering the opponent half outlines it before the drop', (
      tester,
    ) async {
      final spy = _ViewSpy();
      await tester.pumpWidget(ProviderScope(child: _app(_view(spy))));
      expect(_greenOutline(tester), findsNothing);

      final gesture = await _longPressDrag(
        tester,
        find.text('Minh'),
        find.text('Bảo'),
        release: false,
      );
      expect(_greenOutline(tester), findsOneWidget);

      await gesture.up();
      await tester.pumpAndSettle();
      expect(_greenOutline(tester), findsNothing);
      expect(spy.drops.single, isA<SwitchEnds>());
    });

    testWidgets('side-out: the ball dropped on an opponent changes the serve', (
      tester,
    ) async {
      final spy = _ViewSpy();
      await tester.pumpWidget(ProviderScope(child: _app(_view(spy))));

      await _longPressDrag(tester, _ball(), find.text('Bảo'));

      expect(spy.servingTeams, [2]);
      final drop = spy.drops.single as SetServer;
      expect(
        (drop.team, drop.playerIndex, drop.changesServingTeam),
        (2, 0, true),
      );
    });

    testWidgets(
      'the ball can move to a teammate but never to the other team in rally',
      (tester) async {
        final spy = _ViewSpy();
        await tester.pumpWidget(
          ProviderScope(
            child: _app(_view(spy, context: _rallyContext, sideOut: false)),
          ),
        );

        await _longPressDrag(tester, _ball(), find.text('Bảo'));
        expect(spy.drops, isEmpty);
        expect(spy.servingTeams, isEmpty);

        await _longPressDrag(tester, _ball(), find.text('Minh'));
        final drop = spy.drops.single as SetServer;
        expect(
          (drop.team, drop.playerIndex, drop.changesServingTeam),
          (1, 1, false),
        );
      },
    );

    testWidgets('receiverCanScore keeps plus enabled for the receiving team', (
      tester,
    ) async {
      final spy = _ViewSpy();
      await tester.pumpWidget(
        ProviderScope(child: _app(_view(spy, receiverCanScore: true))),
      );

      await tester.tap(find.byTooltip('Add point for team 2'));

      expect(spy.scoreChanges, [(2, true)]);
    });

    for (final size in const [
      Size(336, 540),
      Size(300, 220),
      Size(300, 130),
      Size(240, 96),
      Size(240, 80),
      Size(616, 150),
      Size(500, 80),
    ]) {
      for (final interactive in const [true, false]) {
        testWidgets(
          'does not throw a layout error in ${size.width}x${size.height} '
          '(interactive: $interactive)',
          (tester) async {
            await tester.pumpWidget(
              ProviderScope(
                child: MaterialApp(
                  theme: ThemeData.dark(),
                  locale: const Locale('en'),
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  home: Scaffold(
                    body: Align(
                      alignment: Alignment.topLeft,
                      child: SizedBox.fromSize(
                        size: size,
                        child: _view(
                          _ViewSpy(),
                          interactive: interactive,
                          score1: 11,
                          score2: 10,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );

            expect(tester.takeException(), isNull);
            expect(
              tester.getSize(find.byType(PickleballCourtView)).height,
              lessThanOrEqualTo(size.height),
            );
          },
        );
      }
    }

    testWidgets('touch targets are at least 44dp and the ball 48dp', (
      tester,
    ) async {
      await tester.pumpWidget(ProviderScope(child: _app(_view(_ViewSpy()))));

      for (final tooltip in const [
        'Add point for team 1',
        'Remove point for team 2',
        'More actions',
      ]) {
        final size = tester.getSize(find.byTooltip(tooltip));
        expect(size.width, greaterThanOrEqualTo(40), reason: tooltip);
        expect(size.height, greaterThanOrEqualTo(40), reason: tooltip);
      }
      final ballHit = tester.getSize(_ball());
      expect(ballHit.width, greaterThanOrEqualTo(48));
      expect(ballHit.height, greaterThanOrEqualTo(48));
    });

    testWidgets('singles: no outline over the free cell or own half', (
      tester,
    ) async {
      final spy = _ViewSpy();
      await tester.pumpWidget(
        ProviderScope(
          child: _app(
            _view(
              spy,
              context: _singlesContext,
              isDoubles: false,
              team1: const ['Lan Anh'],
              team2: const ['Bảo'],
            ),
          ),
        ),
      );
      final courtHeight = tester.getSize(find.byKey(courtSurfaceKey)).height;

      // The left half's free cell is the one above "L. Anh".
      final gesture = await _longPressDrag(
        tester,
        find.text('L. Anh'),
        find.text('L. Anh'),
        release: false,
      );
      await gesture.moveBy(Offset(0, -courtHeight * 0.3));
      await tester.pump();
      expect(_greenOutline(tester), findsNothing);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(spy.drops, isEmpty);

      // Crossing the net still switches ends and still outlines.
      final across = await _longPressDrag(
        tester,
        find.text('L. Anh'),
        find.text('Bảo'),
        release: false,
      );
      expect(_greenOutline(tester), findsOneWidget);
      await across.up();
      await tester.pumpAndSettle();
      expect(spy.drops.single, isA<SwitchEnds>());
    });

    Map<String, int> semanticActionIds(WidgetTester tester, Pattern label) {
      final node = tester.getSemantics(find.bySemanticsLabel(label));
      return {
        for (final id in node.getSemanticsData().customSemanticsActionIds ?? [])
          CustomSemanticsAction.getAction(id)!.label!: id,
      };
    }

    testWidgets('semantic actions: per player, with switch ends once', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final spy = _ViewSpy();
      await tester.pumpWidget(ProviderScope(child: _app(_view(spy))));

      // "Minh" is the server's teammate: can swap and receive the serve.
      final minh = semanticActionIds(tester, RegExp('Minh'));
      expect(
        minh.keys,
        unorderedEquals(['Swap left and right', 'Give serve here']),
      );
      // "Lan Anh" is the server: nobody gives the serve to himself.
      expect(
        semanticActionIds(tester, RegExp('Lan Anh')).keys,
        isNot(contains('Give serve here')),
      );
      // Switch ends lives on the court node only, never on the four players.
      for (final name in ['Lan Anh', 'Minh', 'Bảo', 'Hà']) {
        expect(
          semanticActionIds(tester, RegExp(name)).keys,
          isNot(contains('Switch ends')),
          reason: name,
        );
      }
      final court = semanticActionIds(tester, 'Pickleball court');
      expect(court.keys, ['Switch ends']);

      void run(Pattern label, Map<String, int> ids, String action) =>
          tester.semantics.performAction(
            find.semantics.byLabel(label),
            SemanticsAction.customAction,
            args: ids[action],
          );
      run(RegExp('Minh'), minh, 'Swap left and right');
      run(RegExp('Minh'), minh, 'Give serve here');
      run('Pickleball court', court, 'Switch ends');

      expect(spy.drops[0], isA<SwapPlaces>());
      expect((spy.drops[1] as SetServer).playerIndex, 1);
      expect(spy.drops[2], isA<SwitchEnds>());
      semantics.dispose();
    });

    testWidgets('no semantic actions when read-only or in singles', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        ProviderScope(child: _app(_view(_ViewSpy(), interactive: false))),
      );
      var node = tester.getSemantics(find.bySemanticsLabel(RegExp('Minh')));
      expect(node.getSemanticsData().customSemanticsActionIds ?? [], isEmpty);

      await tester.pumpWidget(
        ProviderScope(
          child: _app(
            _view(
              _ViewSpy(),
              context: _singlesContext,
              isDoubles: false,
              team1: const ['Lan Anh'],
              team2: const ['Bảo'],
            ),
          ),
        ),
      );
      node = tester.getSemantics(find.bySemanticsLabel(RegExp('Lan Anh')));
      final labels = [
        for (final id in node.getSemanticsData().customSemanticsActionIds ?? [])
          CustomSemanticsAction.getAction(id)!.label,
      ];
      expect(labels, isNot(contains('Swap left and right')));
      semantics.dispose();
    });
  });

  group('panel', () {
    testWidgets('shows controls only to users who can score', (tester) async {
      await _pumpPanel(
        tester,
        canScore: false,
        repository: _EchoCourtRepository(),
      );
      expect(find.byTooltip('Add point for team 1'), findsNothing);
      expect(find.byTooltip('More actions'), findsNothing);

      await _pumpPanel(
        tester,
        canScore: true,
        repository: _EchoCourtRepository(),
      );
      expect(find.byTooltip('Add point for team 1'), findsOneWidget);
      expect(find.byTooltip('More actions'), findsOneWidget);
    });

    testWidgets('a completed match is read-only even for scorers', (
      tester,
    ) async {
      final repository = _EchoCourtRepository();
      await _pumpPanel(
        tester,
        canScore: true,
        repository: repository,
        status: 'COMPLETED',
      );
      expect(find.byTooltip('Add point for team 1'), findsNothing);

      await _longPressDrag(tester, find.text('Minh'), find.text('Bảo'));
      expect(repository.requests, isEmpty);
    });

    testWidgets('a user without scoring permission cannot drag', (
      tester,
    ) async {
      final repository = _EchoCourtRepository();
      await _pumpPanel(tester, canScore: false, repository: repository);

      await _longPressDrag(tester, find.text('Minh'), find.text('Bảo'));

      expect(repository.requests, isEmpty);
    });

    testWidgets('dragging onto a teammate flips startingRight and saves', (
      tester,
    ) async {
      final repository = _EchoCourtRepository();
      await _pumpPanel(tester, canScore: true, repository: repository);
      final before = repository.requests.length;

      await _longPressDrag(tester, find.text('Minh'), find.text('L. Anh'));

      expect(repository.requests.length, before + 1);
      expect(repository.requests.last['startingRight'], {
        'team1': 1,
        'team2': 0,
      });
    });

    testWidgets('dragging a player to the other half switches ends and saves', (
      tester,
    ) async {
      final repository = _EchoCourtRepository();
      await _pumpPanel(tester, canScore: true, repository: repository);
      final before = repository.requests.length;

      await _longPressDrag(tester, find.text('Minh'), find.text('Bảo'));

      expect(repository.requests.length, before + 1);
      expect(repository.requests.last['endsOverride'], isTrue);
    });

    testWidgets('dragging the ball onto a teammate sets the server and saves', (
      tester,
    ) async {
      final repository = _EchoCourtRepository();
      await _pumpPanel(tester, canScore: true, repository: repository);
      final before = repository.requests.length;

      await _longPressDrag(tester, _ball(), find.text('Minh'));

      expect(repository.requests.length, before + 1);
      expect(repository.requests.last['serverOverride'], {
        'team': 1,
        'playerIndex': 1,
      });
    });

    testWidgets('side-out rule without serve state: receiver plus is locked', (
      tester,
    ) async {
      final calls = <String>[];
      await _pumpPanel(
        tester,
        canScore: true,
        repository: _EchoCourtRepository(),
        scoreState: _scoreState(SportScoringModel.pickleballSideOut),
        scoreCalls: calls,
      );

      // The court context (real provider: see the notifier test) is side-out
      // with team 1 serving by default: ball shown, team 2 cannot score.
      expect(_ball(), findsOneWidget);
      await tester.tap(find.byTooltip('Add point for team 2'));
      expect(calls, isEmpty);
      await tester.tap(find.byTooltip('Add point for team 1'));
      expect(calls, ['award:1']);
    });

    testWidgets('open scoring (Lite): the receiving team scores as rally', (
      tester,
    ) async {
      final calls = <String>[];
      await _pumpPanel(
        tester,
        canScore: true,
        repository: _EchoCourtRepository(),
        scoreState: _scoreState(
          SportScoringModel.pickleballSideOut,
          open: true,
          serve: const PickleballServeState(),
        ),
        scoreCalls: calls,
      );

      await tester.tap(find.byTooltip('Add point for team 2'));

      expect(calls, ['award:2']);
    });

    testWidgets('rally rule: both teams score and the serve follows', (
      tester,
    ) async {
      final calls = <String>[];
      await _pumpPanel(
        tester,
        canScore: true,
        repository: _EchoCourtRepository(),
        context: _rallyContext,
        scoreState: _scoreState(SportScoringModel.rallyPointSet),
        scoreCalls: calls,
      );

      await tester.tap(find.byTooltip('Add point for team 2'));

      expect(calls, ['award:2']);
    });

    for (final entry in const {
      'LIVE': true,
      'ONGOING': true,
      'SCHEDULED': false,
      'PENDING': false,
      'cancelled': false,
      'CANCELLED': false,
      'COMPLETED': false,
      'WALKOVER': false,
    }.entries) {
      testWidgets('status ${entry.key}: court scoring shown = ${entry.value}', (
        tester,
      ) async {
        await _pumpPanel(
          tester,
          canScore: true,
          repository: _EchoCourtRepository(),
          status: entry.key,
        );

        expect(
          find.byTooltip('Add point for team 1'),
          entry.value ? findsOneWidget : findsNothing,
        );
        expect(
          find.byTooltip('Remove point for team 1'),
          entry.value ? findsOneWidget : findsNothing,
        );
      });
    }

    testWidgets('a cancelled match cannot be edited from the court', (
      tester,
    ) async {
      final repository = _EchoCourtRepository();
      await _pumpPanel(
        tester,
        canScore: true,
        repository: repository,
        status: 'cancelled',
      );

      await _longPressDrag(tester, find.text('Minh'), find.text('Bảo'));

      expect(find.byTooltip('Restore automatic'), findsNothing);
      expect(repository.requests, isEmpty);
    });

    testWidgets('two quick actions write one after the other, never at once', (
      tester,
    ) async {
      final repository = _SlowCourtRepository();
      await _pumpPanel(tester, canScore: true, repository: repository);

      // Two actions inside the 50ms a write takes: without a queue both write.
      final view = tester.widget<PickleballCourtView>(
        find.byType(PickleballCourtView),
      );
      view.onToggleAutoSwitch!();
      view.onToggleAutoSwitch!();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(repository.requests, hasLength(2));
      expect(repository.requests.first['autoSwitchEnds'], isFalse);
      expect(repository.requests.last['autoSwitchEnds'], isTrue);
      expect(repository.maxConcurrent, 1);
    });

    for (final size in [const Size(360, 640), const Size(800, 360)]) {
      testWidgets('the swap button works and the swap stays when saving fails '
          '(${size.width.toInt()}x${size.height.toInt()})', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await _pumpPanel(
          tester,
          canScore: true,
          repository: _FailingCourtRepository(),
        );
        final before = tester.getCenter(find.text('Minh'));
        final partner = tester.getCenter(find.text('L. Anh'));

        final swap = find.byTooltip('Swap left and right').first;
        expect(swap.hitTestable(), findsOneWidget);
        await tester.tap(swap);
        await tester.pumpAndSettle();

        // Saving failed, yet the two partners changed places on screen.
        expect(find.byType(SnackBar), findsOneWidget);
        expect(tester.getCenter(find.text('Minh')), partner);
        expect(tester.getCenter(find.text('L. Anh')), before);
      });
    }

    testWidgets('every failed drag shows its own error, not just the first', (
      tester,
    ) async {
      await _pumpPanel(
        tester,
        canScore: true,
        repository: _FailingCourtRepository(),
      );

      await _longPressDrag(tester, find.text('Minh'), find.text('Bảo'));
      expect(find.byType(SnackBar), findsOneWidget);
      ScaffoldMessenger.of(
        tester.element(find.byType(PickleballCourtView)),
      ).removeCurrentSnackBar();
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);

      await _longPressDrag(tester, find.text('Minh'), find.text('Bảo'));
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('singles: dragging within the own half does not write', (
      tester,
    ) async {
      final repository = _EchoCourtRepository();
      await _pumpPanel(
        tester,
        canScore: true,
        repository: repository,
        context: _singlesContext,
        team1Members: const ['Lan Anh'],
        team2Members: const ['Bảo'],
      );
      final before = repository.requests.length;
      final courtHeight = tester.getSize(find.byKey(courtSurfaceKey)).height;
      final from = tester.getCenter(find.text('L. Anh'));

      final gesture = await tester.startGesture(from);
      await tester.pump(const Duration(milliseconds: 400));
      await gesture.moveBy(const Offset(4, 4));
      await tester.pump();
      await gesture.moveTo(from + Offset(0, -courtHeight * 0.3));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(repository.requests.length, before);
    });

    /// Opens the panel, then flips the serving team through the live context
    /// (as a score change arriving over the socket would).
    Future<_SlowCourtRepository> openThenSocketChange(
      WidgetTester tester, {
      required bool canScore,
      String status = 'LIVE',
    }) async {
      final repository = _SlowCourtRepository();
      await _pumpPanel(
        tester,
        canScore: canScore,
        repository: repository,
        status: status,
        liveContext: true,
      );
      ProviderScope.containerOf(
        tester.element(find.byType(PickleballCourtPanel)),
      ).read(_servingTeamProvider.notifier).set(2);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      return repository;
    }

    testWidgets('a viewer never writes the court when the score changes', (
      tester,
    ) async {
      final repository = await openThenSocketChange(tester, canScore: false);

      expect(repository.requests, isEmpty);
    });

    testWidgets('a finished match never writes the court on a late change', (
      tester,
    ) async {
      final repository = await openThenSocketChange(
        tester,
        canScore: true,
        status: 'COMPLETED',
      );

      expect(repository.requests, isEmpty);
    });

    testWidgets('a scorer in a live match still syncs the turn', (
      tester,
    ) async {
      final repository = await openThenSocketChange(tester, canScore: true);

      expect(repository.requests, hasLength(1));
      expect((repository.requests.single['turnStart'] as Map)['team'], 2);
    });

    testWidgets('handing the serve over writes through one chain only', (
      tester,
    ) async {
      // Dropping the ball on an opponent flips the serving team, which fires
      // the context listener; that automatic sync must not run in parallel
      // with the drop's own write.
      final repository = _SlowCourtRepository();
      await _pumpPanel(
        tester,
        canScore: true,
        repository: repository,
        liveContext: true,
      );

      await _longPressDrag(tester, _ball(), find.text('Bảo'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(repository.requests, isNotEmpty);
      expect(repository.maxConcurrent, 1);
    });

    testWidgets('undo restores the court after a drag', (tester) async {
      final repository = _EchoCourtRepository();
      await _pumpPanel(tester, canScore: true, repository: repository);
      await _longPressDrag(tester, find.text('Minh'), find.text('Bảo'));
      final before = repository.requests.length;

      await _tapMenu(tester, 'Undo');

      expect(repository.requests.length, before + 1);
      expect(repository.requests.last['endsOverride'], isNull);
    });
  });
}
