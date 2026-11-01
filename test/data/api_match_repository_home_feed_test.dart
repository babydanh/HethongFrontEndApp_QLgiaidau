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

/// Socket stub: the repository only needs the connection calls and streams
/// that never emit.
class _QuietSocketService extends Fake implements MatchSocketService {
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

/// Records the query of every `/matches` request and answers one empty page.
class _RecordingAdapter implements HttpClientAdapter {
  final queries = <Map<String, dynamic>>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    queries.add(Map<String, dynamic>.from(options.queryParameters));
    return ResponseBody.fromString(
      jsonEncode({
        'data': <Object>[],
        'meta': {'hasMore': false, 'nextCursor': null},
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ApiMatchRepository _repositoryWith(_RecordingAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1'))
    ..httpClientAdapter = adapter;
  return ApiMatchRepository(
    DioClient(tokenManager: _NoTokenManager(), dio: dio),
    _QuietSocketService(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  dotenv.loadFromString(
    envString: 'API_BASE_URL=https://api.example.test/api/v1',
  );

  test(
    'TC-HOMEFEED-01 watching one tournament asks only for that tournament',
    () async {
      final adapter = _RecordingAdapter();

      await _repositoryWith(adapter).watchByTournament('tournament-1').first;

      // A global /matches read would page through every public match of every
      // tournament just to show one card on the home feed.
      expect(adapter.queries, isNotEmpty);
      expect(
        adapter.queries.every((query) => query['tournamentId'] == 'tournament-1'),
        isTrue,
        reason: 'queries were ${adapter.queries}',
      );
    },
  );

  test(
    'TC-HOMEFEED-02 watching live matches asks only for that tournament',
    () async {
      final adapter = _RecordingAdapter();

      await _repositoryWith(adapter).watchLive('tournament-1').first;

      expect(adapter.queries, isNotEmpty);
      expect(
        adapter.queries.every((query) => query['tournamentId'] == 'tournament-1'),
        isTrue,
        reason: 'queries were ${adapter.queries}',
      );
    },
  );
}
