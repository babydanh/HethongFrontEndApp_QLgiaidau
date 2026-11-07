import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_repository.dart';
import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_notifier.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_state.dart';
import 'package:app_quanly_giaidau/features/match/widgets/rally_score_panel.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _params = (tournamentId: 'tournament-1', matchId: 'match-1');

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
}

/// The real score panel logic, started from a state the test chooses.
class _Panel extends ScorePanelNotifier {
  _Panel(super.arg, this.initial);

  final ScorePanelState initial;

  @override
  ScorePanelState build() => initial;
}

MatchModel _match({bool doubles = false}) => MatchModel(
  id: 'match-1',
  tournamentId: 'tournament-1',
  round: 1,
  matchNumber: 1,
  team1Id: 'team-1',
  team2Id: 'team-2',
  team1Name: 'Team A',
  team2Name: 'Team B',
  team1Members: doubles ? const ['An', 'Binh'] : const ['An'],
  team2Members: doubles ? const ['Chi', 'Dung'] : const ['Chi'],
  status: 'LIVE',
  bracketPosition: const BracketPosition(round: 1, position: 1),
  updatedAt: DateTime.utc(2026, 10, 19),
);

ScorePanelState _state({
  SportRuleKind kind = SportRuleKind.badminton,
  int p1 = 0,
  int p2 = 0,
  int? lastWinner,
  int swaps1 = 0,
  int swaps2 = 0,
  int finishedGames = 0,
  bool open = false,
}) {
  final base = resolveSportConfig(null, kind);
  return ScorePanelState(
    config: SportConfig(
      kind: kind,
      scoringModel: base.scoringModel,
      isOpenScoring: open,
      bestOf: base.bestOf,
      setsToWin: base.setsToWin,
      pointsPerSet: base.pointsPerSet,
      mustWinByTwo: base.mustWinByTwo,
      maxPoints: base.maxPoints,
      tiebreakAt: base.tiebreakAt,
    ),
    isLite: open,
    finishedSets: [
      for (var i = 0; i < finishedGames; i++)
        const SetScoreData(score1: 21, score2: 10, isFinished: true),
    ],
    rally: RallySetState(
      currentP1: p1,
      currentP2: p2,
      lastWinner: lastWinner,
      swaps1: swaps1,
      swaps2: swaps2,
    ),
  );
}

Future<void> _pump(
  WidgetTester tester,
  ScorePanelState state, {
  bool doubles = false,
}) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  final match = _match(doubles: doubles);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        matchRepositoryProvider.overrideWithValue(_Writes()),
        singleMatchProvider.overrideWith((ref, params) => Stream.value(match)),
        scorePanelNotifierProvider.overrideWith2((arg) => _Panel(arg, state)),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: RallyScorePanel(params: _params)),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

Finder get _serve => find.textContaining('● SERVE');

void main() {
  group('TC-CBD-RALLY-09 badminton shows who serves', () {
    testWidgets('team A serves from the right court at 0-0', (tester) async {
      await _pump(tester, _state());
      expect(_serve, findsOneWidget);
      expect(find.text('● SERVE · right court'), findsOneWidget);
      expect(
        tester.getCenter(_serve).dy,
        lessThan(tester.getCenter(find.text('Đội B')).dy),
      );
    });

    testWidgets('team B serves from the left court at an odd score', (
      tester,
    ) async {
      await _pump(tester, _state(p1: 2, p2: 3, lastWinner: 2));
      expect(find.text('● SERVE · left court'), findsOneWidget);
      expect(
        tester.getCenter(_serve).dy,
        greaterThan(tester.getCenter(find.text('Đội B')).dy),
      );
    });

    testWidgets('doubles also names the serving player', (tester) async {
      await _pump(
        tester,
        _state(p1: 1, p2: 0, lastWinner: 1, swaps1: 1),
        doubles: true,
      );
      expect(find.text('● SERVE · left court · Player 1'), findsOneWidget);
    });

    testWidgets('hides the line when the last winner is unknown', (
      tester,
    ) async {
      await _pump(tester, _state(p1: 2, p2: 1));
      expect(_serve, findsNothing);
    });
  });

  group('TC-CBD-RALLY-10 table tennis, breaks and the sports without it', () {
    testWidgets('table tennis changes server every 2 points', (tester) async {
      await _pump(
        tester,
        _state(kind: SportRuleKind.tableTennis, p1: 1, p2: 1),
      );
      expect(find.text('● SERVE'), findsOneWidget);
      expect(
        tester.getCenter(_serve).dy,
        greaterThan(tester.getCenter(find.text('Đội B')).dy),
      );
    });

    testWidgets('badminton 11 shows the 60 second reminder', (tester) async {
      await _pump(tester, _state(p1: 11, p2: 4, lastWinner: 1));
      expect(find.text('60-second interval (leader reached 11)'), findsOne);
    });

    testWidgets('table tennis reminds to change ends at 5 in the last game', (
      tester,
    ) async {
      await _pump(
        tester,
        _state(
          kind: SportRuleKind.tableTennis,
          p1: 5,
          p2: 2,
          lastWinner: 1,
          finishedGames: 4,
        ),
      );
      expect(
        find.text('Deciding game: change ends (a side reached 5)'),
        findsOne,
      );
    });

    testWidgets('pickleball rally shows no serve line', (tester) async {
      await _pump(tester, _state(kind: SportRuleKind.pickleball));
      expect(_serve, findsNothing);
    });

    testWidgets('Lite scorecards show no serve line or reminder', (
      tester,
    ) async {
      await _pump(tester, _state(p1: 11, p2: 4, lastWinner: 1, open: true));
      expect(_serve, findsNothing);
      expect(find.text('60-second interval (leader reached 11)'), findsNothing);
    });
  });

  group('TC-CBD-RALLY-11 scoring taps stay the same', () {
    testWidgets('+ on team B scores for B and hands B the serve', (
      tester,
    ) async {
      await _pump(tester, _state());
      await tester.tap(find.byIcon(Icons.add_rounded).last);
      await tester.pump();
      expect(find.text('1'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('● SERVE · left court'), findsOneWidget);
      expect(
        tester.getCenter(_serve).dy,
        greaterThan(tester.getCenter(find.text('Đội B')).dy),
      );
      // Let the debounced live sync fire before the test ends.
      await tester.pump(const Duration(milliseconds: 400));
    });

    testWidgets('- hides the line until the next point is known', (
      tester,
    ) async {
      await _pump(tester, _state(p1: 2, p2: 1, lastWinner: 2));
      await tester.tap(find.byIcon(Icons.remove_rounded).first);
      await tester.pump();
      expect(_serve, findsNothing);
      await tester.pump(const Duration(milliseconds: 400));
    });
  });
}
