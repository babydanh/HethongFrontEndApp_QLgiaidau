import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/core/di/socket_providers.dart';
import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/core/services/match_socket_service.dart';
import 'package:app_quanly_giaidau/data/models/match_playback_model.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_notifier.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_state.dart';
import 'package:app_quanly_giaidau/features/match/screens/live_score_screen.dart';
import 'package:app_quanly_giaidau/features/match/widgets/live_stream_stats_badge.dart';
import 'package:app_quanly_giaidau/features/match/widgets/live_video_box.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/match_control_notifier.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockMatchSocketService extends Mock implements MatchSocketService {}

class _MockDioClient extends Mock implements DioClient {}

class _MockMatchController extends Mock implements MatchController {}

/// ScorePanelNotifier thật tạo timer đồng bộ; test chỉ cần state tĩnh.
class _StaticScorePanelNotifier extends ScorePanelNotifier {
  _StaticScorePanelNotifier(super.arg);

  @override
  ScorePanelState build() => ScorePanelState(config: resolveSportConfig(null));
}

class _UnauthenticatedNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState();
}

const _tournamentId = 'tournament-live-video';
const _matchId = 'match-live-video';
const _noSignalLabel = 'Chưa có tín hiệu phát trực tiếp';

MatchModel _liveMatch() => MatchModel(
  id: _matchId,
  tournamentId: _tournamentId,
  round: 1,
  matchNumber: 1,
  team1Name: 'Đội A',
  team2Name: 'Đội B',
  status: 'live',
  bracketPosition: BracketPosition(round: 1, position: 1),
  updatedAt: DateTime.utc(2026, 1, 1),
);

_MockMatchSocketService _silentSocket() {
  final socket = _MockMatchSocketService();
  when(
    () => socket.connect(any(), joinMatch: any(named: 'joinMatch')),
  ).thenAnswer((_) async {});
  when(
    () => socket.onCommentNew,
  ).thenAnswer((_) => Stream<Map<String, dynamic>>.empty());
  when(
    () => socket.onCheerUpdate,
  ).thenAnswer((_) => Stream<Map<String, dynamic>>.empty());
  return socket;
}

/// Mọi request bị từ chối trước khi ra mạng. Provider thật (playback, comments)
/// đi qua đường lỗi thật của Dio, không cần ném lỗi giả ở provider.
DioClient _offlineDioClient() {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) => handler.reject(
          DioException.connectionError(
            requestOptions: options,
            reason: 'test: không có mạng',
          ),
        ),
      ),
    );
  final client = _MockDioClient();
  when(() => client.dio).thenReturn(dio);
  return client;
}

