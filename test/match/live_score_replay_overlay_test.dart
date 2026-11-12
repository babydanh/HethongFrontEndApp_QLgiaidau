import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/socket_providers.dart';
import 'package:app_quanly_giaidau/core/services/match_socket_service.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/data/models/match_playback_model.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/features/match/screens/live_score_screen.dart';
import 'package:app_quanly_giaidau/features/match/widgets/live_video_box.dart';
import 'package:app_quanly_giaidau/features/match/widgets/live_video_player.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/match_score_access_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'fake_video_player_platform.dart';

const _tournamentId = 'tournament-replay-overlay';
const _matchId = 'match-replay-overlay';

const _viewerAuth = AuthState(
  status: AuthStatus.authenticated,
  role: UserRole.viewer,
  tournamentId: _tournamentId,
);

class _FixedAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => _viewerAuth;
}

class _SilentMatchSocket extends Fake implements MatchSocketService {
  @override
  Future<void> connect(String? matchId, {bool joinMatch = true}) async {}

  @override
  void leave(String matchId) {}

  @override
  Stream<Map<String, dynamic>> get onCommentNew => const Stream.empty();

  @override
  Stream<Map<String, dynamic>> get onCheerUpdate => const Stream.empty();
}

/// A finished match whose server flags are still ON: the replay must ignore them.
MatchModel _finishedMatch() => MatchModel(
  id: _matchId,
  tournamentId: _tournamentId,
  round: 1,
  matchNumber: 1,
  team1Id: 'team-alpha',
  team2Id: 'team-beta',
  team1Name: 'Team Alpha',
  team2Name: 'Team Beta',
  score1: 11,
  score2: 7,
  status: 'COMPLETED',
  bracketPosition: BracketPosition(round: 1, position: 1),
  updatedAt: DateTime.utc(2026, 10, 15),
  h2hOverlayVisible: true,
  bracketOverlayVisible: true,
);

MatchModel _bracketMatch(int round, int number) => MatchModel(
  id: 'bracket-$round-$number',
  tournamentId: _tournamentId,
  round: round,
  matchNumber: number,
  team1Id: 't-$round-$number-a',
  team2Id: 't-$round-$number-b',
  team1Name: 'R${round}M$number Alpha',
  team2Name: 'R${round}M$number Beta',
  status: 'SCHEDULED',
  bracketPosition: BracketPosition(round: round, position: number),
  updatedAt: DateTime.utc(2026, 10, 15),
);

MatchReplay _replay(List<Map<String, Object?>> overlayEvents) =>
    MatchReplay.fromJson(<String, Object?>{
      'matchId': _matchId,
      'available': true,
      'startedAt': null,
      'endedAt': null,
      'durationSec': 60,
      'overlayEvents': overlayEvents,
      'segments': <Object?>[
        <String, Object?>{
          'name': 'clip.mp4',
          'url': 'https://media.example.test/clip.mp4',
          'startAt': '2026-10-20T14:49:08+07:00',
          'offsetSec': 0,
          'clipStartSec': 0,
          'durationSec': 60,
        },
      ],
    });

Map<String, Object?> _event(String kind, bool visible, num at) =>
    <String, Object?>{'kind': kind, 'visible': visible, 'offsetSec': at};

const _liveStream = MatchPlaybackModel(
  matchId: _matchId,
  streamStatus: StreamStatus.live,
  playbackUrl: 'https://media.example.test/live/camera_new/hls.m3u8',
  cameraName: 'cam',
);

Future<void> _pumpReplay(
  WidgetTester tester,
  List<Map<String, Object?>> overlayEvents, {
  MatchPlaybackModel? live,
  bool recordingAvailable = true,
}) async {
  VideoPlayerPlatform.instance = FakeVideoPlayerPlatform();
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith(_FixedAuthNotifier.new),
        singleMatchProvider.overrideWith(
          (ref, params) => Stream.value(_finishedMatch()),
        ),
        tournamentProvider.overrideWith((ref, id) => Stream.value(null)),
        viewerCountProvider.overrideWith((ref, id) => Stream.value(0)),
        // No live stream: LiveVideoBox falls through to the recording.
        matchPlaybackProvider.overrideWith((ref, id) => Future.value(live)),
        matchReplayProvider.overrideWith(
          (ref, id) => Future.value(
            recordingAvailable ? _replay(overlayEvents) : null,
          ),
        ),
        bracketMatchesWithDivisionProvider.overrideWith(
          (ref, params) => Stream.value([
            for (var n = 1; n <= 2; n++) _bracketMatch(1, n),
            _bracketMatch(2, 1),
          ]),
        ),
        matchScoreAccessProvider.overrideWith((ref, id) => Future.value(false)),
        userProfileProvider.overrideWith(
          (ref) async => UserProfile(id: 'user-1', fullName: 'U', email: ''),
        ),
        matchSocketServiceProvider.overrideWithValue(_SilentMatchSocket()),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const LiveScoreScreen(
          tournamentId: _tournamentId,
          matchId: _matchId,
          isViewer: true,
        ),
      ),
    ),
  );
  // The page has looping animations, so pumpAndSettle would never settle.
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
}

