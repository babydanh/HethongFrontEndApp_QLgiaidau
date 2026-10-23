import 'dart:async';

import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_repository.dart';
import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/pickleball_court_notifier.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_notifier.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_state.dart';
import 'package:app_quanly_giaidau/features/match/utils/pickleball_court.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _params = (tournamentId: 'tournament-1', matchId: 'match-1');

CourtContext _contextFor({int? servingTeam = 1, int score1 = 0, int score2 = 0}) {
  return CourtContext(
    score1: score1,
    score2: score2,
    isDoubles: true,
    team1PlayerCount: 2,
    team2PlayerCount: 2,
    servingTeam: servingTeam,
    serverNumber: 1,
    scoringMode: CourtScoringMode.sideOut,
    setIndex: 0,
    targetPoints: 11,
    isDecidingSet: false,
  );
}

MatchModel _match({Map<String, dynamic>? courtState}) => MatchModel.fromJson({
  'id': 'match-1',
  'tournamentId': 'tournament-1',
  'status': 'LIVE',
  if (courtState != null) 'scoreDetails': {'courtState': courtState},
}, 'match-1');

/// Echo lại courtState như server: trả match mang đúng courtState vừa ghi.
class _EchoCourtRepository extends Fake implements IMatchRepository {
  final requests = <Map<String, dynamic>>[];
  Object? failWith;

  @override
  Future<MatchModel> updateCourtState(
    String matchId,
    Map<String, dynamic> courtState,
  ) async {
    requests.add(courtState);
    final error = failWith;
    if (error != null) throw error;
    return _match(courtState: courtState);
  }
}

class _Harness {
  _Harness() {
    container = ProviderContainer(
      overrides: [
        singleMatchProvider.overrideWith((ref, params) => matches.stream),
        pickleballCourtContextProvider.overrideWith((ref, params) => context),
        matchRepositoryProvider.overrideWithValue(repository),
      ],
    );
    container.listen(pickleballCourtNotifierProvider(_params), (_, _) {});
  }

  final matches = StreamController<MatchModel?>.broadcast();
  final repository = _EchoCourtRepository();
  CourtContext? context = _contextFor();
  late final ProviderContainer container;

  PickleballCourtNotifier get notifier =>
      container.read(pickleballCourtNotifierProvider(_params).notifier);

  CourtState get state => container.read(pickleballCourtNotifierProvider(_params));

  /// Đổi ngữ cảnh điểm (như sau một điểm) rồi làm mới provider ngữ cảnh.
  void setContext(CourtContext? next) {
    context = next;
    container.invalidate(pickleballCourtContextProvider(_params));
  }

