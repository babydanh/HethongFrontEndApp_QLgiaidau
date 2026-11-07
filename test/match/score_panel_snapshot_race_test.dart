import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_repository.dart';
import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_notifier.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_state.dart';
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

/// The real score panel logic, started from a 0-0 badminton rally state.
class _Panel extends ScorePanelNotifier {
  _Panel(super.arg);

  @override
  ScorePanelState build() => ScorePanelState(
    config: resolveSportConfig(null, SportRuleKind.badminton),
    rally: const RallySetState(),
  );
}

/// A server snapshot that still shows the set at [p1]-[p2].
MatchModel _snapshot({required int p1, required int p2, required int revision}) =>
    MatchModel(
      id: 'match-1',
      tournamentId: 'tournament-1',
      round: 1,
      matchNumber: 1,
      team1Id: 'team-1',
      team2Id: 'team-2',
      team1Name: 'Team A',
      team2Name: 'Team B',
      sportKey: 'badminton',
      status: 'LIVE',
      revision: revision,
      scoreDetails: {
        'sets': [
          {'score1': p1, 'score2': p2, 'isFinished': false},
        ],
      },
      bracketPosition: const BracketPosition(round: 1, position: 1),
      updatedAt: DateTime.utc(2026, 11, 7),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('TC-SYNC-01 a snapshot that lacks an unsent tap does not roll the score back', () async {
    final container = ProviderContainer(
      overrides: [
        matchRepositoryProvider.overrideWithValue(_Writes()),
        scorePanelNotifierProvider.overrideWith2((arg) => _Panel(arg)),
      ],
    );
    addTearDown(container.dispose);
    // The live sync fires 250 ms after a tap; let it land while the container is alive.
    addTearDown(() => Future<void>.delayed(const Duration(milliseconds: 400)));
    container.listen(scorePanelNotifierProvider(_params), (_, _) {});
    final panel = container.read(scorePanelNotifierProvider(_params).notifier);

    panel.rallyAddPoint(true);
    panel.rallyAddPoint(true);
    // Echo of an earlier write: the server still shows 1-0 while the 2nd tap is unsent.
    panel.applyMatchSnapshot(_snapshot(p1: 1, p2: 0, revision: 7));

    expect(container.read(scorePanelNotifierProvider(_params)).rally!.currentP1, 2);
  });
}
