import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/participants/match_side_players.dart';
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

CourtContext _context({
  bool isDoubles = true,
  int serverNumber = 2,
  CourtScoringMode mode = CourtScoringMode.sideOut,
}) => CourtContext(
  score1: 0,
  score2: 0,
  isDoubles: isDoubles,
  team1PlayerCount: isDoubles ? 2 : 1,
  team2PlayerCount: isDoubles ? 2 : 1,
  servingTeam: 1,
  serverNumber: serverNumber,
  scoringMode: mode,
  setIndex: 0,
  targetPoints: 11,
  isDecidingSet: false,
);

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

ScorePanelState _state({
  SportScoringModel model = SportScoringModel.pickleballSideOut,
  bool lite = false,
  bool override = false,
  String reason = '',
  PickleballServeState serve = const PickleballServeState(),
}) => ScorePanelState(
  config: _config(model, open: lite),
  isLite: lite,
  pickleball: serve,
  rally: const RallySetState(currentP1: 5, currentP2: 3),
  overrideEnabled: override,
  overrideReason: reason,
);

/// Score panel whose set / match actions are scripted and recorded.
class _FakeScorePanel extends ScorePanelNotifier {
  _FakeScorePanel(
    super.arg,
    this.initial,
    this.log, {
    this.confirmMessage = 'Finish set 1 at 5-3?',
    this.completable = const {},
    this.failComplete = false,
  });

  final ScorePanelState initial;
  final List<String> log;
  final String? confirmMessage;
  final Set<int> completable;
  final bool failComplete;

  @override
  ScorePanelState build() => initial;

  @override
  String? finishSetConfirmMessage() => confirmMessage;

  @override
  Future<void> finishSet() async => log.add('finishSet');

  @override
  bool canCompleteAs(int winnerTeam) => completable.contains(winnerTeam);

  @override
  Future<void> completeMatch(int winnerTeam) async {
    log.add('complete:$winnerTeam');
    if (failComplete) state = state.copyWith(errorMessage: 'save failed');
  }

  @override
  void setOverride(bool enabled, String reason) {
    log.add('override:$enabled:$reason');
    state = state.copyWith(overrideEnabled: enabled, overrideReason: reason);
  }

  @override
  void pickleballSwitchServer() => log.add('switchServer');

  @override
  void pickleballSideOut() => log.add('sideOut');

  @override
  void rallyAddPoint(bool isTeam1) => log.add('rallyAdd:${isTeam1 ? 1 : 2}');

  @override
  bool pickleballAwardPoint(bool isTeam1) {
    log.add('award:${isTeam1 ? 1 : 2}');
    return true;
  }
}