Future<void> _pumpLiveScore(
  WidgetTester tester, {
  FutureOr<MatchPlaybackModel?> Function(Ref ref, String matchId)? playback,
  UserProfile? profile,
  Tournament? tournament,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        singleMatchProvider.overrideWith(
          (ref, params) => Stream.value(_liveMatch()),
        ),
        matchControllerProvider.overrideWith(
          (ref, arg) => _MockMatchController(),
        ),
        scorePanelNotifierProvider.overrideWith2(_StaticScorePanelNotifier.new),
        dioClientProvider.overrideWithValue(_offlineDioClient()),
        if (playback != null) matchPlaybackProvider.overrideWith(playback),
        if (profile != null)
          userProfileProvider.overrideWith((ref) async => profile),
        liveStreamPingProbeProvider.overrideWithValue((dio, url) async => null),
        viewerCountProvider.overrideWith((ref, matchId) => Stream.value(0)),
        tournamentProvider.overrideWith(
          (ref, id) => Stream<Tournament?>.value(tournament),
        ),
        authProvider.overrideWith(_UnauthenticatedNotifier.new),
        matchSocketServiceProvider.overrideWithValue(_silentSocket()),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('vi'),
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
  // Không dùng pumpAndSettle: _livePulseCtrl lặp vô hạn.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// Khung video là Stack gần nhất chứa LiveVideoBox. Đếm icon chỉ trong Stack
/// này, vì nút "Bắt đầu trận" ở ngoài khung dùng cùng Icons.play_arrow_rounded.
Finder _videoFrame() => find
    .ancestor(of: find.byType(LiveVideoBox), matching: find.byType(Stack))
    .first;

/// Khung video không còn icon play nào: thanh điều khiển giả đã bị xoá.
/// Nút Phát/Tạm dừng thật nằm trong LiveVideoPlayer, chỉ hiện khi có luồng.
void _expectNoPlayIconInVideoFrame() {
  expect(_videoFrame(), findsOneWidget);
  final playIcons = find.descendant(
    of: _videoFrame(),
    matching: find.byIcon(Icons.play_arrow_rounded),
  );
  expect(playIcons, findsNothing);
}

void main() {
  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=https://api.example.test');
  });

  testWidgets('trận chưa có luồng: không icon play giả, còn nhãn no-signal', (
    tester,
  ) async {
    // Giá trị hợp đồng khi backend không có luồng: provider trả null.
    await _pumpLiveScore(tester, playback: (ref, matchId) => null);

    expect(find.byType(LiveVideoBox), findsOneWidget);
    expect(find.text(_noSignalLabel), findsOneWidget);
    _expectNoPlayIconInVideoFrame();
  });

  testWidgets('backend lỗi khi tải playback: vẫn không icon play giả', (
    tester,
  ) async {
    // Không override playback: provider thật bắt lỗi Dio và trả null.
    await _pumpLiveScore(tester);

    expect(find.byType(LiveVideoBox), findsOneWidget);
    expect(find.text(_noSignalLabel), findsOneWidget);
    _expectNoPlayIconInVideoFrame();
  });

  testWidgets('chủ giải thấy huy hiệu Ping/Trễ/FPS trên khung video', (
    tester,
  ) async {
    await _pumpLiveScore(
      tester,
      playback: (ref, matchId) => _flvPlayback(),
      profile: const UserProfile(id: _ownerId, fullName: 'Chủ giải'),
      tournament: _tournament(creatorId: _ownerId),
    );

    expect(find.byKey(const ValueKey('live-stream-stats')), findsOneWidget);
  });

  testWidgets('trọng tài không phải chủ giải không thấy huy hiệu', (
    tester,
  ) async {
    await _pumpLiveScore(
      tester,
      playback: (ref, matchId) => _flvPlayback(),
      profile: const UserProfile(
        id: 'referee-1',
        role: 'REFEREE',
        roles: ['REFEREE'],
      ),
      tournament: _tournament(creatorId: _ownerId),
    );

    expect(find.byType(LiveVideoBox), findsOneWidget);
    expect(find.byKey(const ValueKey('live-stream-stats')), findsNothing);
  });

  testWidgets('admin thấy huy hiệu dù không phải chủ giải', (tester) async {
    await _pumpLiveScore(
      tester,
      playback: (ref, matchId) => _flvPlayback(),
      profile: const UserProfile(
        id: 'admin-1',
        role: 'ADMIN',
        roles: ['ADMIN'],
      ),
      tournament: _tournament(creatorId: _ownerId),
    );

    expect(find.byKey(const ValueKey('live-stream-stats')), findsOneWidget);
  });
}

const _ownerId = 'owner-live-video';

MatchPlaybackModel _flvPlayback() =>
    MatchPlaybackModel.fromJson(<String, Object?>{
      'matchId': _matchId,
      'streamStatus': 'LIVE',
      'playbackUrl': 'https://media.example.test/live/stream.flv',
      'cameraName': 'Sân 1',
    });

Tournament _tournament({required String creatorId}) =>
    Tournament.fromJson(<String, dynamic>{
      'name': 'Giải thử live',
      'sport': 'pickleball',
      'format': 'doubles',
      'creatorId': creatorId,
    }, _tournamentId);
