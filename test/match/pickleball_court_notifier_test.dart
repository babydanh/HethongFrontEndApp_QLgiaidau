import 'dart:async';

import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_repository.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/pickleball_court_notifier.dart';
import 'package:app_quanly_giaidau/features/match/utils/pickleball_court.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _params = (tournamentId: 'tournament-1', matchId: 'match-1');

const _sideOutContext = CourtContext(
  score1: 0,
  score2: 0,
  isDoubles: true,
  team1PlayerCount: 2,
  team2PlayerCount: 2,
  servingTeam: 1,
  serverNumber: 1,
  scoringMode: CourtScoringMode.sideOut,
  setIndex: 0,
  targetPoints: 11,
  isDecidingSet: false,
);

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
  _Harness({CourtContext? context = _sideOutContext}) {
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
  late final ProviderContainer container;

  PickleballCourtNotifier get notifier =>
      container.read(pickleballCourtNotifierProvider(_params).notifier);

  CourtState get state => container.read(pickleballCourtNotifierProvider(_params));

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

  test(
    'syncAutomatic writes the opened turn once, then nothing new',
    () async {
      final harness = _Harness();
      addTearDown(harness.dispose);
      harness.matches.add(_match());
      await harness.settle();

      await harness.notifier.syncAutomatic();
      expect(harness.repository.requests, hasLength(1));
      expect(harness.repository.requests.single['turnStart'], isNotNull);

      await harness.notifier.syncAutomatic();
      expect(harness.repository.requests, hasLength(1));
    },
  );

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
}