const _forward = ValueKey<String>('replay-skip-forward');
const _back = ValueKey<String>('replay-skip-back');
final _h2h = find.byKey(const ValueKey('live-overlay-h2h'));
final _bracket = find.byKey(const ValueKey('live-overlay-bracket'));

/// One skip button press moves the replay 3 s; wait out the overlay motion.
Future<void> _skip(WidgetTester tester, Key button) async {
  await tester.tap(find.byKey(button));
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'TC-REPLAYOV-11 H2H shows only inside its on/off window of the recording',
    (tester) async {
      await _pumpReplay(tester, [
        _event('H2H', true, 3),
        _event('H2H', false, 6),
      ]);
      expect(find.byType(LiveVideoBox), findsOneWidget);
      // At 0 s: the finished match still has the server flag on, yet nothing shows.
      expect(_h2h, findsNothing);
      expect(_bracket, findsNothing);

      await _skip(tester, _forward); // 3 s
      expect(_h2h, findsOneWidget);

      await _skip(tester, _forward); // 6 s
      expect(_h2h, findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('TC-REPLAYOV-12 the bracket overlay follows its own events', (
    tester,
  ) async {
    await _pumpReplay(tester, [
      _event('BRACKET', true, 3),
      _event('BRACKET', false, 6),
    ]);
    expect(_bracket, findsNothing);

    await _skip(tester, _forward); // 3 s
    expect(_bracket, findsOneWidget);
    expect(_h2h, findsNothing);

    // The bracket covers the skip buttons, so seek past the off event on the
    // timeline bar, which stays below the panel.
    final bar = find.byKey(const ValueKey<String>('match-replay-timeline'));
    await tester.tapAt(tester.getRect(bar).centerRight - const Offset(16, 0));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(_bracket, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'TC-REPLAYOV-13 X hides the panel, and seeking out then back brings it again',
    (tester) async {
      await _pumpReplay(tester, [
        _event('H2H', true, 3),
        _event('H2H', false, 6),
      ]);
      await _skip(tester, _forward); // 3 s
      expect(_h2h, findsOneWidget);

      await tester.tap(
        find.descendant(of: _h2h, matching: find.byIcon(Icons.close)),
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(_h2h, findsNothing);

      await _skip(tester, _forward); // 6 s: window over
      await _skip(tester, _back); // 3 s: inside the window again
      expect(_h2h, findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'TC-REPLAYOV-15 a live stream and a recording together: live first, a button switches to the recording and the overlay follows it',
    (tester) async {
      await _pumpReplay(tester, [
        _event('H2H', true, 3),
        _event('H2H', false, 6),
      ], live: _liveStream);
      expect(find.byType(LiveVideoPlayer), findsOneWidget);
      expect(find.byKey(const ValueKey('match-replay-player')), findsNothing);

      final toggle = find.byKey(const ValueKey('live-replay-toggle'));
      expect(toggle, findsOneWidget);
      await tester.tap(toggle);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(LiveVideoPlayer), findsNothing);
      expect(find.byKey(const ValueKey('match-replay-player')), findsOneWidget);
      expect(_h2h, findsNothing); // 0 s: the recording's own events, not the server flag
      await _skip(tester, _forward); // 3 s
      expect(_h2h, findsOneWidget);

      await tester.tap(toggle); // back to live
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(LiveVideoPlayer), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('TC-REPLAYOV-16 a live stream without a recording has no button', (
    tester,
  ) async {
    await _pumpReplay(tester, const [], live: _liveStream, recordingAvailable: false);

    expect(find.byType(LiveVideoPlayer), findsOneWidget);
    expect(find.byKey(const ValueKey('live-replay-toggle')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'TC-REPLAYOV-14 a recording without events shows no overlay, whatever the server flags say',
    (tester) async {
      await _pumpReplay(tester, const []);
      await _skip(tester, _forward);

      expect(_h2h, findsNothing);
      expect(_bracket, findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
