import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/socket_providers.dart';
import 'package:app_quanly_giaidau/core/services/match_socket_service.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/features/match/screens/live_score_screen.dart';
import 'package:app_quanly_giaidau/features/match/widgets/live_video_box.dart';
import 'package:app_quanly_giaidau/features/match/widgets/viewer/live_landscape_chat.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _tournamentId = 'tournament-fullscreen';
const _matchId = 'match-fullscreen';

class _ViewerAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState(
    status: AuthStatus.authenticated,
    role: UserRole.viewer,
    tournamentId: _tournamentId,
  );
}

class _SilentMatchSocket extends Fake implements MatchSocketService {
  final comments = StreamController<Map<String, dynamic>>.broadcast();

  @override
  Future<void> connect(String? matchId, {bool joinMatch = true}) async {}

  @override
  void leave(String matchId) {}

  @override
  Stream<Map<String, dynamic>> get onCommentNew => comments.stream;

  @override
  Stream<Map<String, dynamic>> get onCheerUpdate => const Stream.empty();
}

MatchModel _match() => MatchModel(
  id: _matchId,
  tournamentId: _tournamentId,
  round: 1,
  matchNumber: 1,
  team1Id: 'team-1',
  team2Id: 'team-2',
  team1Name: 'Alpha',
  team2Name: 'Beta',
  status: 'SCHEDULED',
  bracketPosition: const BracketPosition(round: 1, position: 1),
  updatedAt: DateTime.utc(2026, 11, 1),
);

Future<void> _pump(
  WidgetTester tester,
  Size size, {
  _SilentMatchSocket? socket,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith(_ViewerAuthNotifier.new),
        singleMatchProvider.overrideWith(
          (ref, params) => Stream.value(_match()),
        ),
        tournamentProvider.overrideWith((ref, id) => Stream.value(null)),
        viewerCountProvider.overrideWith((ref, id) => Stream.value(0)),
        matchPlaybackProvider.overrideWith((ref, id) => Future.value(null)),
        matchSocketServiceProvider.overrideWithValue(
          socket ?? _SilentMatchSocket(),
        ),
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
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('TC-LIVEFS-10 landscape: no AppBar, chat floats over the video', (
    tester,
  ) async {
    await _pump(tester, const Size(800, 360));

    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(LiveLandscapeChat), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('TC-LIVEFS-11 landscape chat can be hidden and shown again', (
    tester,
  ) async {
    await _pump(tester, const Size(800, 360));

    await tester.tap(find.byTooltip('Hide chat'));
    await tester.pump();
    expect(find.byType(LiveLandscapeChat), findsNothing);

    await tester.tap(find.byTooltip('Show chat'));
    await tester.pump();
    expect(find.byType(LiveLandscapeChat), findsOneWidget);
  });

  testWidgets('TC-LIVEFS-12 portrait: no Report chip under the video, no AppBar', (
    tester,
  ) async {
    await _pump(tester, const Size(390, 844));

    expect(find.byType(AppBar), findsNothing);
    // Report now lives in the details sheet, not as a chip under the video.
    expect(find.text('Report'), findsNothing);
    expect(find.byType(LiveLandscapeChat), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('TC-LIVEFS-13 scrolled-up chat holds new rows behind a pill', (
    tester,
  ) async {
    final socket = _SilentMatchSocket();
    addTearDown(socket.comments.close);
    await _pump(tester, const Size(390, 844), socket: socket);

    void say(int i) => socket.comments.add({
      'id': 'c$i',
      'matchId': _matchId,
      'user': {'id': 'u$i', 'fullName': 'User $i'},
      'commentText': 'message $i',
      'createdAt': DateTime.utc(2026, 11, 1, 10, i).toIso8601String(),
    });

    for (var i = 0; i < 15; i++) {
      say(i);
    }
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('new messages'), findsNothing);

    // Scroll up to read older rows, then a newer comment arrives.
    await tester.drag(find.byType(ListView).first, const Offset(0, 300));
    await tester.pump(const Duration(milliseconds: 100));
    say(20);
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('1 new messages'), findsOneWidget);
    expect(find.text('message 20'), findsNothing);

    await tester.tap(find.text('1 new messages'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining('new messages'), findsNothing);
    expect(find.text('message 20'), findsOneWidget);
  });
}
