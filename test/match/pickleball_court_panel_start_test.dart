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

const _context = CourtContext(
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

/// Records the points the panel awards.
class _FakeScorePanel extends ScorePanelNotifier {
  _FakeScorePanel(super.arg, this.log);

  final List<String> log;

  @override
  ScorePanelState build() => const ScorePanelState(
    config: _config,
    pickleball: PickleballServeState(),
    rally: RallySetState(),
  );

  @override
  bool pickleballAwardPoint(bool isTeam1) {
    log.add('award:${isTeam1 ? 1 : 2}');
    return true;
  }

  @override
  void rallyAddPoint(bool isTeam1) => log.add('rallyAdd:${isTeam1 ? 1 : 2}');
}

class _Repo extends Fake implements IMatchRepository {
  _Repo(this.log, {this.failStart = false});

  final List<String> log;
  final bool failStart;

  @override
  Future<void> startMatch(
    String tournamentId,
    String matchId, {
    int? maxScore,
    int? timeLimitMinutes,
    String? refereeName,
    bool useLiteParticipantAccess = false,
  }) async {
    log.add('start');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (failStart) throw Exception('cannot start');
  }

  @override
  Future<MatchModel> updateCourtState(
    String matchId,
    Map<String, dynamic> courtState,
  ) async => _match('LIVE');
}

MatchModel _match(String status) => MatchModel.fromJson({
  'id': 'match-1',
  'tournamentId': 'tournament-1',
  'status': status,
  'team1Members': ['Lan Anh', 'Minh'],
  'team2Members': ['Bảo', 'Hà'],
}, 'match-1');

Future<void> _pumpPanel(
  WidgetTester tester, {
  required List<String> log,
  required String status,
  bool failStart = false,
}) async {
  tester.view.physicalSize = const Size(360, 700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        singleMatchProvider.overrideWith(
          (ref, params) => Stream.value(_match(status)),
        ),
        pickleballCourtContextProvider.overrideWith((ref, params) => _context),
        scorePanelNotifierProvider.overrideWith2(
          (arg) => _FakeScorePanel(arg, log),
        ),
        matchRepositoryProvider.overrideWithValue(
          _Repo(log, failStart: failStart),
        ),
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TC-START-APP a scheduled match starts on the first point', () {
    testWidgets('TC-START-APP-01 the plus button shows before the match starts', (
      tester,
    ) async {
      await _pumpPanel(tester, log: <String>[], status: 'SCHEDULED');

      expect(find.byTooltip('Add point for team 1'), findsOneWidget);
    });

    testWidgets('TC-START-APP-02 the first plus starts the match, then scores', (
      tester,
    ) async {
      final log = <String>[];
      await _pumpPanel(tester, log: log, status: 'SCHEDULED');

      await tester.tap(find.byTooltip('Add point for team 1'));
      await tester.pumpAndSettle();

      expect(log.where((e) => e == 'start').length, 1);
      expect(log.indexOf('start'), lessThan(log.indexOf('award:1')));
    });

    testWidgets('TC-START-APP-03 a double tap starts the match only once', (
      tester,
    ) async {
      final log = <String>[];
      await _pumpPanel(tester, log: log, status: 'SCHEDULED');

      final plus = find.byTooltip('Add point for team 1');
      await tester.tap(plus);
      await tester.tap(plus);
      await tester.pumpAndSettle();

      expect(log.where((e) => e == 'start').length, 1);
    });

    testWidgets('TC-START-APP-04 a failed start scores nothing', (tester) async {
      final log = <String>[];
      await _pumpPanel(tester, log: log, status: 'SCHEDULED', failStart: true);

      await tester.tap(find.byTooltip('Add point for team 1'));
      await tester.pumpAndSettle();

      expect(log, ['start']);
      expect(find.text('Unable to start the match.'), findsOneWidget);
    });

    testWidgets('TC-START-APP-05 a live match scores without starting again', (
      tester,
    ) async {
      final log = <String>[];
      await _pumpPanel(tester, log: log, status: 'LIVE');

      await tester.tap(find.byTooltip('Add point for team 1'));
      await tester.pumpAndSettle();

      expect(log, contains('award:1'));
      expect(log, isNot(contains('start')));
    });
  });
}
