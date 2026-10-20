import 'dart:convert';
import 'dart:typed_data';

import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/core/services/token_manager.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_match_playback_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _matchId = 'match-replay-api-test';

class _NoTokenManager extends TokenManager {
  @override
  Future<String?> getAccessToken() async => null;
}

class _ReplayAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(<String, Object?>{
        'statusCode': 200,
        'message': 'OK',
        'data': <String, Object?>{
          'matchId': _matchId,
          'available': true,
          'reason': null,
          'startedAt': null,
          'endedAt': null,
          'durationSec': 12,
          'segments': <Object?>[
            <String, Object?>{
              'name': 'clip.mp4',
              'url': 'https://media.example.test/clip.mp4',
              'startAt': '2026-10-20T14:49:08+07:00',
              'offsetSec': 0,
              'clipStartSec': 0,
              'durationSec': 12,
            },
          ],
        },
      }),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.loadFromString(
      envString: 'API_BASE_URL=https://api.example.test/api/v1',
    );
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'getMatchReplay requests endpoint and parses the data envelope',
    () async {
      final adapter = _ReplayAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1'))
        ..httpClientAdapter = adapter;
      final repository = ApiMatchPlaybackRepository(
        DioClient(tokenManager: _NoTokenManager(), dio: dio),
      );

      final replay = await repository.getMatchReplay(_matchId);

      expect(
        adapter.requests.single.path,
        '/livestream/matches/$_matchId/replay',
      );
      expect(replay.available, isTrue);
      expect(replay.segments.single.url, 'https://media.example.test/clip.mp4');
    },
  );
}
