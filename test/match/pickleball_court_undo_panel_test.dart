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

/// Score panel that really changes its state, so undo has something to restore.
class _LiveScorePanel extends ScorePanelNotifier {
  _LiveScorePanel(super.arg);

  @override
  ScorePanelState build() => const ScorePanelState(
    config: _config,
    pickleball: PickleballServeState(serverNumber: 1, openingDone: true),
    rally: RallySetState(currentP1: 2, currentP2: 1),
  );

  @override
  bool pickleballAwardPoint(bool isTeam1) {
    final r = state.rally!;
    state = state.copyWith(
      rally: RallySetState(
        currentP1: isTeam1 ? r.currentP1 + 1 : r.currentP1,
        currentP2: isTeam1 ? r.currentP2 : r.currentP2 + 1,
      ),
    );
    return true;
  }

  @override
  void pickleballSwitchServer() {
    final pb = state.pickleball!;
    state = state.copyWith(
      pickleball: pb.serverNumber == 1
          ? pb.copyWith(serverNumber: 2)
          : pb.copyWith(isTeam1Serving: !pb.isTeam1Serving, serverNumber: 1),
    );
  }

  @override
  void pickleballRestoreStep({
    required RallySetState rally,
    required PickleballServeState serve,
  }) => state = state.copyWith(rally: rally, pickleball: serve);
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

Future<ProviderContainer> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(360, 700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        singleMatchProvider.overrideWith(
          (ref, params) => Stream.value(
            MatchModel.fromJson({
              'id': 'match-1',
              'tournamentId': 'tournament-1',
              'status': 'LIVE',
              'team1Members': ['Lan Anh', 'Minh'],
              'team2Members': ['Bảo', 'Hà'],
            }, 'match-1'),
          ),
        ),
        pickleballCourtContextProvider.overrideWith(
          (ref, params) => const CourtContext(
            score1: 2,
            score2: 1,
            isDoubles: true,
            team1PlayerCount: 2,
            team2PlayerCount: 2,
            servingTeam: 1,
            serverNumber: 1,
            scoringMode: CourtScoringMode.sideOut,
            setIndex: 0,
            targetPoints: 11,
            isDecidingSet: false,
          ),
        ),
        scorePanelNotifierProvider.overrideWith2(
          (arg) => _LiveScorePanel(arg),
        ),
        matchRepositoryProvider.overrideWithValue(_EchoCourtRepository()),
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

/// The undo button's tap handler: null when it is greyed out.
GestureTapCallback? _undoTap(WidgetTester tester) => tester
    .widget<InkWell>(
      find.ancestor(
        of: find.byIcon(Icons.undo_rounded),
        matching: find.byType(InkWell),
      ),
    )
    .onTap;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('TC-UNDO-APP-02 undo is off until the referee does something', (
    tester,
  ) async {
    await _pump(tester);

    expect(_undoTap(tester), isNull);
  });

  testWidgets('TC-UNDO-APP-03 undo walks back point, lose-serve and point, '
      'as often as pressed', (tester) async {
    final container = await _pump(tester);
    ScorePanelState read() => container.read(scorePanelNotifierProvider(_params));

    await tester.tap(find.byTooltip('Add point for team 1')); // 3-1
    await tester.pump();
    await tester.tap(find.byTooltip('Add point for team 2')); // lose serve -> server 2
    await tester.pump();
    await tester.tap(find.byTooltip('Add point for team 1')); // 4-1
    await tester.pump();
    expect(read().rally!.currentP1, 4);
    expect(read().pickleball!.serverNumber, 2);

    await tester.tap(find.byTooltip('Undo'));
    await tester.pumpAndSettle();
    expect(read().rally!.currentP1, 3);
    expect(read().pickleball!.serverNumber, 2);

    await tester.tap(find.byTooltip('Undo'));
    await tester.pumpAndSettle();
    expect(read().pickleball!.serverNumber, 1, reason: 'lose-serve taken back');

    await tester.tap(find.byTooltip('Undo'));
    await tester.pumpAndSettle();
    expect(read().rally!.currentP1, 2);
    expect(read().rally!.currentP2, 1);

    expect(_undoTap(tester), isNull, reason: 'nothing left to undo');
  });
}
