import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/socket_providers.dart';
import 'package:app_quanly_giaidau/core/services/match_socket_service.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/features/match/screens/live_score_screen.dart';
import 'package:app_quanly_giaidau/features/match/widgets/live_video_box.dart';
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
}) {
  return MatchModel(
    id: _matchId,
    tournamentId: _tournamentId,
    round: 1,
    matchNumber: 1,
    team1Id: 'team-alpha',
    team2Id: 'team-beta',
    team1Name: 'Team Alpha',
    team2Name: 'Team Beta',
    score1: 3,
    score2: 1,
    status: status,
    bracketPosition: const BracketPosition(round: 1, position: 1),
    updatedAt: DateTime.utc(2026, 10, 15),
    refereeName: 'Trong tai A',
    scoreboardVisible: scoreboardVisible,
  );
}

Future<void> _pumpLiveScreen(
  WidgetTester tester, {
  required AuthState auth,
  required MatchModel match,
  bool isViewer = true,
  bool? scoreAccess,
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
        matchPlaybackProvider.overrideWith((ref, id) => Future.value(null)),
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

Finder _appBarScoringIcon() => find.descendant(
  of: find.byType(AppBar),
  matching: find.byIcon(Icons.scoreboard_rounded),
);

void main() {
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

  testWidgets('bảng điểm đè khung hình không gây lỗi layout khi trận đang live', (
    tester,
  ) async {
    await _pumpLiveScreen(
      tester,
      auth: _viewerAuth,
      match: _match(scoreboardVisible: true),
      isViewer: true,
    );

    expect(find.text('Team Alpha'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('admin của giải khác không thấy icon bấm điểm dù score-access true', (
    tester,
  ) async {
    await _pumpLiveScreen(
      tester,
      auth: _adminAuth,
      match: _match(),
      isViewer: false,
      scoreAccess: true,
    );

    expect(_appBarScoringIcon(), findsNothing);
    expect(tester.takeException(), isNull);
  });

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
