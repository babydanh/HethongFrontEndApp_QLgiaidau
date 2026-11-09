import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_repository.dart';
import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_notifier.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_state.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations_vi.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _params = (tournamentId: 'tournament-1', matchId: 'match-1');

const _config = SportConfig(
  kind: SportRuleKind.pickleball,
  scoringModel: SportScoringModel.pickleballSideOut,
  bestOf: 3,
  setsToWin: 2,
  pointsPerSet: 11,
  mustWinByTwo: true,
  maxPoints: 0,
  tiebreakAt: 0,
);

/// Counts what the panel sends to the server.
class _Writes extends Fake implements IMatchRepository {
  int calls = 0;

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
  }) async {
    calls++;
  }
}

class _Panel extends ScorePanelNotifier {
  _Panel(super.arg, this.initial);

  final ScorePanelState initial;

  @override
  ScorePanelState build() => initial;
}

ProviderContainer _container({
  required int score1,
  required int score2,
  required _Writes writes,
  bool isLite = true,
}) {
  final container = ProviderContainer(
    overrides: [
      matchRepositoryProvider.overrideWithValue(writes),
      scorePanelNotifierProvider.overrideWith2(
        (arg) => _Panel(
          arg,
          ScorePanelState(
            config: _config,
            isLite: isLite,
            pickleball: const PickleballServeState(
              isTeam1Serving: true,
              serverNumber: 1,
            ),
            rally: RallySetState(currentP1: score1, currentP2: score2),
          ),
        ),
      ),
    ],
  );
  addTearDown(container.dispose);
  addTearDown(() => Future<void>.delayed(const Duration(milliseconds: 300)));
  container.listen(scorePanelNotifierProvider(_params), (_, _) {});
  return container;
}

ScorePanelNotifier _panel(ProviderContainer c) =>
    c.read(scorePanelNotifierProvider(_params).notifier);

ScorePanelState _state(ProviderContainer c) =>
    c.read(scorePanelNotifierProvider(_params));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final needsWinner = AppLocalizationsVi().scorePanel_pickleballTieNeedsWinner;

  group('TC-TIE-APP-01 finishing a tied pickleball set', () {
    test('Lite 5-5: refuses with a clear message and sends nothing', () async {
      final writes = _Writes();
      final c = _container(score1: 5, score2: 5, writes: writes);

      await _panel(c).finishSet();

      expect(_state(c).errorMessage, needsWinner);
      expect(_state(c).finishedSets, isEmpty);
      expect(_state(c).rally?.currentP1, 5);
      expect(_state(c).isSubmitting, isFalse);
      expect(writes.calls, 0);
    });

    test('rejectTiedRallySet is true on a tie and sets the message', () {
      final c = _container(score1: 7, score2: 7, writes: _Writes());

      expect(_panel(c).rejectTiedRallySet(), isTrue);
      expect(_state(c).errorMessage, needsWinner);
    });

    test('Lite 5-4: still finishes the set', () async {
      final writes = _Writes();
      final c = _container(score1: 5, score2: 4, writes: writes);

      expect(_panel(c).rejectTiedRallySet(), isFalse);
      await _panel(c).finishSet();

      expect(_state(c).finishedSets.length, 1);
      expect(_state(c).finishedSets.first.isFinished, isTrue);
      expect(writes.calls, greaterThan(0));
    });
  });
}
