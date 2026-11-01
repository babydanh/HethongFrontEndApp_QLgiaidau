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

/// Socket giả cho phép test tự phát sự kiện.
class _ControllableSocket extends Fake implements MatchSocketService {
  final score = StreamController<Map<String, dynamic>>.broadcast();
  final status = StreamController<Map<String, dynamic>>.broadcast();
  final tournament = StreamController<Map<String, dynamic>>.broadcast();

  @override
  Future<void> connect(String? matchId, {bool joinMatch = true}) async {}

  @override
  void joinTournament(String tournamentId) {}

  @override
  void leaveTournament(String tournamentId) {}

  @override
  Stream<Map<String, dynamic>> get onTournamentMatchUpdate => tournament.stream;

  @override
  Stream<Map<String, dynamic>> get onScoreUpdate => score.stream;

  @override
  Stream<Map<String, dynamic>> get onMatchStatus => status.stream;
}

/// Trả một trận; có thể giữ response lại cho tới khi [hold] hoàn tất.
class _Adapter implements HttpClientAdapter {
  int requestCount = 0;
  Completer<void>? hold;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestCount++;
    final gate = hold;
    if (gate != null) await gate.future;
    return ResponseBody.fromString(
      jsonEncode({
        'data': [
          {'id': 'match-1', 'tournamentId': 'tour-1', 'status': 'SCHEDULED'},
        ],
        'meta': {'total': 1, 'hasMore': false},
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

({ApiMatchRepository repository, _Adapter adapter, _ControllableSocket socket})
_build() {
  final adapter = _Adapter();
  final socket = _ControllableSocket();
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1'))
    ..httpClientAdapter = adapter;
  final repository = ApiMatchRepository(
    DioClient(tokenManager: _NoTokenManager(), dio: dio),
    socket,
  );
  return (repository: repository, adapter: adapter, socket: socket);
}

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 50));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  dotenv.loadFromString(
    envString: 'API_BASE_URL=https://api.example.test/api/v1',
  );

  test(
    'TC-OPEN-SPEED-04 reopening a tournament emits stored matches at once',
    () async {
      final env = _build();
      final first = await env.repository.watchByTournament('tour-1').first;
      expect(first.map((m) => m.id), ['match-1']);

      env.adapter.hold = Completer<void>();
      final reopened = await env.repository
          .watchByTournament('tour-1')
          .first
          .timeout(const Duration(seconds: 1));

      expect(reopened.map((m) => m.id), ['match-1']);
      env.adapter.hold!.complete();
    },
  );

  test(
    'TC-OPEN-SPEED-05 score events of another tournament do not reload',
    () async {
      final env = _build();
      final subscription = env.repository
          .watchByTournament('tour-1')
          .listen((_) {});
      await _settle();
      final baseline = env.adapter.requestCount;

      env.socket.score.add({'tournamentId': 'other-tour', 'matchId': 'x'});
      env.socket.status.add({'tournamentId': 'other-tour', 'matchId': 'x'});
      await _settle();
      expect(env.adapter.requestCount, baseline);

      await subscription.cancel();
    },
  );

  test(
    'TC-OPEN-SPEED-06 score events of this or unknown tournament reload',
    () async {
      final env = _build();
      final subscription = env.repository
          .watchByTournament('tour-1')
          .listen((_) {});
      await _settle();
      final baseline = env.adapter.requestCount;

      env.socket.score.add({'tournamentId': 'tour-1', 'matchId': 'x'});
      await _settle();
      expect(env.adapter.requestCount, baseline + 1);

      env.socket.status.add({'matchId': 'x'});
      await _settle();
      expect(env.adapter.requestCount, baseline + 2);

      await subscription.cancel();
    },
  );
}
