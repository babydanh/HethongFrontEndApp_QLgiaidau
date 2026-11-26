import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_repository.dart';
import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_notifier.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_state.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _params = (tournamentId: 'tournament-1', matchId: 'match-1');

const _timeout = ScoreWriteException('Connection timed out', transient: true);

/// Records every live score write; the first [failures] writes fail with
/// [error] (by default the way a dropped connection or a timeout does).
class _FlakyWrites extends Fake implements IMatchRepository {
  _FlakyWrites(this.failures, {this.error = _timeout});

  int failures;
  final Object error;
  int attempts = 0;
  final List<Map<String, dynamic>?> sent = [];

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
    attempts++;
    if (failures > 0) {
      failures--;
      throw error;
    }
    final live = scoreDetailsExtras?['liveState'] as Map<String, dynamic>?;
    sent.add(live?['tennisPointState'] as Map<String, dynamic>?);
  }
}

class _Panel extends ScorePanelNotifier {
  _Panel(super.arg);

  @override
  ScorePanelState build() => ScorePanelState(
    config: resolveSportConfig({
      'kind': 'TENNIS',
      'setsToWin': 2,
    }, SportRuleKind.tennis),
    // Game 0-1 already won and 30-0, as the Backend kept it in the report.
    finishedSets: const [SetScoreData(score1: 0, score2: 1)],
    tennis: const TennisGameState(team1GamePoints: 2),
  );
}

ProviderContainer _container(_FlakyWrites writes) {
  final container = ProviderContainer(
    overrides: [
      matchRepositoryProvider.overrideWithValue(writes),
      scorePanelNotifierProvider.overrideWith2((arg) => _Panel(arg)),
    ],
  );
  addTearDown(container.dispose);
  container.listen(scorePanelNotifierProvider(_params), (_, _) {});
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'TC-TENNIS-OVL-APP-01 a failed live point write is retried until the '
    'Backend has the newest point, without another tap',
    () async {
      final writes = _FlakyWrites(2);
      final container = _container(writes);
      final panel = container.read(
        scorePanelNotifierProvider(_params).notifier,
      );

      // 30-0 -> 40-0, then the referee stops tapping.
      panel.tennisAwardPoint(true);
      await Future<void>.delayed(const Duration(seconds: 4));

      expect(writes.sent, isNotEmpty);
      expect(writes.sent.last, {
        'team1Point': 3,
        'team2Point': 0,
        'mode': 'game',
      });
      // The warning goes away once the point is saved.
      expect(
        container.read(scorePanelNotifierProvider(_params)).errorMessage,
        isNull,
      );
    },
  );

  test(
    'TC-TENNIS-OVL-APP-02 points taken while a write is in flight are sent '
    'after it, newest last',
    () async {
      final writes = _FlakyWrites(0);
      final container = _container(writes);
      final panel = container.read(
        scorePanelNotifierProvider(_params).notifier,
      );

      panel.tennisAwardPoint(false); // 30-15
      await Future<void>.delayed(const Duration(milliseconds: 300));
      panel.tennisAwardPoint(false); // 30-30
      panel.tennisAwardPoint(true); // 40-30
      panel.tennisAwardPoint(false); // 40-40
      await Future<void>.delayed(const Duration(milliseconds: 600));

      expect(writes.sent.first, {
        'team1Point': 2,
        'team2Point': 1,
        'mode': 'game',
      });
      expect(writes.sent.last, {
        'team1Point': 3,
        'team2Point': 3,
        'mode': 'game',
      });
    },
  );

  // A refused write (no right to score, conflict) fails the same way again:
  // resending it only hammers the Backend. The warning stays up instead.
  for (final (id, error) in [
    (
      'TC-TENNIS-OVL-APP-09 a 403 refusal',
      const ScoreWriteException('Bạn không có quyền chấm', statusCode: 403),
    ),
    (
      'TC-TENNIS-OVL-APP-10 a 409 conflict',
      const ScoreWriteException(
        'Điểm đã thay đổi từ thiết bị khác.',
        statusCode: 409,
      ),
    ),
  ]) {
    test('$id is not resent and keeps the sync warning', () {
      fakeAsync((async) {
        final writes = _FlakyWrites(99, error: error);
        final container = _container(writes);
        container
            .read(scorePanelNotifierProvider(_params).notifier)
            .tennisAwardPoint(true);

        async.elapse(const Duration(seconds: 30));

        expect(writes.attempts, 1);
        expect(
          container.read(scorePanelNotifierProvider(_params)).errorMessage,
          isNotNull,
        );
      });
    });
  }
}
