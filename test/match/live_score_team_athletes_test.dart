import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/socket_providers.dart';
import 'package:app_quanly_giaidau/core/services/match_socket_service.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/features/match/screens/live_score_screen.dart';
import 'package:app_quanly_giaidau/features/match/widgets/live_video_box.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _tournamentId = 'tournament-team-athletes';
const _matchId = 'match-team-athletes';

class _FixedAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState(
    status: AuthStatus.authenticated,
    role: UserRole.viewer,
    tournamentId: _tournamentId,
  );
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
  required String team1Name,
  List<MatchMemberInfo> team1MemberInfos = const [],
}) {
  return MatchModel(
    id: _matchId,
    tournamentId: _tournamentId,
    round: 1,
    matchNumber: 1,
    team1Id: 'team-1',
    team2Id: 'team-2',
    team1Name: team1Name,
    team2Name: 'Biên Hòa Pickleball',
    team1Members: team1MemberInfos.map((m) => m.fullName).toList(),
    team1MemberInfos: team1MemberInfos,
    status: 'SCHEDULED',
    bracketPosition: const BracketPosition(round: 1, position: 1),
    updatedAt: DateTime.utc(2026, 10, 19),
  );
}

Future<void> _pump(WidgetTester tester, MatchModel match) async {
  tester.view.physicalSize = const Size(390, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith(_FixedAuthNotifier.new),
        singleMatchProvider.overrideWith((ref, params) => Stream.value(match)),
        tournamentProvider.overrideWith((ref, id) => Stream.value(null)),
        viewerCountProvider.overrideWith((ref, id) => Stream.value(0)),
        matchPlaybackProvider.overrideWith((ref, id) => Future.value(null)),
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
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  // Người xem mở vào tab Thảo luận; khối hai đội nằm ở tab Tỉ số.
  await tester.tap(find.text('Score & Timeline'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// Chữ trong vòng tròn VĐV (CircleAvatar) của Chi tiết trận.
Finder _circleText(String text) => find.descendant(
  of: find.byType(CircleAvatar),
  matching: find.text(text),
);

void main() {
  testWidgets('a guest pair shows one circle per athlete and doubles ELO', (
    tester,
  ) async {
    await _pump(
      tester,
      _match(
        team1Name: 'CLB Pickleball Sài Gòn',
        team1MemberInfos: MatchMemberInfo.guestsOf({
          'guestNames': ['Nguyễn Minh Anh', 'Trần Quốc Bảo'],
        }),
      ),
    );

    expect(_circleText('N'), findsOneWidget);
    expect(_circleText('T'), findsOneWidget);
    expect(_circleText('C'), findsNothing);
    expect(find.textContaining('Doubles ELO'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a team named "A / B" without members fabricates no athletes', (
    tester,
  ) async {
    await _pump(tester, _match(team1Name: 'Phan Anh Khoa / Hồ Minh Trí'));

    // Chuẩn hiển thị không dựng VĐV giả từ tên đội: không có roster thì
    // không có vòng tròn VĐV nào.
    expect(_circleText('P'), findsNothing);
    expect(_circleText('H'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
