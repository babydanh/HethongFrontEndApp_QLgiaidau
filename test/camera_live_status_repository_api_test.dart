import 'dart:convert';
import 'dart:typed_data';

import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/core/services/token_manager.dart';
import 'package:app_quanly_giaidau/data/models/camera_live_status_model.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_court_camera_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _cameraId = '550e8400-e29b-41d4-a716-446655440000';

class _NoTokenManager extends TokenManager {
  @override
  Future<String?> getAccessToken() async => null;
}

class _ResponseAdapter implements HttpClientAdapter {
  _ResponseAdapter({
    required this.data,
    required this.expectedPath,
    required this.requests,
  });

  final Object? data;
  final String expectedPath;
  final List<RequestOptions> requests;
  bool failAfterFirst = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final statusCode = options.path != expectedPath
        ? 404
        : failAfterFirst && requests.length > 1
        ? 503
        : 200;
    final body = statusCode == 200
        ? <String, Object?>{'data': data}
        : <String, Object?>{'message': 'temporary failure'};
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
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

  test('returns safe live status from the backend status route', () async {
    final requests = <RequestOptions>[];
    final adapter = _ResponseAdapter(
      expectedPath: '/livestream/cameras/$_cameraId/status',
      data: <String, Object?>{
        'cameraId': _cameraId,
        'streamName': 'provider-secret-stream',
        'online': true,
        'status': 'LIVE',
        'publishKey': 'secret-key',
      },
      requests: requests,
    );
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1'))
      ..httpClientAdapter = adapter;
    final repository = ApiCourtCameraRepository(
      DioClient(tokenManager: _NoTokenManager(), dio: dio),
    );

    final result = await repository.getCameraLiveStatus(_cameraId);

    expect(result.cameraId, _cameraId);
    expect(result.online, isTrue);
    expect(result.status, CameraLiveStatus.live);
    expect(
      () => (result as dynamic).streamName,
      throwsA(isA<NoSuchMethodError>()),
    );
  });

  test('status failures do not fall back to a cached snapshot', () async {
    final requests = <RequestOptions>[];
    final path = '/livestream/cameras/$_cameraId/status';
    final adapter = _ResponseAdapter(
      expectedPath: path,
      data: <String, Object?>{
        'cameraId': _cameraId,
        'online': true,
        'status': 'LIVE',
      },
      requests: requests,
    );
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1'))
      ..httpClientAdapter = adapter;
    final client = DioClient(tokenManager: _NoTokenManager(), dio: dio);
    await client.dio.get(path);
    adapter.failAfterFirst = true;
    final repository = ApiCourtCameraRepository(client);

    await expectLater(
      repository.getCameraLiveStatus(_cameraId),
      throwsA(isA<DioException>()),
    );
  });
}