  Future<void> settle() async {
    for (var i = 0; i < 3; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  Future<void> dispose() async {
    container.dispose();
    await matches.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('mở màn chỉ suy lượt tại chỗ, không ghi server', () async {
    final harness = _Harness();
    addTearDown(harness.dispose);
    harness.matches.add(_match());
    await harness.settle();

    final error = await harness.notifier.syncAutomatic();

    expect(error, isNull);
    expect(harness.repository.requests, isEmpty);
    expect(harness.state.turnStart?.team, 1);
  });

  test('lượt giao đổi sau mở màn thì ghi đúng một lần', () async {
    final harness = _Harness();
    addTearDown(harness.dispose);
    harness.matches.add(_match());
    await harness.settle();
    await harness.notifier.syncAutomatic();

    harness.setContext(_contextFor(servingTeam: 2));
    await harness.notifier.syncAutomatic();
    expect(harness.repository.requests, hasLength(1));
    final turn = harness.repository.requests.single['turnStart'] as Map;
    expect(turn['team'], 2);

    await harness.notifier.syncAutomatic();
    expect(harness.repository.requests, hasLength(1));
  });

  test('socket không có lượt giao thì giữ lượt suy tại chỗ', () async {
    final harness = _Harness();
    addTearDown(harness.dispose);
    harness.matches.add(_match());
    await harness.settle();
    await harness.notifier.syncAutomatic();

    harness.matches.add(_match());
    await harness.settle();

    expect(harness.state.turnStart?.team, 1);
    expect(harness.repository.requests, isEmpty);
  });

  test('apply writes the changed setting and adopts the saved court', () async {
    final harness = _Harness();
    addTearDown(harness.dispose);
    harness.matches.add(_match());
    await harness.settle();

    final error = await harness.notifier.apply(
      (state, context) => setAutoSwitchEnds(state, context, false),
    );

    expect(error, isNull);
    expect(harness.repository.requests, hasLength(1));
    expect(harness.repository.requests.single['autoSwitchEnds'], isFalse);
    expect(harness.state.autoSwitchEnds, isFalse);
  });

  test('a failed write reverts to the last server court and reports it', () async {
    final harness = _Harness();
    addTearDown(harness.dispose);
    harness.matches.add(_match());
    await harness.settle();
    harness.repository.failWith = Exception('Lỗi mạng');

    final error = await harness.notifier.apply(
      (state, context) => setAutoSwitchEnds(state, context, false),
    );

    expect(error, isA<Exception>());
    expect(harness.state.autoSwitchEnds, isTrue);
  });

  test('a socket update replaces the court when no write is pending', () async {
    final harness = _Harness();
    addTearDown(harness.dispose);
    harness.matches.add(_match());
    await harness.settle();

    harness.matches.add(
      _match(courtState: const CourtState(autoSwitchEnds: false).toJson()),
    );
    await harness.settle();

    expect(harness.state.autoSwitchEnds, isFalse);
    expect(harness.repository.requests, isEmpty);
  });

  test('mỗi loại lỗi ghi chỉ báo một lần trong phiên', () async {
    final harness = _Harness();
    addTearDown(harness.dispose);
    harness.matches.add(_match());
    await harness.settle();

    expect(harness.notifier.claimErrorReport('404'), isTrue);
    expect(harness.notifier.claimErrorReport('404'), isFalse);
    expect(harness.notifier.claimErrorReport('Lỗi mạng'), isTrue);
  });

  _realContextTests();
}

// ---- Real court context (no override): rule decides side-out ----

SportConfig _sideOutConfig() => const SportConfig(
  kind: SportRuleKind.pickleball,
  scoringModel: SportScoringModel.pickleballSideOut,
  bestOf: 3,
  setsToWin: 2,
  pointsPerSet: 11,
  mustWinByTwo: true,
  maxPoints: 0,
  tiebreakAt: 0,
);

ScorePanelState _scoreState({
  int score1 = 0,
  int score2 = 0,
  PickleballServeState? serve,
}) => ScorePanelState(
  config: _sideOutConfig(),
  pickleball: serve,
  rally: RallySetState(currentP1: score1, currentP2: score2),
);

/// Score panel whose state a test sets directly.
class _SettableScorePanel extends ScorePanelNotifier {
  _SettableScorePanel(super.arg, this.initial);

  final ScorePanelState initial;

  @override
  ScorePanelState build() => initial;

  void set(ScorePanelState next) => state = next;
}

class _RealContextHarness {
  _RealContextHarness() {
    container = ProviderContainer(
      overrides: [
        singleMatchProvider.overrideWith(
          (ref, params) => Stream.value(
            MatchModel.fromJson({
              'id': 'match-1',
              'tournamentId': 'tournament-1',
              'status': 'LIVE',
              'team1Members': ['A', 'B'],
              'team2Members': ['C', 'D'],
            }, 'match-1'),
          ),
        ),
        scorePanelNotifierProvider.overrideWith2(
          (arg) => _SettableScorePanel(arg, _scoreState()),
        ),
        matchRepositoryProvider.overrideWithValue(repository),
      ],
    );
    container.listen(pickleballCourtNotifierProvider(_params), (_, _) {});
  }

  final repository = _EchoCourtRepository();
  late final ProviderContainer container;

  PickleballCourtNotifier get notifier =>
      container.read(pickleballCourtNotifierProvider(_params).notifier);

  CourtState get state =>
      container.read(pickleballCourtNotifierProvider(_params));

  CourtContext get context =>
      container.read(pickleballCourtContextProvider(_params))!;

  void setScore(ScorePanelState next) =>
      (container.read(scorePanelNotifierProvider(_params).notifier)
              as _SettableScorePanel)
          .set(next);

  Future<void> settle() async {
    for (var i = 0; i < 3; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }
}

void _realContextTests() {
  group('side-out rule without serve state (real court context)', () {
    test('the context is side-out with team 1 serving at 0-0', () async {
      final harness = _RealContextHarness();
      addTearDown(harness.container.dispose);
      await harness.settle();

      expect(harness.context.scoringMode, CourtScoringMode.sideOut);
      expect(harness.context.servingTeam, 1);
      expect(harness.context.serverNumber, 1);
    });

    test('moving the ball to the partner at 0-0 keeps the override', () async {
      final harness = _RealContextHarness();
      addTearDown(harness.container.dispose);
      await harness.settle();
      await harness.notifier.syncAutomatic();

      await harness.notifier.apply(
        (state, context) => setServerOverride(state, context, 1, 1),
      );

      final layout = resolveCourtLayout(harness.state, harness.context);
      expect(harness.state.serverOverride?.playerIndex, 1);
      expect(layout.serverPlayerIndex, 1);
      expect(harness.state.turnStart, isNotNull);
    });

    test('the first point keeps the first server serving', () async {
      final harness = _RealContextHarness();
      addTearDown(harness.container.dispose);
      await harness.settle();
      await harness.notifier.syncAutomatic();
      final server = resolveCourtLayout(
        harness.state,
        harness.context,
      ).serverPlayerIndex;

      harness.setScore(
        _scoreState(score1: 1, serve: const PickleballServeState()),
      );
      await harness.notifier.syncAutomatic();

      final layout = resolveCourtLayout(harness.state, harness.context);
      expect(layout.serverPlayerIndex, server);
      expect(harness.state.turnStart?.serverPlayerIndex, server);
    });
  });
}
