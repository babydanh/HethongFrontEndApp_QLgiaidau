import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/match_playback_model.dart';
import 'package:app_quanly_giaidau/data/models/match_suggestion_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_playback_repository.dart';
import 'package:app_quanly_giaidau/features/match/widgets/live_embed_player.dart';
import 'package:app_quanly_giaidau/features/match/widgets/live_video_box.dart';
import 'package:app_quanly_giaidau/features/match/widgets/match_replay_player.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_webview_platform.dart';

class _FakeRepository implements IMatchPlaybackRepository {
  _FakeRepository(this.replay);

  final MatchReplay replay;

  @override
  Future<MatchPlaybackModel> getMatchPlayback(String matchId) async =>
      MatchPlaybackModel.fromJson(<String, Object?>{
        'matchId': matchId,
        'streamStatus': 'OFFLINE',
        'playbackUrl': null,
      });

  @override
  Future<MatchReplay> getMatchReplay(String matchId) async => replay;

  @override
  Future<MatchSuggestionsPage> getMatchSuggestions(
    String matchId, {
    String? cursor,
  }) => throw UnimplementedError();
}

MatchReplay _linkOnlyReplay(String? externalUrl) =>
    MatchReplay.fromJson(<String, Object?>{
      'matchId': 'match-1',
      'available': true,
      'reason': null,
      'startedAt': null,
      'endedAt': null,
      'durationSec': 0,
      'segments': <Object?>[],
      'externalUrl': externalUrl,
    });

Future<void> _pumpBox(WidgetTester tester, MatchReplay replay) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        matchPlaybackRepositoryProvider.overrideWithValue(
          _FakeRepository(replay),
        ),
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
  setUp(FakeWebViewPlatform.install);

  testWidgets(
    'TC-FBREPLAY-APP-06 a finished Facebook live replays from its watch link',
    (tester) async {
      await _pumpBox(
        tester,
        _linkOnlyReplay('https://www.facebook.com/watch/?v=1234567890'),
      );

      expect(find.byType(LiveEmbedPlayer), findsOneWidget);
      expect(find.byType(MatchReplayPlayer), findsNothing);
      expect(FakeWebViewPlatform.loadedHtml, hasLength(1));
      expect(
        FakeWebViewPlatform.loadedHtml.single,
        contains('facebook.com/plugins/video.php'),
      );
    },
  );

  testWidgets(
    'TC-FBREPLAY-APP-07 a link that is not an allowed embed shows no signal',
    (tester) async {
      await _pumpBox(
        tester,
        _linkOnlyReplay('https://evil.example/watch/?v=1'),
      );

      expect(find.byType(LiveEmbedPlayer), findsNothing);
      expect(find.byType(MatchReplayPlayer), findsNothing);
      expect(FakeWebViewPlatform.loadedHtml, isEmpty);
    },
  );
}
