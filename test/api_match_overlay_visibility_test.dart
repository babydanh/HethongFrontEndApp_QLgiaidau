import 'dart:async';

import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/core/services/match_socket_service.dart';
import 'package:app_quanly_giaidau/core/services/token_manager.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_match_repository.dart';
import 'package:app_quanly_giaidau/domain/entities/live_overlay_kind.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoTokenManager extends TokenManager {
  @override
  Future<String?> getAccessToken() async => null;
}

class _FakeMatchSocketService implements MatchSocketService {
  final overlayEvents = StreamController<Map<String, dynamic>>.broadcast();

  @override
  Stream<Map<String, dynamic>> get onOverlayVisibility => overlayEvents.stream;

  @override
  Stream<Map<String, dynamic>> get onScoreUpdate => const Stream.empty();

  @override
  Stream<Map<String, dynamic>> get onMatchStatus => const Stream.empty();

  @override
  Stream<Map<String, dynamic>> get onTournamentMatchUpdate =>
      const Stream.empty();

  @override
  Stream<Map<String, dynamic>> get onScoreboardVisibility =>
      const Stream.empty();

  @override
  Future<void> connect(String? matchId, {bool joinMatch = true}) async {}

  @override
  void leave(String matchId) {}

  @override
  void leaveTournament(String tournamentId) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

({ApiMatchRepository repository, List<RequestOptions> requests})
_repositoryWith(
  MatchSocketService socket,
  Response<dynamic> Function(RequestOptions options) respond,
) {
  final requests = <RequestOptions>[];
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        requests.add(options);
        handler.resolve(respond(options));
      },
    ),
  );
  final repository = ApiMatchRepository(
    DioClient(tokenManager: _NoTokenManager(), dio: dio),
    socket,
  );
  return (repository: repository, requests: requests);
}

Map<String, dynamic> _matchJson({required bool h2h, required bool bracket}) {
  return {
    'id': 'match-1',
    'tournamentId': 'tournament-1',
    'round': 1,
    'status': 'LIVE',
    'team1Name': 'Doi A',
    'team2Name': 'Doi B',
    'updatedAt': '2026-07-15T08:00:00Z',
    'h2hOverlayVisible': h2h,
    'bracketOverlayVisible': bracket,
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  dotenv.loadFromString(
    envString: 'API_BASE_URL=https://api.example.test/api/v1',
  );

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('setOverlayVisibility', () {
    test(
      'tournament match PATCHes the kind and returns server flags after exclusion',
      () async {
        final ctx = _repositoryWith(
          _FakeMatchSocketService(),
          (options) => Response<dynamic>(
            requestOptions: options,
            statusCode: 200,
            data: {
              'statusCode': 200,
              'message': 'ok',
              'data': {
                'id': 'match-1',
                'matchId': 'match-1',
                'h2hOverlayVisible': false,
                'bracketOverlayVisible': true,
              },
              'meta': {},
            },
          ),
        );

        final result = await ctx.repository.setOverlayVisibility(
          'match-1',
          kind: LiveOverlayKind.bracket,
          visible: true,
          isClubMatch: false,
        );

        expect(ctx.requests, hasLength(1));
        expect(ctx.requests.single.method, 'PATCH');
        expect(ctx.requests.single.path, '/matches/match-1/overlay-visibility');
        expect(ctx.requests.single.data, {'kind': 'BRACKET', 'visible': true});
        expect(result, (h2hOverlayVisible: false, bracketOverlayVisible: true));
      },
    );

    test('club match uses the club-match-sessions route', () async {
      final ctx = _repositoryWith(
        _FakeMatchSocketService(),
        (options) => Response<dynamic>(
          requestOptions: options,
          statusCode: 200,
          data: {
            'data': {
              'id': 'match-1',
              'matchId': 'match-1',
              'h2hOverlayVisible': true,
              'bracketOverlayVisible': false,
            },
          },
        ),
      );

      final result = await ctx.repository.setOverlayVisibility(
        'match-1',
        kind: LiveOverlayKind.h2h,
        visible: false,
        isClubMatch: true,
      );

      expect(
        ctx.requests.single.path,
        '/club-match-sessions/matches/match-1/overlay-visibility',
      );
      expect(ctx.requests.single.data, {'kind': 'H2H', 'visible': false});
      expect(result, (h2hOverlayVisible: true, bracketOverlayVisible: false));
    });

    test('a response without data is an error, not a silent hidden state', () async {
      final ctx = _repositoryWith(
        _FakeMatchSocketService(),
        (options) => Response<dynamic>(
          requestOptions: options,
          statusCode: 200,
          data: {'statusCode': 200},
        ),
      );

      await expectLater(
        ctx.repository.setOverlayVisibility(
          'match-1',
          kind: LiveOverlayKind.h2h,
          visible: true,
          isClubMatch: false,
        ),
        throwsFormatException,
      );
    });
  });

  test(
    'overlay:visibility socket event updates live flags without refetching',
    () async {
      final socket = _FakeMatchSocketService();
      final ctx = _repositoryWith(
        socket,
        (options) => Response<dynamic>(
          requestOptions: options,
          statusCode: 200,
          data: {
            'data': _matchJson(h2h: false, bracket: false),
            'meta': {},
          },
        ),
      );

      final snapshot = Completer<MatchModel>();
      final emitted = <MatchModel>[];
      final subscription = ctx.repository
          .watchMatch('tournament-1', 'match-1')
          .listen((match) {
            if (match == null) return;
            emitted.add(match);
            if (!snapshot.isCompleted) snapshot.complete(match);
          });
      addTearDown(subscription.cancel);

      await snapshot.future;
      expect(emitted.single.h2hOverlayVisible, isFalse);
      expect(emitted.single.bracketOverlayVisible, isFalse);

      socket.overlayEvents.add({
        'id': 'match-1',
        'matchId': 'match-1',
        'h2hOverlayVisible': true,
        'bracketOverlayVisible': false,
      });
      await Future<void>.delayed(Duration.zero);
      expect(emitted.last.h2hOverlayVisible, isTrue);
      expect(emitted.last.bracketOverlayVisible, isFalse);

      socket.overlayEvents.add({
        'id': 'match-1',
        'matchId': 'match-1',
        'h2hOverlayVisible': false,
        'bracketOverlayVisible': true,
      });
      await Future<void>.delayed(Duration.zero);
      expect(emitted.last.h2hOverlayVisible, isFalse);
      expect(emitted.last.bracketOverlayVisible, isTrue);

      expect(ctx.requests, hasLength(1));
    },
  );
}
