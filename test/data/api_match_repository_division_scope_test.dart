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

class _SilentSocketService extends Fake implements MatchSocketService {}

/// Ghi lại query của mọi request `/matches`, trả một trang rỗng.
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
    _SilentSocketService(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  dotenv.loadFromString(
    envString: 'API_BASE_URL=https://api.example.test/api/v1',
  );

  test(
    'a division query never falls back to the whole tournament feed',
    () async {
      final adapter = _RecordingAdapter();

      await _repositoryWith(
        adapter,
      ).getAllByTournament('tournament-1', divisionId: 'division-draft');

      // Without strictDivisionScope the backend answers a division that has no
      // stage yet with every match of the tournament: a phantom bracket.
      expect(adapter.queries.single['divisionId'], 'division-draft');
      expect(adapter.queries.single['strictDivisionScope'], true);
    },
  );
}
