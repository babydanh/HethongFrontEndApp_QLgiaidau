import 'dart:convert';
import 'dart:typed_data';

import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/core/services/token_manager.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_match_recording_catalog_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _matchId = '550e8400-e29b-41d4-a716-446655440001';

class _NoTokenManager extends TokenManager {
  @override
  Future<String?> getAccessToken() async => null;
}

class _CatalogAdapter implements HttpClientAdapter {
  bool failRequests = false;

  ResponseBody _response(Object? data, int statusCode) =>
      ResponseBody.fromString(
        jsonEncode(data),
        statusCode,
        headers: <String, List<String>>{
          Headers.contentTypeHeader: <String>[Headers.jsonContentType],
        },
      );

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (failRequests) {
      return _response(<String, Object?>{'message': 'temporary failure'}, 503);
    }

    final Object? data;
    if (options.path == '/livestream/matches/$_matchId/control-state') {
      data = <String, Object?>{
        'matchId': _matchId,
        'hasCamera': true,
        'streamStatus': 'LIVE',
        'streamName': 'provider-secret-stream',
      };
    } else if (options.path == '/livestream/matches/$_matchId/recording-days') {
      data = <Object?>['2026-10-09', '2026-10-08'];
    } else if (options.path == '/livestream/matches/$_matchId/recordings' &&
        options.queryParameters['period'] == '2026-10-09') {
      data = <Object?>[
        <String, Object?>{
          'name': 'court-final.mp4',
          'sizeBytes': 0,
          'recordingUrl': 'https://media.example.test/private.mp4',
          'rootPath': '/private/root',
        },
        <String, Object?>{'name': '../secret.mp4', 'sizeBytes': 25},
      ];
    } else if (options.path == '/livestream/matches/$_matchId/recordings') {
      data = <Object?>[
        <String, Object?>{'name': 'wrong-period.mp4'},
      ];
    } else {
      return _response('', 404);
    }
    return _response(<String, Object?>{'data': data}, 200);
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

  test('reads safe metadata from the selected recording day', () async {
    final adapter = _CatalogAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1'))
      ..httpClientAdapter = adapter;
    final repository = ApiMatchRecordingCatalogRepository(
      DioClient(tokenManager: _NoTokenManager(), dio: dio),
    );

    final control = await repository.getMatchControlState(_matchId);
    final days = await repository.listRecordingDays(_matchId);
    final files = await repository.listRecordings(
      _matchId,
      period: '2026-10-09',
    );

    expect(control.hasCamera, isTrue);
    expect(days.days, <String>['2026-10-09', '2026-10-08']);
    expect(files.map((file) => file.name), <String>['court-final.mp4']);
    expect(files.single.sizeBytes, 0);
    expect(
      () => (files.single as dynamic).recordingUrl,
      throwsA(isA<NoSuchMethodError>()),
    );
  });

  test('failed fresh catalog reads never return a cached snapshot', () async {
    final adapter = _CatalogAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1'))
      ..httpClientAdapter = adapter;
    final client = DioClient(tokenManager: _NoTokenManager(), dio: dio);
    final repository = ApiMatchRecordingCatalogRepository(client);

    await client.dio.get('/livestream/matches/$_matchId/control-state');
    adapter.failRequests = true;
    await expectLater(
      repository.getMatchControlState(_matchId),
      throwsA(isA<DioException>()),
    );

    adapter.failRequests = false;
    await client.dio.get('/livestream/matches/$_matchId/recording-days');
    adapter.failRequests = true;
    await expectLater(
      repository.listRecordingDays(_matchId),
      throwsA(isA<DioException>()),
    );

    adapter.failRequests = false;
    await client.dio.get(
      '/livestream/matches/$_matchId/recordings',
      queryParameters: const <String, Object?>{'period': '2026-10-09'},
    );
    adapter.failRequests = true;
    await expectLater(
      repository.listRecordings(_matchId, period: '2026-10-09'),
      throwsA(isA<DioException>()),
    );
  });
}
