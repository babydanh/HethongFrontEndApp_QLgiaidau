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

/// Pickleball serve and ends on the real court screen: the real score panel,
/// the real court context and court state, driven only by taps. Nothing about
/// the rules is mocked; only the network writes are swallowed.

const _params = (tournamentId: 'tournament-1', matchId: 'match-1');

const _config = SportConfig(
  kind: SportRuleKind.pickleball,
  scoringModel: SportScoringModel.pickleballSideOut,
  isOpenScoring: false,
  bestOf: 3,
  setsToWin: 2,
  pointsPerSet: 11,
  mustWinByTwo: true,
  maxPoints: 0,
  tiebreakAt: 0,
);

class _Writes extends Fake implements IMatchRepository {
  @override
  Future<void> updateScoreDetails(
    String tournamentId,
    String matchId, {
    required int p1SetsWon,
    required int p2SetsWon,
    required List<SetScoreData> scoreDetails,
    Map<String, dynamic>? scoreDetailsExtras,
    String? winnerId,
    String? overrideReason,
    int? expectedRevision,
    bool useLiteParticipantAccess = false,
    ({String date, String? time})? playedAt,
  }) async {}

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

class _Seeded extends ScorePanelNotifier {
  _Seeded(super.arg, this.initial);

  final ScorePanelState initial;

  @override
  ScorePanelState build() => initial;
}

ScorePanelState _seed({
  int p1 = 0,
  int p2 = 0,
  PickleballServeState serve = const PickleballServeState(openingDone: true),
  List<SetScoreData> finishedSets = const [],
}) => ScorePanelState(
  config: _config,
  pickleball: serve,
  rally: RallySetState(currentP1: p1, currentP2: p2),
  finishedSets: finishedSets,
);

Future<ProviderContainer> _pump(
  WidgetTester tester,
  ScorePanelState seed, {
  required bool doubles,
}) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  // The server already holds the court of the opening turn: a match is
  // reopened from it, and the turn start must not be re-derived mid-game.
  final pb = seed.pickleball!;
  final servingScore = pb.isTeam1Serving
      ? seed.rally!.currentP1
      : seed.rally!.currentP2;
  final court = CourtState(
    turnStart: CourtTurnStart(
      team: pb.isTeam1Serving ? 1 : 2,
      serverNumber: pb.serverNumber,
      teamScoreAtStart: servingScore,
      serverPlayerIndex: doubles && servingScore.isOdd ? 1 : 0,
    ),
  );
  final match = MatchModel.fromJson({
    'id': 'match-1',
    'tournamentId': 'tournament-1',
    'status': 'LIVE',
    'scoreDetails': {'courtState': court.toJson()},
    'team1Members': doubles ? ['An', 'Binh'] : ['An'],
    'team2Members': doubles ? ['Chi', 'Dung'] : ['Chi'],
  }, 'match-1');
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        matchRepositoryProvider.overrideWithValue(_Writes()),
        singleMatchProvider.overrideWith((ref, params) => Stream.value(match)),
        scorePanelNotifierProvider.overrideWith2((arg) => _Seeded(arg, seed)),
      ],
      child: MaterialApp(
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
  return ProviderScope.containerOf(
    tester.element(find.byType(PickleballCourtPanel)),
  );
}

/// Taps a control by tooltip, then lets the live-sync debounce fire.
Future<void> _tap(WidgetTester tester, String tooltip) async {
  await tester.tap(find.byTooltip(tooltip));
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pumpAndSettle();
}

Future<void> _plus(WidgetTester tester, int team) =>
    _tap(tester, 'Add point for team $team');

ScorePanelState _score(ProviderContainer c) =>
    c.read(scorePanelNotifierProvider(_params));

/// The layout the screen draws now, from the real context and court state.
CourtLayout _layout(ProviderContainer c) => resolveCourtLayout(
  c.read(pickleballCourtNotifierProvider(_params)),
  c.read(pickleballCourtContextProvider(_params))!,
);