class _EchoCourtRepository extends Fake implements IMatchRepository {
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

MatchModel _match() => MatchModel.fromJson({
  'id': 'match-1',
  'tournamentId': 'tournament-1',
  'status': 'LIVE',
  'team1Members': ['Lan Anh', 'Minh'],
  'team2Members': ['Bảo', 'Hà'],
}, 'match-1');

/// Opens the panel on a second route, like the real scoring page, so that a
/// finished match can pop it.
Future<void> _pumpPanel(
  WidgetTester tester, {
  required List<String> log,
  CourtContext? context,
  ScorePanelState? state,
  String? confirmMessage = 'Finish set 1 at 5-3?',
  Set<int> completable = const {},
  bool failComplete = false,
  bool canScore = true,
  VoidCallback? onForceWin,
  Size size = const Size(360, 700),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        singleMatchProvider.overrideWith(
          (ref, params) => Stream.value(_match()),
        ),
        pickleballCourtContextProvider.overrideWith(
          (ref, params) => context ?? _context(),
        ),
        scorePanelNotifierProvider.overrideWith2(
          (arg) => _FakeScorePanel(
            arg,
            state ?? _state(),
            log,
            confirmMessage: confirmMessage,
            completable: completable,
            failComplete: failComplete,
          ),
        ),
        matchRepositoryProvider.overrideWithValue(_EchoCourtRepository()),
      ],
      child: MaterialApp(
        theme: ThemeData.dark().copyWith(splashFactory: NoSplash.splashFactory),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => Scaffold(
                      body: PickleballCourtPanel(
                        params: _params,
                        canScore: canScore,
                        onForceWin: onForceWin,
                      ),
                    ),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

/// Opens the END dialog and taps one of its entries.
Future<void> _endChoose(WidgetTester tester, String item) async {
  await tester.tap(find.text('END'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(item));
}

Future<void> _openMenu(WidgetTester tester) async {
  await tester.tap(find.byTooltip('More actions'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TC-SERVE-APP-05 one serve button, only where serve turns exist', () {
    testWidgets('strict side-out: exactly one serve button in the bar', (tester) async {
      await _pumpPanel(tester, log: <String>[], context: _context(serverNumber: 1));

      expect(find.byTooltip('Change serve'), findsOneWidget);
      expect(find.text('LOSE SERVE'), findsNothing);
    });

    testWidgets('rally rule has none either', (tester) async {
      await _pumpPanel(
        tester,
        log: <String>[],
        context: _context(mode: CourtScoringMode.rally),
        state: _state(model: SportScoringModel.rallyPointSet),
      );

      expect(find.byTooltip('Change serve'), findsNothing);
    });

    testWidgets('Lite with side-out serve turns has it too', (tester) async {
      await _pumpPanel(tester, log: <String>[], state: _state(lite: true));

      expect(find.byTooltip('Change serve'), findsOneWidget);
    });
  });

  group('strict side-out: the receiving team winning the rally', () {
    testWidgets('doubles: plus of the receiver loses the serve step by step', (
      tester,
    ) async {
      final log = <String>[];
      await _pumpPanel(tester, log: log);

      await tester.tap(find.byTooltip('Add point for team 2'));

      // No point is awarded: the serve moves on (1 -> 2 -> other team).
      expect(log, ['switchServer']);
    });

    testWidgets('singles: plus of the receiver hands the serve over at once', (
      tester,
    ) async {
      final log = <String>[];
      await _pumpPanel(
        tester,
        log: log,
        context: _context(isDoubles: false, serverNumber: 1),
      );

      await tester.tap(find.byTooltip('Add point for team 2'));

      expect(log, ['sideOut']);
    });

    testWidgets('plus of the serving team still awards the point', (
      tester,
    ) async {
      final log = <String>[];
      await _pumpPanel(tester, log: log);

      await tester.tap(find.byTooltip('Add point for team 1'));

      expect(log, ['award:1']);
    });
  });

  group('TC-CBD-PB receiver plus = serving team lost the rally', () {
    const secondDone = PickleballServeState(serverNumber: 1, openingDone: true);
    const serverTwo = PickleballServeState(serverNumber: 2, openingDone: true);

    testWidgets('TC-CBD-PB-01 doubles, server 1: the receiver plus moves the '
        'serve to server 2', (tester) async {
      final log = <String>[];
      await _pumpPanel(
        tester,
        log: log,
        context: _context(serverNumber: 1),
        state: _state(serve: secondDone),
      );

      await tester.tap(find.byTooltip('Add point for team 2'));
      await tester.pump();

      expect(log, ['switchServer']);
      expect(
        find.textContaining('won the rally'),
        findsNothing,
        reason: 'no toast: it floated over the lower "+" button',
      );
    });

    testWidgets('TC-CBD-PB-02 doubles, server 2: the receiver plus hands the '
        'serve over, no toast', (tester) async {
      final log = <String>[];
      await _pumpPanel(
        tester,
        log: log,
        state: _state(serve: serverTwo),
      );

      await tester.tap(find.byTooltip('Add point for team 2'));
      await tester.pump();

      expect(log, ['switchServer']);
      expect(
        find.textContaining('won the rally'),
        findsNothing,
        reason: 'no toast: it floated over the lower "+" button',
      );
    });

    testWidgets('TC-CBD-PB-03 opening serve (0-0): the first fault hands over '
        'at once', (tester) async {
      final log = <String>[];
      await _pumpPanel(tester, log: log);

      await tester.tap(find.byTooltip('Add point for team 2'));
      await tester.pump();

      expect(log, ['switchServer']);
      expect(find.textContaining('won the rally'), findsNothing);
    });

    testWidgets('TC-CBD-PB-04 singles: the serve is handed over at once', (
      tester,
    ) async {
      final log = <String>[];
      await _pumpPanel(
        tester,
        log: log,
        context: _context(isDoubles: false, serverNumber: 1),
        state: _state(serve: secondDone),
      );

      await tester.tap(find.byTooltip('Add point for team 2'));
      await tester.pump();

      expect(log, ['sideOut']);
      expect(find.textContaining('won the rally'), findsNothing);
    });

    testWidgets('a serving team point shows no toast', (tester) async {
      final log = <String>[];
      await _pumpPanel(tester, log: log);

      await tester.tap(find.byTooltip('Add point for team 1'));
      await tester.pump();

      expect(log, ['award:1']);
      expect(find.textContaining('no point awarded'), findsNothing);
    });

    testWidgets('viewer: no plus, no lose-serve button', (tester) async {
      await _pumpPanel(tester, log: <String>[], canScore: false);

      expect(find.byTooltip('Add point for team 2'), findsNothing);
      expect(find.byTooltip('Change serve'), findsNothing);
      expect(find.text('LOSE SERVE'), findsNothing);
    });
  });

  group('TC-CBD-PB-05 Lite / rally: either team scores, no side-out', () {
    for (final lite in [true, false]) {
      final name = lite ? 'Lite' : 'rally point set';
      testWidgets('$name: plus of the receiving team awards the point, no '
          'lose-serve toast or hand-over', (tester) async {
        final log = <String>[];
        await _pumpPanel(
          tester,
          log: log,
          state: _state(model: SportScoringModel.rallyPointSet, lite: lite),
        );

        await tester.tap(find.byTooltip('Add point for team 2'));
        await tester.pump();

        expect(log, ['award:2']);
        expect(find.textContaining('no point awarded'), findsNothing);
      });
    }
  });

  group('finish set', () {
    testWidgets('asks first, then finishes the set', (tester) async {
      final log = <String>[];
      await _pumpPanel(tester, log: log);

      await _endChoose(tester, 'Finish set');
      await tester.pumpAndSettle();
      expect(find.text('Finish set 1 at 5-3?'), findsOneWidget);
      expect(log, isEmpty);

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(log, ['finishSet']);
    });

    testWidgets('cancel does not finish the set', (tester) async {
      final log = <String>[];
      await _pumpPanel(tester, log: log);

      await _endChoose(tester, 'Finish set');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(log, isEmpty);
    });

    testWidgets('is disabled when the set has no points', (tester) async {
      final log = <String>[];
      await _pumpPanel(tester, log: log, confirmMessage: null);

      await tester.tap(find.text('END'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Finish set'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Only the END dialog is open: no confirmation follows.
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Confirm'), findsNothing);
      expect(log, isEmpty);
    });

    testWidgets('with override on, the reason is required in the dialog', (
      tester,
    ) async {
      final log = <String>[];
      await _pumpPanel(tester, log: log, state: _state(override: true));

      await _endChoose(tester, 'Finish set');
      await tester.pumpAndSettle();
      final confirm = find.widgetWithText(FilledButton, 'Confirm');
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull);

      await tester.enterText(find.byType(TextField), 'referee decision');
      await tester.pump();
      expect(tester.widget<FilledButton>(confirm).onPressed, isNotNull);
      expect(log, contains('override:true:referee decision'));
    });
  });

  group('pick the winner', () {
    testWidgets('lists both teams and saves the chosen one', (tester) async {
      final log = <String>[];
      await _pumpPanel(tester, log: log, completable: {1});
      final label1 = matchSideLabel(_match(), 1);

      await _endChoose(tester, 'Pick the winner');
      await tester.pumpAndSettle();
      await tester.tap(find.text(label1));
      await tester.pumpAndSettle();

      expect(log, ['complete:1']);
      // The scoring page closes once the result is saved.
      expect(find.byType(PickleballCourtPanel), findsNothing);
    });

    testWidgets('a team that has not won is locked and the popup says why', (
      tester,
    ) async {
      final log = <String>[];
      await _pumpPanel(tester, log: log, completable: {1});
      final label2 = matchSideLabel(_match(), 2);

      await _endChoose(tester, 'Pick the winner');
      await tester.pumpAndSettle();
      await tester.tap(find.text(label2), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(log, isEmpty);
      expect(find.byType(PickleballCourtPanel), findsOneWidget);
    });

    testWidgets('nobody can win yet: both locked with an explanation', (
      tester,
    ) async {
      final log = <String>[];
      await _pumpPanel(tester, log: log);

      await _endChoose(tester, 'Pick the winner');
      await tester.pumpAndSettle();

      expect(
        find.text(
          'The match does not meet the configured completion conditions.',
        ),
        findsOneWidget,
      );
      await tester.tap(
        find.text(matchSideLabel(_match(), 1)),
        warnIfMissed: false,
      );
      expect(log, isEmpty);
    });

    testWidgets('override on and no reason: locked until a reason is typed', (
      tester,
    ) async {
      final log = <String>[];
      await _pumpPanel(
        tester,
        log: log,
        state: _state(override: true),
        completable: {1},
      );

      await _endChoose(tester, 'Pick the winner');
      await tester.pumpAndSettle();
      final button = find.widgetWithText(
        FilledButton,
        matchSideLabel(_match(), 1),
      );
      expect(tester.widget<FilledButton>(button).onPressed, isNull);

      await tester.enterText(find.byType(TextField), 'opponent withdrew');
      await tester.pump();
      expect(log, contains('override:true:opponent withdrew'));
    });

    testWidgets('a failed save keeps the scoring page open', (tester) async {
      final log = <String>[];
      await _pumpPanel(tester, log: log, completable: {1}, failComplete: true);

      await _endChoose(tester, 'Pick the winner');
      await tester.pumpAndSettle();
      await tester.tap(find.text(matchSideLabel(_match(), 1)));
      await tester.pumpAndSettle();

      expect(log, ['complete:1']);
      expect(find.byType(PickleballCourtPanel), findsOneWidget);
    });

    testWidgets('cancel closes the popup and saves nothing', (tester) async {
      final log = <String>[];
      await _pumpPanel(tester, log: log, completable: {1});

      await _endChoose(tester, 'Pick the winner');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(log, isEmpty);
      expect(find.text(matchSideLabel(_match(), 1)), findsNothing);
    });
  });

  group('while a save is running', () {
    testWidgets('finish set and the cup are locked', (tester) async {
      final log = <String>[];
      await _pumpPanel(
        tester,
        log: log,
        completable: {1},
        state: _state().copyWith(isSubmitting: true),
      );

      await tester.tap(find.text('END'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pick the winner'), warnIfMissed: false);
      await tester.tap(find.text('Finish set'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Both entries are locked: only the END dialog stays open.
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(log, isEmpty);
    });
  });

  group('popups with the keyboard open', () {
    testWidgets('the winner popup scrolls instead of overflowing', (
      tester,
    ) async {
      await _pumpPanel(
        tester,
        log: <String>[],
        state: _state(override: true),
        completable: {1},
        size: const Size(800, 360),
      );
      tester.view.viewInsets = const FakeViewPadding(bottom: 200);
      addTearDown(tester.view.resetViewInsets);

      // Landscape: the scoreboard's END button leads to the winner popup.
      await tester.tap(find.text('END'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pick the winner'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsWidgets);
    });
  });

  group('menu', () {
    testWidgets('turning override on asks for the reason first', (
      tester,
    ) async {
      final log = <String>[];
      await _pumpPanel(tester, log: log);

      await _openMenu(tester);
      await tester.tap(find.text('Override'));
      await tester.pumpAndSettle();

      final confirm = find.widgetWithText(FilledButton, 'Confirm');
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
      await tester.enterText(find.byType(TextField), 'referee decision');
      await tester.pump();
      await tester.tap(confirm);
      await tester.pumpAndSettle();

      expect(log.last, 'override:true:referee decision');
    });

    testWidgets('cancelling the reason leaves override off', (tester) async {
      final log = <String>[];
      await _pumpPanel(tester, log: log);

      await _openMenu(tester);
      await tester.tap(find.text('Override'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'half typed');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(log.last, 'override:false:');
    });

    testWidgets('turning override off needs no reason', (tester) async {
      final log = <String>[];
      await _pumpPanel(
        tester,
        log: log,
        state: _state(override: true, reason: 'x'),
      );

      await _openMenu(tester);
      await tester.tap(find.text('Override'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);
      expect(log, ['override:false:x']);
    });

    testWidgets('Lite has no override item', (tester) async {
      await _pumpPanel(tester, log: <String>[], state: _state(lite: true));

      await _openMenu(tester);

      expect(find.text('Override'), findsNothing);
    });

    testWidgets('force win appears only when the page provides it', (
      tester,
    ) async {
      var forced = 0;
      await _pumpPanel(tester, log: <String>[], onForceWin: () => forced++);

      await _openMenu(tester);
      await tester.tap(find.text('Force win'));
      await tester.pumpAndSettle();

      expect(forced, 1);
    });

    testWidgets('no menu and no net icons without scoring permission', (
      tester,
    ) async {
      await _pumpPanel(tester, log: <String>[], canScore: false);

      expect(find.byTooltip('More actions'), findsNothing);
      expect(find.text('END'), findsNothing);
      expect(find.byTooltip('Change serve'), findsNothing);
    });
  });

  group('Lite', () {
    testWidgets('rally: both teams can score, no side-out lock', (
      tester,
    ) async {
      final log = <String>[];
      await _pumpPanel(
        tester,
        log: log,
        state: _state(model: SportScoringModel.rallyPointSet, lite: true),
        context: _context(mode: CourtScoringMode.rally),
      );

      await tester.tap(find.byTooltip('Add point for team 2'));

      expect(log, ['award:2']);
    });

    testWidgets('TC-LPK-APP-05 side-out: plus of the receiver loses the serve, '
        'no point', (tester) async {
      final log = <String>[];
      await _pumpPanel(tester, log: log, state: _state(lite: true));

      await tester.tap(find.byTooltip('Add point for team 2'));

      expect(log, ['switchServer']);
    });

    testWidgets('TC-LPK-APP-06 side-out: plus of the serving team awards the '
        'point', (tester) async {
      final log = <String>[];
      await _pumpPanel(tester, log: log, state: _state(lite: true));

      await tester.tap(find.byTooltip('Add point for team 1'));

      expect(log, ['award:1']);
    });

    test('the court context tracks serve turns in Lite', () async {
      final container = ProviderContainer(
        overrides: [
          singleMatchProvider.overrideWith(
            (ref, params) => Stream.value(_match()),
          ),
          scorePanelNotifierProvider.overrideWith2(
            (arg) => _FakeScorePanel(arg, _state(lite: true), <String>[]),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.listen(singleMatchProvider(_params), (_, _) {});
      await container.read(singleMatchProvider(_params).future);

      final court = container.read(pickleballCourtContextProvider(_params));

      expect(court?.scoringMode, CourtScoringMode.sideOut);
      expect(court?.serverNumber, 1);
    });
  });
}
