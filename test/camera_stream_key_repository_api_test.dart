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

/// Task 5.2 (TC-WP-05-04/05/06): the four AQP stream-key routes the web
/// organizer uses. Every credential below is an obviously fake fixture.
const _cameraId = '550e8400-e29b-41d4-a716-446655440000';
const _route = '/livestream/cameras/$_cameraId/aqp-stream-key';
const _fakeQr = 'fake-qr-payload';
const _fakeKey = 'fake-key';
const _fakeServer = 'rtmp://fake.invalid/live';

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

Map<String, Object?> _keyBody({bool withKey = true}) => <String, Object?>{
  'data': <String, Object?>{
    'camera': <String, Object?>{
      'id': _cameraId,
      'name': 'Court 1 phone',
      'streamName': 'court-1',
    },
    'streamKeyId': withKey ? 'key-1' : null,
    'status': withKey ? 'READY' : null,
    'qrPayload': withKey ? <String, Object?>{'v': 1} : null,
    'qrPayloadString': withKey ? _fakeQr : null,
    'rtmp': withKey
        ? <String, Object?>{'server': _fakeServer, 'streamKey': _fakeKey}
        : null,
  },
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.loadFromString(
      envString: 'API_BASE_URL=https://api.example.test/api/v1',
    );
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'getStreamKey reads the state with GET and bypasses the GET cache',
    () async {
      final adapter = _CannedAdapter(status: 200, body: _keyBody());
      final repository = _repository(adapter);

      final state = await repository.getStreamKey(_cameraId);
      await repository.getStreamKey(_cameraId);

      expect(adapter.requests, hasLength(2));
      final request = adapter.requests.first;
      expect(request.method, 'GET');
      expect(request.path, _route);
      expect(request.extra['noCache'], true);
      expect(state.cameraId, _cameraId);
      expect(state.streamName, 'court-1');
      expect(state.streamKeyId, 'key-1');
      expect(state.qrPayloadString, _fakeQr);
      expect(state.rtmpServer, _fakeServer);
      expect(state.rtmpStreamKey, _fakeKey);
    },
  );

  test(
    'getStreamKey maps a camera without a key to null credentials',
    () async {
      final adapter = _CannedAdapter(
        status: 200,
        body: _keyBody(withKey: false),
      );

      final state = await _repository(adapter).getStreamKey(_cameraId);

      expect(state.streamKeyId, isNull);
      expect(state.qrPayloadString, isNull);
      expect(state.rtmpServer, isNull);
      expect(state.rtmpStreamKey, isNull);
      expect(state.hasKey, isFalse);
    },
  );

  test('createStreamKey posts an empty object to the key route', () async {
    final adapter = _CannedAdapter(status: 201, body: _keyBody());

    final state = await _repository(adapter).createStreamKey(_cameraId);

    final request = adapter.requests.single;
    expect(request.method, 'POST');
    expect(request.path, _route);
    expect(request.data, <String, Object?>{});
    expect(state.hasKey, isTrue);
  });

  test('renameStreamKey patches the stream name', () async {
    final adapter = _CannedAdapter(status: 200, body: _keyBody(withKey: false));

    await _repository(adapter).renameStreamKey(_cameraId, 'court-2');

    final request = adapter.requests.single;
    expect(request.method, 'PATCH');
    expect(request.path, _route);
    expect(request.data, <String, Object?>{'stream': 'court-2'});
  });

  test('rotateStreamKey posts an empty object to the rotate route', () async {
    final adapter = _CannedAdapter(status: 200, body: _keyBody());

    await _repository(adapter).rotateStreamKey(_cameraId);

    final request = adapter.requests.single;
    expect(request.method, 'POST');
    expect(request.path, '$_route/rotate');
    expect(request.data, <String, Object?>{});
  });

  test(
    'the model never prints the key, the server or the QR payload',
    () async {
      final adapter = _CannedAdapter(status: 200, body: _keyBody());

      final text = (await _repository(
        adapter,
      ).getStreamKey(_cameraId)).toString();

      expect(text, isNot(contains(_fakeKey)));
      expect(text, isNot(contains(_fakeQr)));
      expect(text, isNot(contains(_fakeServer)));
    },
  );

  test('a response without a data object fails with a fixed message', () async {
    final adapter = _CannedAdapter(
      status: 200,
      body: <String, Object?>{'data': null, 'echo': _fakeKey},
    );

    Object? failure;
    try {
      await _repository(adapter).createStreamKey(_cameraId);
    } on Object catch (error) {
      failure = error;
    }

    expect(failure, isA<FormatException>());
    expect(failure.toString(), isNot(contains(_fakeKey)));
  });

  test(
    'a backend refusal reaches the caller with its verbatim message',
    () async {
      final adapter = _CannedAdapter(
        status: 409,
        body: <String, Object?>{'message': 'Stream name is locked'},
      );

      Object? failure;
      try {
        await _repository(adapter).renameStreamKey(_cameraId, 'court-2');
      } on Object catch (error) {
        failure = error;
      }

      expect(failure, isA<DioException>());
      expect(tournamentSheetServerMessage(failure!), 'Stream name is locked');
    },
  );
}
