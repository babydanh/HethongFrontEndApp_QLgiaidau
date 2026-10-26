import 'dart:convert';
import 'dart:typed_data';

import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/core/services/token_manager.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_camera_admin_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_manage_sheet.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Task 5.1 (TC-WP-05-01/02/03): camera CRUD routes of a tournament, exactly
/// the ones the web organizer uses.
const _tournamentId = '550e8400-e29b-41d4-a716-446655440010';
const _cameraId = '550e8400-e29b-41d4-a716-446655440000';
const _courtId = '550e8400-e29b-41d4-a716-446655440020';

class _NoTokenManager extends TokenManager {
  @override
  Future<String?> getAccessToken() async => null;
}

class _CannedAdapter implements HttpClientAdapter {
  _CannedAdapter({required this.status, required this.body});

  final int status;
  final Object? body;
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ApiCameraAdminRepository _repository(_CannedAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1'))
    ..httpClientAdapter = adapter;
  return ApiCameraAdminRepository(
    DioClient(tokenManager: _NoTokenManager(), dio: dio),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.loadFromString(
      envString: 'API_BASE_URL=https://api.example.test/api/v1',
    );
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('createCamera posts a PUSH camera and keeps no credential field', () async {
    final adapter = _CannedAdapter(
      status: 201,
      body: <String, Object?>{
        'data': <String, Object?>{
          'id': _cameraId,
          'name': 'Court 1 phone',
          'mode': 'PUSH',
          'status': 'IDLE',
          'courtId': _courtId,
          'playbackUrl': null,
          'publish': <String, Object?>{'url': 'rtmp://fake.invalid/live/fake-key'},
          'ingest': <String, Object?>{'rtmp': 'rtmp://fake.invalid/live/fake-key'},
          'streamKey': 'fake-key',
        },
      },
    );

    final camera = await _repository(adapter).createCamera(
      tournamentId: _tournamentId,
      name: 'Court 1 phone',
      mode: 'PUSH',
      courtId: _courtId,
    );

    final request = adapter.requests.single;
    expect(request.method, 'POST');
    expect(request.path, '/livestream/tournaments/$_tournamentId/cameras');
    expect(request.data, <String, Object?>{
      'name': 'Court 1 phone',
      'mode': 'PUSH',
      'protocol': 'RTMP',
      'courtId': _courtId,
    });
    expect(camera.id, _cameraId);
    expect(camera.mode, 'PUSH');
    expect(camera.courtId, _courtId);
    expect(() => (camera as dynamic).streamKey, throwsA(isA<NoSuchMethodError>()));
    expect(() => (camera as dynamic).publish, throwsA(isA<NoSuchMethodError>()));
    expect(camera.toString(), isNot(contains('fake-key')));
  });

  test('createCamera sends playbackUrl for PULL and omits an empty court', () async {
    final adapter = _CannedAdapter(
      status: 201,
      body: <String, Object?>{
        'data': <String, Object?>{
          'id': _cameraId,
          'name': 'Hall cam',
          'mode': 'PULL',
          'status': 'IDLE',
          'playbackUrl': 'https://media.example.test/live/hall.m3u8',
        },
      },
    );

    final camera = await _repository(adapter).createCamera(
      tournamentId: _tournamentId,
      name: 'Hall cam',
      mode: 'PULL',
      playbackUrl: 'https://media.example.test/live/hall.m3u8',
    );

    expect(adapter.requests.single.data, <String, Object?>{
      'name': 'Hall cam',
      'mode': 'PULL',
      'protocol': 'RTMP',
      'playbackUrl': 'https://media.example.test/live/hall.m3u8',
    });
    expect(camera.playbackUrl, 'https://media.example.test/live/hall.m3u8');
  });

  test('deleteCamera calls DELETE on the camera route', () async {
    final adapter = _CannedAdapter(
      status: 200,
      body: <String, Object?>{'data': <String, Object?>{'id': _cameraId}},
    );

    await _repository(adapter).deleteCamera(_cameraId);

    expect(adapter.requests.single.method, 'DELETE');
    expect(adapter.requests.single.path, '/livestream/cameras/$_cameraId');
  });

  test('assignCameraCourt patches the court and sends null to unassign', () async {
    final adapter = _CannedAdapter(
      status: 200,
      body: <String, Object?>{'data': <String, Object?>{'id': _cameraId}},
    );
    final repository = _repository(adapter);

    await repository.assignCameraCourt(_cameraId, _courtId);
    await repository.assignCameraCourt(_cameraId, null);

    expect(adapter.requests.map((r) => r.method), ['PATCH', 'PATCH']);
    expect(
      adapter.requests.map((r) => r.path),
      everyElement('/livestream/cameras/$_cameraId/court'),
    );
    expect(adapter.requests[0].data, <String, Object?>{'courtId': _courtId});
    expect(adapter.requests[1].data, <String, Object?>{'courtId': null});
  });

  test('backend refusal reaches the caller with its verbatim message', () async {
    final adapter = _CannedAdapter(
      status: 409,
      body: <String, Object?>{'message': 'Camera is live on a match'},
    );
    final repository = _repository(adapter);

    Object? failure;
    try {
      await repository.deleteCamera(_cameraId);
    } on Object catch (error) {
      failure = error;
    }

    expect(failure, isA<DioException>());
    expect(tournamentSheetServerMessage(failure!), 'Camera is live on a match');
  });
}
