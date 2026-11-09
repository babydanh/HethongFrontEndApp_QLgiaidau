import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/socket_providers.dart';
import 'package:app_quanly_giaidau/core/services/match_socket_service.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/data/models/match_playback_model.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/features/match/screens/live_score_screen.dart';
import 'package:app_quanly_giaidau/features/match/widgets/live_overlay_controls.dart';
import 'package:app_quanly_giaidau/features/match/widgets/live_video_box.dart';
import 'package:app_quanly_giaidau/features/match/widgets/viewer/live_scoreboard_overlay.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/match_score_access_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'fake_video_player_platform.dart';

const _tournamentId = 'tournament-live-header';
const _matchId = 'match-live-header';

const _refereeAuth = AuthState(
  status: AuthStatus.authenticated,
  role: UserRole.referee,
  tournamentId: _tournamentId,
);

const _adminAuth = AuthState(
  status: AuthStatus.authenticated,
  role: UserRole.admin,
);

const _organizerAuth = AuthState(
  status: AuthStatus.authenticated,
  role: UserRole.organizer,
);

const _viewerAuth = AuthState(
  status: AuthStatus.authenticated,
  role: UserRole.viewer,
  tournamentId: _tournamentId,
);

class _FixedAuthNotifier extends AuthNotifier {
  _FixedAuthNotifier(this._state);

  final AuthState _state;

