import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
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

/// The real score panel logic, started from a state the test chooses.
class _Panel extends ScorePanelNotifier {
  _Panel(super.arg, this.initial);

  final ScorePanelState initial;

  @override
  ScorePanelState build() => initial;
}

SportConfig _config([Map<String, dynamic> format = const {}]) =>
    resolveSportConfig({
      'kind': 'TENNIS',
      'setsToWin': 2,
      'format': format,
    }, SportRuleKind.tennis);

ProviderContainer _container(
  SportConfig config, {
  List<SetScoreData> sets = const [],
  TennisGameState? tennis,
}) {
  final container = ProviderContainer(
    overrides: [
      matchRepositoryProvider.overrideWithValue(_Writes()),
      scorePanelNotifierProvider.overrideWith2(
        (arg) => _Panel(
          arg,
          ScorePanelState(config: config, finishedSets: sets, tennis: tennis),
        ),
      ),
    ],
  );
  addTearDown(container.dispose);
  // The live sync fires 250ms after a change; let it land while the container
  // is still alive (tear-downs run last-in first-out).
  addTearDown(() => Future<void>.delayed(const Duration(milliseconds: 300)));
  container.listen(scorePanelNotifierProvider(_params), (_, _) {});
  return container;
}

ScorePanelNotifier _panel(ProviderContainer c) =>
    c.read(scorePanelNotifierProvider(_params).notifier);

ScorePanelState _state(ProviderContainer c) =>
    c.read(scorePanelNotifierProvider(_params));

void _points(ProviderContainer c, bool team1, int count) {
  for (var i = 0; i < count; i++) {
    _panel(c).tennisAwardPoint(team1);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TC-CBD-TN-06 No-Ad from the configuration', () {
    test('at 40-40 the next point wins the game', () {
      final c = _container(_config({'noAd': true}));
      _points(c, true, 3);
      _points(c, false, 3);
      expect(_state(c).tennis!.team1GamePoints, 3);

      _panel(c).tennisAwardPoint(false);

      final set = _state(c).finishedSets.last;
      expect((set.score1, set.score2), (0, 1));
      expect(_state(c).tennis!.team2GamePoints, 0);
    });

    test('without the key 40-40 still goes to advantage', () {
      final c = _container(_config());
      _points(c, true, 3);
      _points(c, false, 3);

      _panel(c).tennisAwardPoint(false);

      expect(_state(c).finishedSets, isEmpty);
      expect(_state(c).tennis!.team2GamePoints, 4);
    });
  });

  group('TC-CBD-TN-07 tie-break from the configuration', () {
    const fiveSix = [SetScoreData(score1: 5, score2: 6)];

    test('6-6 starts a tie-break to 7 by default', () {
      final c = _container(_config(), sets: fiveSix);
      _points(c, true, 4);
      expect(_state(c).tennis!.isTiebreak, isTrue);

      _points(c, true, 6);
      expect(_state(c).finishedSets.last.isFinished, isFalse);
      _points(c, true, 1);
      final set = _state(c).finishedSets.last;
      expect((set.score1, set.score2, set.isFinished), (7, 6, true));
    });

    test('SUPER_10 plays the tie-break to 10', () {
      final c = _container(
        _config({'tiebreakMode': 'SUPER_10'}),
        sets: fiveSix,
      );
      _points(c, true, 4);
      _points(c, true, 9);
      expect(_state(c).finishedSets.last.isFinished, isFalse);
      _points(c, true, 1);
      expect(_state(c).finishedSets.last.isFinished, isTrue);
    });

    test('tiebreakMode NONE keeps playing until a 2 game lead', () {
      final c = _container(_config({'tiebreakMode': 'NONE'}), sets: fiveSix);
      _points(c, true, 4);
      expect(_state(c).tennis!.isTiebreak, isFalse);
      expect(_state(c).finishedSets.last.isFinished, isFalse);

      _points(c, true, 4);
      expect(_state(c).finishedSets.last.isFinished, isFalse);

      _points(c, true, 4);
      final set = _state(c).finishedSets.last;
      expect((set.score1, set.score2, set.isFinished), (8, 6, true));
    });
  });

  group('TC-CBD-TN-08 match tie-break replaces the deciding set', () {
    const level = [
      SetScoreData(score1: 6, score2: 3, isFinished: true),
      SetScoreData(score1: 3, score2: 6, isFinished: true),
    ];
    final superTb = {'finalSetMode': 'SUPER_TIEBREAK'};

    test('points count to 10 and the set is stored as 7-6', () {
      final c = _container(_config(superTb), sets: level);
      _points(c, true, 9);
      expect(_state(c).finishedSets.length, 2);
      expect(_state(c).isMatchComplete, isFalse);

      _points(c, true, 1);

      expect(_state(c).finishedSets.length, 3);
      final set = _state(c).finishedSets.last;
      expect((set.score1, set.score2, set.isFinished), (7, 6, true));
      expect(_state(c).isMatchComplete, isTrue);
      expect(_state(c).winnerTeam, 1);
    });

    test('it still needs a 2 point lead', () {
      final c = _container(_config(superTb), sets: level);
      _points(c, true, 9);
      _points(c, false, 9);
      _points(c, true, 1);
      expect(_state(c).isMatchComplete, isFalse);
      _points(c, true, 1);
      expect(_state(c).isMatchComplete, isTrue);
    });

    test('team 2 wins it as 6-7', () {
      final c = _container(_config(superTb), sets: level);
      _points(c, false, 10);
      final set = _state(c).finishedSets.last;
      expect((set.score1, set.score2), (6, 7));
      expect(_state(c).winnerTeam, 2);
    });

    test('without the key the deciding set is a normal set', () {
      final c = _container(_config(), sets: level);
      _points(c, true, 4);
      final set = _state(c).finishedSets.last;
      expect((set.score1, set.score2, set.isFinished), (1, 0, false));
    });
  });
}
