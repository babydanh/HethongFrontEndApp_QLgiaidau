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
}) {
  return MatchModel(
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
  );
}

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
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
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

    testWidgets('H2H panel is translucent and comes back from the menu after X', (
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
      final opacity = tester.widget<Opacity>(
        find.descendant(of: h2h, matching: find.byType(Opacity)).first,
      );
      expect(opacity.opacity, lessThan(1));

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
}