({int team, int server, int s1, int s2}) _serve(ProviderContainer c) {
  final s = _score(c);
  return (
    team: s.pickleball!.isTeam1Serving ? 1 : 2,
    server: s.pickleball!.serverNumber,
    s1: s.rally!.currentP1,
    s2: s.rally!.currentP2,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('doubles: server 1, server 2, side-out', () {
    testWidgets(
      'serving team scores: even score serves from the right, odd from the left',
      (tester) async {
        final c = await _pump(tester, _seed(), doubles: true);

        expect(_layout(c).serverCell, CourtCell.right);
        expect(_layout(c).receiverCell, CourtCell.right);
        await _plus(tester, 1);
        expect(_layout(c).serverCell, CourtCell.left);
        expect(_layout(c).receiverCell, CourtCell.left);
        await _plus(tester, 1);
        expect(_layout(c).serverCell, CourtCell.right);
        expect(_serve(c), (team: 1, server: 1, s1: 2, s2: 0));
      },
    );

    testWidgets(
      'both servers lose in turn: server 1 -> server 2 (partner) -> other team',
      (tester) async {
        final c = await _pump(tester, _seed(p1: 3, p2: 2), doubles: true);
        final first = _layout(c);
        expect(first.callServerNumber, 1);

        await _tap(tester, 'Switch server');
        final second = _layout(c);
        expect(_serve(c), (team: 1, server: 2, s1: 3, s2: 2));
        expect(second.callServerNumber, 2);
        expect(second.serverPlayerIndex, isNot(first.serverPlayerIndex));
        expect(second.serverCell, isNot(first.serverCell));

        await _tap(tester, 'Change serve');
        final other = _layout(c);
        expect(_serve(c), (team: 2, server: 1, s1: 3, s2: 2));
        expect(other.servingTeam, 2);
        expect(other.callServerNumber, 1);
        // Team 2 has 2 points: even, so it serves from the right.
        expect(other.serverCell, CourtCell.right);
      },
    );

    testWidgets('the receiver plus is a fault of the server, not a point', (
      tester,
    ) async {
      final c = await _pump(tester, _seed(p1: 1, p2: 1), doubles: true);

      await _plus(tester, 2);
      expect(_serve(c), (team: 1, server: 2, s1: 1, s2: 1));
      await _plus(tester, 2);
      expect(_serve(c), (team: 2, server: 1, s1: 1, s2: 1));
    });

    testWidgets('the opening serve has one fault: it hands over at once', (
      tester,
    ) async {
      final c = await _pump(
        tester,
        _seed(serve: const PickleballServeState()),
        doubles: true,
      );

      await _tap(tester, 'Change serve');
      expect(_serve(c), (team: 2, server: 1, s1: 0, s2: 0));
      // Back at server 1 of a normal turn afterwards: two faults needed.
      expect(find.byTooltip('Switch server'), findsOneWidget);
    });

    testWidgets('undo puts back each serve step and the point', (tester) async {
      final c = await _pump(tester, _seed(p1: 2), doubles: true);

      await _plus(tester, 1);
      await _tap(tester, 'Switch server');
      await _tap(tester, 'Change serve');
      expect(_serve(c), (team: 2, server: 1, s1: 3, s2: 0));

      await _tap(tester, 'Undo');
      expect(_serve(c), (team: 1, server: 2, s1: 3, s2: 0));
      await _tap(tester, 'Undo');
      expect(_serve(c), (team: 1, server: 1, s1: 3, s2: 0));
      await _tap(tester, 'Undo');
      expect(_serve(c), (team: 1, server: 1, s1: 2, s2: 0));
      expect(_layout(c).serverCell, CourtCell.right);
    });
  });

  group('singles: no server 2', () {
    testWidgets('score parity picks the cell and a fault hands over at once', (
      tester,
    ) async {
      final c = await _pump(tester, _seed(), doubles: false);

      expect(_layout(c).callServerNumber, isNull);
      expect(_layout(c).serverCell, CourtCell.right);
      await _plus(tester, 1);
      expect(_layout(c).serverCell, CourtCell.left);

      await _plus(tester, 2);
      expect(_serve(c), (team: 2, server: 1, s1: 1, s2: 0));
      expect(_layout(c).callServerNumber, isNull);
      // Team 2 has 0 points: even, right cell.
      expect(_layout(c).serverCell, CourtCell.right);
    });
  });

  group('changing ends', () {
    testWidgets('the switch-ends button flips the court and undo flips back', (
      tester,
    ) async {
      final c = await _pump(tester, _seed(p1: 2, p2: 1), doubles: true);
      expect(_layout(c).team1First, isTrue);

      await _tap(tester, 'Switch ends');
      expect(_layout(c).team1First, isFalse);
      expect(_serve(c), (team: 1, server: 1, s1: 2, s2: 1));

      await _tap(tester, 'Undo');
      expect(_layout(c).team1First, isTrue);
    });

    testWidgets('a game 2 starts with the ends already switched', (
      tester,
    ) async {
      final c = await _pump(
        tester,
        _seed(
          finishedSets: const [
            SetScoreData(score1: 11, score2: 5, isFinished: true),
          ],
        ),
        doubles: true,
      );

      expect(_layout(c).team1First, isFalse);
    });

    testWidgets('the deciding game switches ends once, at 6 points', (
      tester,
    ) async {
      final c = await _pump(
        tester,
        _seed(
          p1: 4,
          finishedSets: const [
            SetScoreData(score1: 11, score2: 5, isFinished: true),
            SetScoreData(score1: 4, score2: 11, isFinished: true),
          ],
        ),
        doubles: true,
      );
      expect(_layout(c).team1First, isTrue);

      await _plus(tester, 1);
      expect(_layout(c).team1First, isTrue, reason: '5 points: not yet');
      await _plus(tester, 1);
      expect(_layout(c).team1First, isFalse, reason: '6 points: switch');
      await _plus(tester, 1);
      expect(_layout(c).team1First, isFalse, reason: 'only once');
    });
  });
}
