import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/match_playback_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_playback_repository.dart';
import 'package:app_quanly_giaidau/features/match/widgets/live_video_box.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _matchId = 'match-1';

MatchReplay _replay({required bool available}) => MatchReplay(
  matchId: _matchId,
  available: available,
  reason: null,
  startedAt: null,
  endedAt: null,
  durationSec: 0,
  segments: const [],
  externalUrl: available ? 'https://www.youtube.com/watch?v=dQw4w9WgXcQ' : null,
);

/// No live stream; the replay answers come from [replays] in order (an
/// [Exception] entry is thrown), the last one repeats.
class _Playback extends Fake implements IMatchPlaybackRepository {
  _Playback(this.replays);

  final List<Object> replays;
  int replayCalls = 0;

  @override
  Future<MatchPlaybackModel> getMatchPlayback(String matchId) async =>
      const MatchPlaybackModel(
        matchId: _matchId,
        streamStatus: StreamStatus.idle,
        playbackUrl: null,
        cameraName: null,
      );

  @override
  Future<MatchReplay> getMatchReplay(String matchId) async {
    final i = replayCalls < replays.length ? replayCalls : replays.length - 1;
    replayCalls++;
    final answer = replays[i];
    if (answer is Exception) throw answer;
    return answer as MatchReplay;
  }
}

ProviderContainer _container(_Playback repo) {
  final container = ProviderContainer(
    overrides: [matchPlaybackRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'TC-TENNIS-OVL-APP-03 reopening the match asks for the recording again '
    'instead of keeping the old "no recording" answer',
    () async {
      final repo = _Playback([
        _replay(available: false),
        _replay(available: true),
      ]);
      final container = _container(repo);

      final first = container.listen(matchReplayProvider(_matchId), (_, _) {});
      expect(await container.read(matchReplayProvider(_matchId).future), isNull);
      first.close();
      // The screen is gone: the provider is disposed after a frame.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      container.listen(matchReplayProvider(_matchId), (_, _) {});
      final again = await container.read(matchReplayProvider(_matchId).future);
      expect(again, isNotNull);
    },
  );

  test(
    'TC-TENNIS-OVL-APP-04 a failed recording lookup is tried again, not kept '
    'as "no recording"',
    () async {
      final repo = _Playback([
        Exception('Connection timed out'),
        _replay(available: true),
      ]);
      final container = _container(repo);
      container.listen(matchReplayProvider(_matchId), (_, _) {});

      await Future<void>.delayed(const Duration(seconds: 2));

      expect(
        container.read(matchReplayProvider(_matchId)).asData?.value,
        isNotNull,
      );
    },
  );

  testWidgets(
    'TC-TENNIS-OVL-APP-05 the recording is looked up again when the match '
    'changes status',
    (tester) async {
      final repo = _Playback([_replay(available: false)]);
      Widget app(String status) => ProviderScope(
        overrides: [matchPlaybackRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: LiveVideoBox(matchId: _matchId, matchStatus: status),
          ),
        ),
      );

      await tester.pumpWidget(app('ONGOING'));
      await tester.pumpAndSettle();
      expect(repo.replayCalls, 1);

      await tester.pumpWidget(app('COMPLETED'));
      await tester.pumpAndSettle();
      expect(repo.replayCalls, 2);
    },
  );
}
