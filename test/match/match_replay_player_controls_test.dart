import 'dart:async';

import 'package:app_quanly_giaidau/data/models/match_playback_model.dart';
import 'package:app_quanly_giaidau/features/match/widgets/match_replay_player.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

/// In-memory player: initialises at once and records what the app asks of it.
class _FakeVideoPlayerPlatform extends VideoPlayerPlatform {
  final volumes = <double>[];
  final seeks = <Duration>[];
  final _events = <int, StreamController<VideoEvent>>{};
  Duration duration = const Duration(seconds: 60);

  @override
  Future<void> init() async {}

  @override
  Future<void> dispose(int playerId) async {}

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    final id = _events.length + 1;
    _events[id] = StreamController<VideoEvent>(
      onListen: () => _events[id]!.add(
        VideoEvent(
          eventType: VideoEventType.initialized,
          duration: duration,
          size: const Size(1280, 720),
        ),
      ),
    );
    return id;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => _events[playerId]!.stream;

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> play(int playerId) async {}

  @override
  Future<void> pause(int playerId) async {}

  @override
  Future<void> setVolume(int playerId, double volume) async =>
      volumes.add(volume);

  @override
  Future<void> seekTo(int playerId, Duration position) async =>
      seeks.add(position);

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<Duration> getPosition(int playerId) async =>
      seeks.lastOrNull ?? Duration.zero;

  @override
  Widget buildView(int playerId) => const SizedBox.expand();
}

MatchReplay _replay(int durationSec) => MatchReplay.fromJson(<String, Object?>{
  'matchId': 'match-1',
  'available': true,
  'startedAt': null,
  'endedAt': null,
  'durationSec': durationSec,
  'segments': <Object?>[
    <String, Object?>{
      'name': 'clip.mp4',
      'url': 'https://media.example.test/clip.mp4',
      'startAt': '2026-10-20T14:49:08+07:00',
      'offsetSec': 0,
      'clipStartSec': 0,
      'durationSec': durationSec,
    },
  ],
});

const _centre = ValueKey<String>('replay-center-controls');
const _back = ValueKey<String>('replay-skip-back');
const _forward = ValueKey<String>('replay-skip-forward');
const _timeline = ValueKey<String>('match-replay-timeline');

/// 400dp wide, so the picture is the 400 x 225dp video of a phone.
Future<_FakeVideoPlayerPlatform> _pump(
  WidgetTester tester, {
  int durationSec = 60,
  List<bool>? visibility,
}) async {
  final platform = _FakeVideoPlayerPlatform()
    ..duration = Duration(seconds: durationSec);
  VideoPlayerPlatform.instance = platform;
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('vi'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 400,
            child: MatchReplayPlayer(
              replay: _replay(durationSec),
              onControlsVisibleChanged: visibility?.add,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
  return platform;
}

Finder _picture() => find.byKey(const ValueKey<String>('match-replay-player'));

/// Tap the empty top-left of the picture: no control lives there.
Future<void> _tapPicture(WidgetTester tester) async {
  await tester.tapAt(tester.getTopLeft(_picture()) + const Offset(20, 20));
  await tester.pump(const Duration(milliseconds: 250));
}

bool _shown(WidgetTester tester, Key key) {
  final ignore = find.ancestor(
    of: find.byKey(key),
    matching: find.byType(IgnorePointer),
  );
  return !tester.widget<IgnorePointer>(ignore.first).ignoring;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('TC-REPLAY-01 opens with sound on (volume 1)', (tester) async {
    final platform = await _pump(tester);

    expect(platform.volumes, isNotEmpty);
    expect(platform.volumes.last, 1.0);
    expect(find.byIcon(Icons.volume_up), findsOneWidget);
    expect(find.byIcon(Icons.volume_off), findsNothing);
  });

  testWidgets('TC-REPLAY-02 the sound button still mutes and unmutes', (
    tester,
  ) async {
    final platform = await _pump(tester);

    await tester.tap(find.byIcon(Icons.volume_up));
    await tester.pump();
    expect(platform.volumes.last, 0.0);
    expect(find.byIcon(Icons.volume_off), findsOneWidget);

    await tester.tap(find.byIcon(Icons.volume_off));
    await tester.pump();
    expect(platform.volumes.last, 1.0);
  });

  testWidgets(
    'TC-REPLAY-03 centre layer hides after 3s and a tap brings it back',
    (tester) async {
      await _pump(tester);
      expect(_shown(tester, _centre), isTrue);

      await tester.pump(const Duration(milliseconds: 2800));
      expect(_shown(tester, _centre), isTrue);
      await tester.pump(const Duration(milliseconds: 400));
      expect(_shown(tester, _centre), isFalse);

      await _tapPicture(tester);
      expect(_shown(tester, _centre), isTrue);
      // The bottom bar follows the same switch.
      expect(_shown(tester, _timeline), isTrue);

      // A second tap hides both again.
      await _tapPicture(tester);
      expect(_shown(tester, _centre), isFalse);
      expect(_shown(tester, _timeline), isFalse);
    },
  );

  testWidgets(
    'TC-REPLAY-04 skip buttons seek 3s and stay inside [0, duration]',
    (tester) async {
      final platform = await _pump(tester, durationSec: 5);
      platform.seeks.clear();

      await tester.tap(find.byKey(_back)); // already at 0: stays at 0
      await tester.pump();
      expect(platform.seeks.last, Duration.zero);

      await tester.tap(find.byKey(_forward));
      await tester.pump();
      expect(platform.seeks.last, const Duration(seconds: 3));

      await tester.tap(find.byKey(_forward)); // 6s would pass the 5s end
      await tester.pump();
      expect(platform.seeks.last, const Duration(seconds: 5));
    },
  );

  testWidgets('TC-REPLAY-05 reports when the control layer is up or down', (
    tester,
  ) async {
    final seen = <bool>[];
    await _pump(tester, visibility: seen);
    expect(seen, [true]);

    await tester.pump(const Duration(seconds: 4));
    expect(seen, [true, false]);
  });
}
