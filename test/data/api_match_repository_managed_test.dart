import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/core/services/match_socket_service.dart';
import 'package:app_quanly_giaidau/core/services/token_manager.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_match_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoTokenManager extends TokenManager {
  @override
  Future<String?> getAccessToken() async => null;
}

/// Socket không phát sự kiện nào; test chỉ kiểm tra request HTTP.
class _SilentSocketService extends Fake implements MatchSocketService {
  @override
  Future<void> connect(String? matchId, {bool joinMatch = true}) async {}

  @override
  void joinTournament(String tournamentId) {}

  @override
  void leaveTournament(String tournamentId) {}

  @override
  Stream<Map<String, dynamic>> get onTournamentMatchUpdate =>
      const Stream.empty();

  @override
  Stream<Map<String, dynamic>> get onScoreUpdate => const Stream.empty();

  @override
  Stream<Map<String, dynamic>> get onMatchStatus => const Stream.empty();
}

typedef _Reply = (int, Object) Function(RequestOptions options);

/// Ghi lại mọi request và trả về status/body theo [reply].
class _RoutingAdapter implements HttpClientAdapter {
  _RoutingAdapter(this.reply);

  final _Reply reply;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final (status, body) = reply(options);
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ApiMatchRepository _repositoryWith(_RoutingAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1'))
    ..httpClientAdapter = adapter;
  return ApiMatchRepository(
    DioClient(tokenManager: _NoTokenManager(), dio: dio),
    _SilentSocketService(),
  );
}

Map<String, dynamic> _matchJson(String id) => {
  'id': id,
  'tournamentId': 'tournament-1',
  'status': 'SCHEDULED',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  dotenv.loadFromString(
    envString: 'API_BASE_URL=https://api.example.test/api/v1',
  );

  group('ApiMatchRepository.watchManagedByTournament', () {
    test(
      'calls manage route with divisionId and activeStageOnly, never publicOnly',
      () async {
        final adapter = _RoutingAdapter(
          (_) => (
            200,
            {
              'data': [_matchJson('match-1')],
              'meta': {'total': 1, 'hasMore': false},
            },
          ),
        );
        final repository = _repositoryWith(adapter);

        final matches = await repository
            .watchManagedByTournament('tournament-1', divisionId: 'division-1')
            .first;

        expect(matches.map((match) => match.id), ['match-1']);
        final request = adapter.requests.single;
        expect(request.path, '/tournaments/tournament-1/manage/matches');
        expect(request.queryParameters['divisionId'], 'division-1');
        expect(request.queryParameters['activeStageOnly'], true);
        expect(request.queryParameters.containsKey('publicOnly'), isFalse);
      },
    );

    test('follows nextCursor until every page is loaded', () async {
      final adapter = _RoutingAdapter((options) {
        if (options.queryParameters['cursor'] == null) {
          return (
            200,
            {
              'data': [_matchJson('match-1')],
              'meta': {'total': 2, 'hasMore': true, 'nextCursor': 'cursor-2'},
            },
          );
        }
        return (
          200,
          {
            'data': [_matchJson('match-2')],
            'meta': {'total': 2, 'hasMore': false},
          },
        );
      });
      final repository = _repositoryWith(adapter);

      final matches = await repository
          .watchManagedByTournament('tournament-1')
          .first;

      expect(matches.map((match) => match.id), ['match-1', 'match-2']);
      expect(adapter.requests, hasLength(2));
      expect(adapter.requests.last.queryParameters['cursor'], 'cursor-2');
    });

    test('emits an error on 403 when no cached matches exist', () async {
      final adapter = _RoutingAdapter(
        (_) => (403, {'message': 'Forbidden'}),
      );
      final repository = _repositoryWith(adapter);

      final error = Completer<Object>();
      final emitted = <List<Object>>[];
      final subscription = repository
          .watchManagedByTournament('tournament-1')
          .listen(
            (matches) => emitted.add(matches),
            onError: (Object e, StackTrace _) {
              if (!error.isCompleted) error.complete(e);
            },
          );
      final thrown = await error.future.timeout(const Duration(seconds: 5));
      await subscription.cancel();

      expect(thrown, isA<DioException>());
      expect(emitted, isEmpty);
    });
  });
}
