import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/match_playback_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_playback_repository.dart';
import 'package:app_quanly_giaidau/features/match/widgets/live_video_box.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeMatchPlaybackRepository implements IMatchPlaybackRepository {
  _FakeMatchPlaybackRepository(this.replay);

  final MatchReplay replay;
  int replayCalls = 0;

  @override
  Future<MatchPlaybackModel> getMatchPlayback(String matchId) async =>
      MatchPlaybackModel.fromJson(<String, Object?>{
        'matchId': matchId,
        'streamStatus': 'OFFLINE',
        'playbackUrl': null,
      });

  @override
  Future<MatchReplay> getMatchReplay(String matchId) async {
    replayCalls++;
    return replay;
  }
}

MatchReplay _replay({required bool available, String? reason}) =>
    MatchReplay.fromJson(<String, Object?>{
      'matchId': 'match-1',
      'available': available,
      'reason': reason,
      'startedAt': null,
      'endedAt': null,
      'durationSec': available ? 20 : 0,
      'segments': available
          ? <Object?>[
              <String, Object?>{
                'name': 'clip.mp4',
                'url': 'https://media.example.test/clip.mp4',
                'startAt': '2026-10-20T14:49:08+07:00',
                'offsetSec': 0,
                'clipStartSec': 0,
                'durationSec': 20,
              },
            ]
          : <Object?>[],
    });

Future<void> _pumpBox(
  WidgetTester tester,
  _FakeMatchPlaybackRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        matchPlaybackRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: LiveVideoBox(matchId: 'match-1'),
            ),
          ),
        ),
      ),
    ),
  );
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows replay player when the finished match has a recording', (
    tester,
  ) async {
    final repository = _FakeMatchPlaybackRepository(_replay(available: true));

    await _pumpBox(tester, repository);

    expect(
      find.byKey(const ValueKey<String>('match-replay-player')),
      findsOneWidget,
    );
    expect(repository.replayCalls, 1);
  });

  testWidgets(
    'keeps no-signal view and does not show replay for NOT_FINISHED',
    (tester) async {
      final repository = _FakeMatchPlaybackRepository(
        _replay(available: false, reason: 'NOT_FINISHED'),
      );

      await _pumpBox(tester, repository);

      expect(
        find.byKey(const ValueKey<String>('match-replay-player')),
        findsNothing,
      );
      expect(find.byIcon(Icons.videocam_outlined), findsOneWidget);
      expect(repository.replayCalls, 1);
    },
  );
}