  @override
  AuthState build() => _state;
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

MatchModel _match({
  String status = 'LIVE',
  bool scoreboardVisible = true,
  int round = 1,
  String? matchCode,
  bool h2hOverlayVisible = false,
  bool bracketOverlayVisible = false,
  Map<String, dynamic>? scoreDetails,
}) {
  return MatchModel(
    scoreDetails: scoreDetails,
    id: _matchId,
    tournamentId: _tournamentId,
    round: round,
    matchNumber: 1,
    matchCode: matchCode,
    team1Id: 'team-alpha',
    team2Id: 'team-beta',
    team1Name: 'Team Alpha',
    team2Name: 'Team Beta',
    score1: 3,
    score2: 1,
    status: status,
    bracketPosition: BracketPosition(round: round, position: 1),
    updatedAt: DateTime.utc(2026, 10, 15),
    refereeName: 'Trong tai A',
    scoreboardVisible: scoreboardVisible,
    h2hOverlayVisible: h2hOverlayVisible,
    bracketOverlayVisible: bracketOverlayVisible,
  );
}

/// One knockout match for the bracket overlay; team names carry round/number.
MatchModel _bracketMatch(int round, int number) {
  return MatchModel(
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
}

/// Four, two and one match: three columns, the first one four cards tall.
final _bracketMatches = [
  for (var n = 1; n <= 4; n++) _bracketMatch(1, n),
  for (var n = 1; n <= 2; n++) _bracketMatch(2, n),
  _bracketMatch(3, 1),
];

final _livePlayback = MatchPlaybackModel.fromJson(<String, Object?>{
  'matchId': _matchId,
  'streamStatus': 'LIVE',
  'playbackUrl': 'https://media.example.test/live/stream.flv',
  'cameraName': 'Sân 1',
});

Future<void> _pumpLiveScreen(
  WidgetTester tester, {
  required AuthState auth,
  required MatchModel match,
  bool isViewer = true,
  bool? scoreAccess,
  bool withVideo = true,
  Size size = const Size(390, 844),
  bool playVideo = false,
  FakeViewPadding padding = FakeViewPadding.zero,
}) async {
  // A real (fake-platform) picture, so the tests can measure where it is drawn.
  if (playVideo) VideoPlayerPlatform.instance = FakeVideoPlayerPlatform();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  // A camera cutout: the unsafe strip on one side of a landscape phone.
  tester.view.padding = padding;
  tester.view.viewPadding = padding;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.view.resetPadding();
    tester.view.resetViewPadding();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith(() => _FixedAuthNotifier(auth)),
        singleMatchProvider.overrideWith((ref, params) => Stream.value(match)),
        tournamentProvider.overrideWith((ref, id) => Stream.value(null)),
        viewerCountProvider.overrideWith((ref, id) => Stream.value(0)),
        matchPlaybackProvider.overrideWith(
          (ref, id) => Future.value(withVideo ? _livePlayback : null),
        ),
        matchReplayProvider.overrideWith((ref, id) => Future.value(null)),
        bracketMatchesWithDivisionProvider.overrideWith(
          (ref, params) => Stream.value(_bracketMatches),
        ),
        matchScoreAccessProvider.overrideWith(
          (ref, id) => Future.value(scoreAccess),
        ),
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
        home: LiveScoreScreen(
          tournamentId: _tournamentId,
          matchId: _matchId,
          isViewer: isViewer,
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  if (playVideo) {
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
  }
}

Finder _appBarScoringIcon() => find.byIcon(Icons.scoreboard_rounded);

void main() {
  group('TC-LIVEVIEW-20 one modern layout for every account', () {
    for (final entry in {
      'referee': _refereeAuth,
      'viewer': _viewerAuth,
    }.entries) {
      testWidgets('${entry.key}: no AppBar, Chat and Other videos tabs', (
        tester,
      ) async {
        await _pumpLiveScreen(
          tester,
          auth: entry.value,
          match: _match(),
          isViewer: true,
        );

        expect(find.byType(AppBar), findsNothing);
        expect(find.text('Chat'), findsOneWidget);
        expect(find.text('Score & Timeline'), findsNothing);
        expect(find.text('Discussion'), findsNothing);
        expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('referee: scoring icon on video, overlay toggles in the ⋮ menu', (
      tester,
    ) async {
      await _pumpLiveScreen(
        tester,
        auth: _refereeAuth,
        match: _match(),
        isViewer: true,
      );

      final videoBox = find.ancestor(
        of: find.byType(LiveVideoBox),
        matching: find.byType(Stack),
      );
      expect(
        find.descendant(
          of: videoBox.first,
          matching: find.byIcon(Icons.scoreboard_rounded),
        ),
        findsOneWidget,
      );
      // No toggle row anywhere on the page: the toggles hide behind ⋮.
      expect(find.byType(LiveOverlayToggleChips), findsNothing);
      expect(find.byKey(const ValueKey('live-scorer-controls')), findsNothing);
      expect(find.text('H2H'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('live-more-menu')));
      // The page has looping animations, so pumpAndSettle would never settle.
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Match details'), findsOneWidget);
      expect(find.text('Scoreboard'), findsOneWidget);
      expect(find.text('H2H'), findsOneWidget);
      expect(find.text('Bracket'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('H2H panel keeps the Web translucency (no extra fade) and comes back from the menu after X', (
      tester,
    ) async {
      await _pumpLiveScreen(
        tester,
        auth: _refereeAuth,
        match: _match(h2hOverlayVisible: true),
        isViewer: true,
      );
      final h2h = find.byKey(const ValueKey('live-overlay-h2h'));
      expect(h2h, findsOneWidget);
      // TC-OVL-OPA-01: the Web panel is only as see-through as its own
      // gradient; no Opacity wrapper may fade the text and border on top.
      expect(
        find.descendant(
          of: h2h,
          matching: find.byWidgetPredicate(
            (widget) => widget is Opacity && widget.opacity < 1,
          ),
        ),
        findsNothing,
      );

      // Hide it with its own X: the server flag is still on.
      await tester.tap(find.descendant(of: h2h, matching: find.byIcon(Icons.close)));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(h2h, findsNothing);

      // The menu must not claim H2H is on while the picture hides it.
      await tester.tap(find.byKey(const ValueKey('live-more-menu')));
      await tester.pump(const Duration(milliseconds: 400));
      final items = tester
          .widgetList<CheckedPopupMenuItem<String>>(
            find.byType(CheckedPopupMenuItem<String>),
          )
          .toList();
      expect(items.firstWhere((i) => i.value == 'h2h').checked, isFalse);
      await tester.tapAt(const Offset(5, 600)); // barrier: close the menu
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      // Choosing H2H once must bring the panel back (not flip the server flag
      // off, which would need a second tap).
      final menu = tester.widget<PopupMenuButton<String>>(
        find.byKey(const ValueKey('live-more-menu')),
      );
      menu.onSelected!('h2h');
      await tester.pump(const Duration(milliseconds: 400));
      expect(h2h, findsOneWidget);
    });

    testWidgets('viewer has no overlay toggles', (tester) async {
      await _pumpLiveScreen(
        tester,
        auth: _viewerAuth,
        match: _match(),
        isViewer: true,
      );

      expect(find.byType(LiveOverlayToggleChips), findsNothing);
      expect(find.byKey(const ValueKey('live-more-menu')), findsNothing);
      expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);
    });

    testWidgets('LIVE is a red dot by the sound button, not a header pill', (
      tester,
    ) async {
      await _pumpLiveScreen(
        tester,
        auth: _viewerAuth,
        match: _match(),
        isViewer: true,
      );

      expect(find.text('LIVE'), findsNothing);
      expect(find.byKey(const ValueKey('live-dot')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('no live dot once the match is over', (tester) async {
      await _pumpLiveScreen(
        tester,
        auth: _viewerAuth,
        match: _match(status: 'COMPLETED'),
        isViewer: true,
      );

      expect(find.byKey(const ValueKey('live-dot')), findsNothing);
    });
  });

  testWidgets(
    'trọng tài thấy icon bấm điểm ở header khi mở trận live từ thẻ trận (route viewer)',
    (tester) async {
      await _pumpLiveScreen(
        tester,
        auth: _refereeAuth,
        match: _match(),
        isViewer: true,
      );

      expect(_appBarScoringIcon(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('trọng tài thấy icon bấm điểm khi mở trực tiếp (không viewer)', (
    tester,
  ) async {
    await _pumpLiveScreen(
      tester,
      auth: _refereeAuth,
      match: _match(),
      isViewer: false,
    );

    expect(_appBarScoringIcon(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('người xem không có quyền chấm không thấy icon bấm điểm', (
    tester,
  ) async {
    await _pumpLiveScreen(
      tester,
      auth: _viewerAuth,
      match: _match(),
      isViewer: true,
    );

    expect(_appBarScoringIcon(), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('trận đã kết thúc không còn icon bấm điểm cho trọng tài', (
    tester,
  ) async {
    await _pumpLiveScreen(
      tester,
      auth: _refereeAuth,
      match: _match(status: 'COMPLETED'),
      isViewer: true,
    );

    expect(_appBarScoringIcon(), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'bảng điểm đè khung hình không gây lỗi layout khi trận đang live',
    (tester) async {
      await _pumpLiveScreen(
        tester,
        auth: _viewerAuth,
        match: _match(scoreboardVisible: true),
        isViewer: true,
      );

      // The scoreboard writes the short name in upper case, like the Web.
      expect(find.text('TEAM ALPHA'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'TC-SETCOL-09 scoreboard shows every played set at once, like the Web',
    (tester) async {
      await _pumpLiveScreen(
        tester,
        auth: _viewerAuth,
        match: _match(
          scoreboardVisible: true,
          scoreDetails: {
            'sets': [
              {'team1Score': 11, 'team2Score': 7, 'isFinished': true},
              {'team1Score': 6, 'team2Score': 11, 'isFinished': true},
              {'team1Score': 4, 'team2Score': 2, 'isFinished': false},
            ],
          },
        ),
        isViewer: true,
      );

      final board = find.byType(LiveScoreboardOverlay);
      for (final label in ['S1', 'S2', 'S3']) {
        expect(
          find.descendant(of: board, matching: find.text(label)),
          findsOneWidget,
          reason: label,
        );
      }
      // Finished sets stay on screen; the blue cell holds the open set.
      expect(find.descendant(of: board, matching: find.text('7')), findsOneWidget);
      expect(find.descendant(of: board, matching: find.text('4')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'TC-LIVEVIEW-11 scoreboard keeps the top-left spot, the header layer sits above it',
    (tester) async {
      await _pumpLiveScreen(
        tester,
        auth: _viewerAuth,
        match: _match(scoreboardVisible: true),
        isViewer: true,
      );

      final board = find.byType(LiveScoreboardOverlay);
      final backButton = tester.getRect(
        find.ancestor(
          of: find.byIcon(Icons.arrow_back_ios_new_rounded),
          matching: find.byType(IconButton),
        ),
      );
      final videoRect = tester.getRect(find.byType(LiveVideoBox));

      expect(board, findsOneWidget);
      // The header is the top layer of the video: the board keeps its old
      // top-left spot and the back button is drawn over it, still visible.
      final videoStack = tester.widget<Stack>(
        find
            .ancestor(
              of: find.byType(LiveVideoBox),
              matching: find.byType(Stack),
            )
            .first,
      );
      int layerOf(Finder target) => videoStack.children.indexWhere(
        (c) => find
            .descendant(of: find.byWidget(c), matching: target)
            .evaluate()
            .isNotEmpty,
      );
      expect(
        layerOf(find.byIcon(Icons.arrow_back_ios_new_rounded)),
        greaterThan(layerOf(find.byType(LiveScoreboardOverlay))),
      );
      expect(videoRect.contains(backButton.topLeft), isTrue);
      expect(tester.getRect(board).overlaps(backButton), isTrue);
      expect(tester.getTopLeft(board).dx, lessThan(videoRect.left + 16));
      expect(tester.getTopLeft(board).dy - videoRect.top, lessThanOrEqualTo(12));
      expect(tester.getTopLeft(board).dy, lessThan(videoRect.center.dy));
      expect(
        tester.getBottomLeft(board).dy,
        lessThan(videoRect.bottom - liveOverlayBottomInset),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('TC-LIVEVIEW-18 viewer sees no overlay while there is no video', (
    tester,
  ) async {
    await _pumpLiveScreen(
      tester,
      auth: _viewerAuth,
      match: _match(scoreboardVisible: true, h2hOverlayVisible: true),
      isViewer: true,
      withVideo: false,
    );

    expect(find.text('No live signal yet'), findsOneWidget);
    expect(find.byType(LiveScoreboardOverlay), findsNothing);
    expect(find.byKey(const ValueKey('live-overlay-h2h')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('TC-FEAT-08: live H2H overlay does not show the match code', (
    tester,
  ) async {
    await _pumpLiveScreen(
      tester,
      auth: _viewerAuth,
      match: _match(round: 0, matchCode: 'DNTB-K1-T3', h2hOverlayVisible: true),
    );

    final h2hOverlay = find.byKey(const ValueKey('live-overlay-h2h'));
    expect(h2hOverlay, findsOneWidget);
    expect(
      find.descendant(
        of: h2hOverlay,
        matching: find.textContaining('DNTB-K1-T3'),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'admin của giải khác không thấy icon bấm điểm dù score-access true',
    (tester) async {
      await _pumpLiveScreen(
        tester,
        auth: _adminAuth,
        match: _match(),
        isViewer: false,
        scoreAccess: true,
      );

      expect(_appBarScoringIcon(), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('người có score-access true thấy icon bấm điểm', (tester) async {
    await _pumpLiveScreen(
      tester,
      auth: _organizerAuth,
      match: _match(),
      isViewer: false,
      scoreAccess: true,
    );

    expect(_appBarScoringIcon(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('người có score-access false không thấy icon bấm điểm', (
    tester,
  ) async {
    await _pumpLiveScreen(
      tester,
      auth: _organizerAuth,
      match: _match(),
      isViewer: false,
      scoreAccess: false,
    );

    expect(_appBarScoringIcon(), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('score-access lỗi (null) không thấy icon bấm điểm', (
    tester,
  ) async {
    await _pumpLiveScreen(
      tester,
      auth: _organizerAuth,
      match: _match(),
      isViewer: false,
    );

    expect(_appBarScoringIcon(), findsNothing);
    expect(tester.takeException(), isNull);
  });

  group('TC-LIVEOVL-12 overlays sit on the picture', () {
    testWidgets('H2H rests 8dp above the bottom of the video', (tester) async {
      await _pumpLiveScreen(
        tester,
        auth: _refereeAuth,
        match: _match(h2hOverlayVisible: true),
        isViewer: true,
        withVideo: false,
      );

      final video = tester.getRect(find.byType(LiveVideoBox));
      final panel = tester.getRect(
        find.byKey(const ValueKey('live-h2h-panel')),
      );
      expect(video.bottom - panel.bottom, closeTo(8, 1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('H2H lifts above the control bar while the bar is showing', (
      tester,
    ) async {
      await _pumpLiveScreen(
        tester,
        auth: _refereeAuth,
        match: _match(h2hOverlayVisible: true),
        isViewer: true,
      );
      // The test player never gets a stream, so its bar stays up: one frame
      // delivers the report, the next ones slide the overlay up.
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      final video = tester.getRect(find.byType(LiveVideoBox));
      final panel = tester.getRect(
        find.byKey(const ValueKey('live-h2h-panel')),
      );
      expect(
        video.bottom - panel.bottom,
        closeTo(liveOverlayBottomInset, 1),
      );
    });

    for (final width in [400.0, 360.0]) {
      testWidgets('whole bracket fits inside its frame on a ${width}dp video', (
        tester,
      ) async {
        await _pumpLiveScreen(
          tester,
          auth: _refereeAuth,
          match: _match(bracketOverlayVisible: true),
          isViewer: true,
          withVideo: false,
          size: Size(width, 844),
        );
        await tester.pump(const Duration(milliseconds: 400));

        final panel = tester.getRect(
          find.byKey(const ValueKey('live-bracket-panel')),
        );
        final video = tester.getRect(find.byType(LiveVideoBox));
        expect(video.width, closeTo(width, 2.5)); // minus the 1dp border
        expect(video.height, closeTo(width * 9 / 16, 2.5));
        expect(panel.width, lessThanOrEqualTo(width * 0.8 + 0.5));
        for (final match in _bracketMatches) {
          final card = find.textContaining(
            'R${match.round}M${match.matchNumber} Alpha',
          );
          expect(card, findsOneWidget, reason: match.id);
          final rect = tester.getRect(card);
          expect(
            panel.inflate(0.5).contains(rect.topLeft) &&
                panel.inflate(0.5).contains(rect.bottomRight),
            isTrue,
            reason: '${match.id} $rect outside $panel',
          );
        }
        expect(tester.takeException(), isNull);
      });
    }
  });

  // The picture a viewer really sees: 16:9, centred, black bands either side
  // when the player box is wider (landscape fullscreen).
  group('TC-LIVEOVL-13 overlays live inside the real picture', () {
    const sizes = {
      'portrait 411x231': Size(411, 844),
      'fullscreen 890x411': Size(890, 411),
      'small 360x203': Size(360, 844),
    };

    Rect picture(WidgetTester tester) =>
        tester.getRect(find.byType(VideoPlayer).first);

    Future<void> pumpWith(
      WidgetTester tester,
      Size size, {
      bool h2h = false,
      bool bracket = false,
    }) => _pumpLiveScreen(
      tester,
      auth: _refereeAuth,
      match: _match(h2hOverlayVisible: h2h, bracketOverlayVisible: bracket),
      isViewer: true,
      size: size,
      playVideo: true,
    );

    bool inside(Rect picture, Rect r) => picture.inflate(0.5).contains(r.topLeft) &&
        picture.inflate(0.5).contains(r.bottomRight);

    for (final entry in sizes.entries) {
      testWidgets('${entry.key}: H2H panel inside the picture, about half its width', (
        tester,
      ) async {
        await pumpWith(tester, entry.value, h2h: true);
        await tester.pump(const Duration(milliseconds: 400));

        final video = picture(tester);
        final panel = tester.getRect(
          find.byKey(const ValueKey('live-h2h-panel')),
        );
        expect(video.width / video.height, closeTo(16 / 9, 0.02));
        expect(inside(video, panel), isTrue, reason: '$panel vs $video');
        expect(panel.width / video.width, inInclusiveRange(0.45, 0.58));
        expect(panel.center.dx, closeTo(video.center.dx, 1));
        expect(tester.takeException(), isNull);
      });

      testWidgets('${entry.key}: bracket frame inside the picture', (
        tester,
      ) async {
        await pumpWith(tester, entry.value, bracket: true);
        await tester.pump(const Duration(milliseconds: 400));

        final video = picture(tester);
        final panel = tester.getRect(
          find.byKey(const ValueKey('live-bracket-panel')),
        );
        expect(inside(video, panel), isTrue, reason: '$panel vs $video');
        expect(panel.width / video.width, inInclusiveRange(0.7, 0.82));
        expect(panel.height / video.height, lessThanOrEqualTo(0.8));
        expect(tester.takeException(), isNull);
      });

      testWidgets('${entry.key}: scoreboard in the top-left of the picture itself', (
        tester,
      ) async {
        await pumpWith(tester, entry.value);

        final video = picture(tester);
        final board = tester.getRect(
          find.byKey(const ValueKey('live-scoreboard-panel')),
        );
        expect(inside(video, board), isTrue, reason: '$board vs $video');
        expect(board.left - video.left, lessThanOrEqualTo(12));
        expect(board.top - video.top, lessThanOrEqualTo(12));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('fullscreen has bands, and the portrait H2H is the smaller one', (
      tester,
    ) async {
      await pumpWith(tester, const Size(411, 844), h2h: true);
      await tester.pump(const Duration(milliseconds: 400));
      final portrait = tester.getRect(
        find.byKey(const ValueKey('live-h2h-panel')),
      );
      final portraitVideo = picture(tester);

      await tester.pumpWidget(const SizedBox());
      await pumpWith(tester, const Size(890, 411), h2h: true);
      await tester.pump(const Duration(milliseconds: 400));
      final full = tester.getRect(find.byKey(const ValueKey('live-h2h-panel')));
      final fullVideo = picture(tester);

      // 16:9 picture centred in the 890 wide box: a black band on each side.
      expect(fullVideo.left, greaterThan(60));
      expect(890 - fullVideo.right, closeTo(fullVideo.left, 1));
      expect(portrait.width, lessThan(full.width));
      expect(
        portrait.width / portraitVideo.width,
        closeTo(full.width / fullVideo.width, 0.04),
      );
    });
  });

  // Landscape fullscreen shows the whole 16:9 picture (never cropped) and pushes
  // the leftover black to the side away from the camera cutout, like YouTube.
  group('TC-LIVEOVL-14 fullscreen picture sits next to the camera cutout', () {
    const screen = Size(890, 411);

    Future<void> pumpCutout(WidgetTester tester, FakeViewPadding padding) async {
      await _pumpLiveScreen(
        tester,
        auth: _refereeAuth,
        match: _match(h2hOverlayVisible: true),
        isViewer: true,
        size: screen,
        playVideo: true,
        padding: padding,
      );
      await tester.pump(const Duration(milliseconds: 400));
    }

    void expectWholePicture(WidgetTester tester) {
      final video = tester.getRect(find.byType(VideoPlayer).first);
      // Never cropped: full height, exact 16:9.
      expect(video.height, closeTo(screen.height, 1));
      expect(video.width / video.height, closeTo(16 / 9, 0.02));
      final panel = tester.getRect(
        find.byKey(const ValueKey('live-h2h-panel')),
      );
      expect(video.inflate(0.5).contains(panel.topLeft), isTrue);
      expect(video.inflate(0.5).contains(panel.bottomRight), isTrue);
      expect(panel.width / video.width, inInclusiveRange(0.45, 0.58));
      expect(tester.takeException(), isNull);
    }

    testWidgets('camera on the left: picture touches the cutout edge', (
      tester,
    ) async {
      await pumpCutout(tester, const FakeViewPadding(left: 44));

      expectWholePicture(tester);
      final video = tester.getRect(find.byType(VideoPlayer).first);
      expect(video.left, closeTo(44, 1));
      // The spare black is all on the far (right) side.
      expect(screen.width - video.right, greaterThan(100));
    });

    testWidgets('camera on the right: picture touches the cutout edge', (
      tester,
    ) async {
      await pumpCutout(tester, const FakeViewPadding(right: 44));

      expectWholePicture(tester);
      final video = tester.getRect(find.byType(VideoPlayer).first);
      expect(video.right, closeTo(screen.width - 44, 1));
      expect(video.left, greaterThan(100));
    });

    testWidgets('no cutout: picture is centred', (tester) async {
      await pumpCutout(tester, FakeViewPadding.zero);

      expectWholePicture(tester);
      final video = tester.getRect(find.byType(VideoPlayer).first);
      expect(video.left, greaterThan(60));
      expect(screen.width - video.right, closeTo(video.left, 1));
    });
  });
}
