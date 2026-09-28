import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/core/services/token_manager.dart';
import 'package:app_quanly_giaidau/data/models/camera_device_model.dart';
import 'package:app_quanly_giaidau/data/models/facebook_page_connection_model.dart';
import 'package:app_quanly_giaidau/data/models/live_session_model.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_live_session_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoTokenManager extends TokenManager {
  @override
  Future<String?> getAccessToken() async => null;
}

/// Every management route answers with this envelope.
Map<String, dynamic> _envelope(Object? data) => <String, dynamic>{
  'statusCode': 200,
  'message': 'Success',
  'data': data,
  'meta': <String, dynamic>{'timestamp': '2026-01-01T00:00:00.000Z'},
};

/// Records the [RequestOptions] the repository really builds and answers only
/// the routes a test registered, keyed by method *and* path. A call that drifts
/// to a different verb or URL finds no fixture and fails loudly.
class _FakeBackend {
  _FakeBackend(this._dio);

  final Dio _dio;
  final List<RequestOptions> requests = <RequestOptions>[];
  final Map<String, Object?> _routes = <String, Object?>{};
  int _nextStatus = 200;

  void onGet(String path, Object? data) =>
      _routes['GET $path'] = _envelope(data);

  void onPost(String path, Object? data) =>
      _routes['POST $path'] = _envelope(data);

  void onDelete(String path, Object? data) =>
      _routes['DELETE $path'] = _envelope(data);

  /// Answers the next call with [status] and no fixture lookup.
  void failWith(int status) => _nextStatus = status;

  RequestOptions get only {
    if (requests.length != 1) {
      throw StateError(
        'Expected exactly 1 request, got ${requests.length}: '
        '${requests.map((r) => '${r.method} ${r.path}').join(', ')}',
      );
    }
    return requests.single;
  }

  void install() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          if (_nextStatus != 200) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.badResponse,
                response: Response<dynamic>(
                  requestOptions: options,
                  statusCode: _nextStatus,
                  data: _envelope(<String, dynamic>{'message': 'denied'}),
                ),
              ),
            );
            return;
          }
          final key = '${options.method.toUpperCase()} ${options.path}';
          if (!_routes.containsKey(key)) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.badResponse,
                error: 'No fixture registered for $key',
                response: Response<dynamic>(
                  requestOptions: options,
                  statusCode: 404,
                  data: _envelope(<String, dynamic>{
                    'message': 'No fixture: $key',
                  }),
                ),
              ),
            );
            return;
          }
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: _routes[key],
            ),
          );
        },
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const baseUrl = 'https://api.example.test/api/v1';
  const communityId = 'community-1';
  const tournamentId = 'tournament-1';

  late _FakeBackend backend;
  late ApiLiveSessionRepository repository;

  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=$baseUrl');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    final dio = Dio(BaseOptions(baseUrl: baseUrl));
    repository = ApiLiveSessionRepository(
      DioClient(tokenManager: _NoTokenManager(), dio: dio),
    );
    // Installed after the client so the fake observes the request as the
    // client finally emitted it.
    backend = _FakeBackend(dio)..install();
  });

  group('tournament sessions', () {
    test('list reads the monitor route with no query and no cache', () async {
      backend.onGet('/livestream/tournaments/$tournamentId/sessions', [
        {
          'id': 'session-1',
          'tournamentId': tournamentId,
          'matchId': 'match-1',
          'status': 'RECONNECTING',
          'provider': 'facebook',
          'title': 'Court 1 semi-final',
        },
      ]);

      final sessions = await repository.listSessions(tournamentId);

      expect(sessions, hasLength(1));
      expect(sessions.single.status, LiveSessionStatus.reconnecting);
      expect(sessions.single.title, 'Court 1 semi-final');
      expect(backend.only.method, 'GET');
      expect(
        backend.only.path,
        '/livestream/tournaments/$tournamentId/sessions',
      );
      expect(backend.only.queryParameters, isEmpty);
    });

    test(
      'recheck re-polls through the reconnect route without a body',
      () async {
        backend.onPost('/livestream/sessions/session-1/reconnect', {
          'session': {
            'id': 'session-1',
            'tournamentId': tournamentId,
            'matchId': 'match-1',
            'status': 'LIVE',
          },
        });

        final result = await repository.reconnectSession('session-1');

        expect(result.session.status, LiveSessionStatus.live);
        expect(backend.only.method, 'POST');
        expect(backend.only.path, '/livestream/sessions/session-1/reconnect');
        expect(backend.only.data, isNull);
      },
    );

    test('stop posts to the stop route', () async {
      backend.onPost('/livestream/sessions/session-1/stop', {
        'id': 'session-1',
        'tournamentId': tournamentId,
        'matchId': 'match-1',
        'status': 'ENDED',
      });

      final session = await repository.stopSession('session-1');

      expect(session.status, LiveSessionStatus.ended);
      expect(backend.only.path, '/livestream/sessions/session-1/stop');
    });
  });

  group('pairing token', () {
    test('issues a token on the device item route with an empty body', () async {
      backend.onPost('/livestream/devices/device-1/pairing-token', {
        'device': {
          'id': 'device-1',
          'communityId': communityId,
          'name': 'Camera A',
          'status': 'UNPAIRED',
        },
        'pairingToken': 'token-abc',
        'expiresAt': '2026-01-01T00:10:00.000Z',
      });

      final result = await repository.createPairingToken('device-1');

      expect(result.pairingToken, 'token-abc');
      expect(result.device.id, 'device-1');
      expect(backend.only.method, 'POST');
      expect(backend.only.path, '/livestream/devices/device-1/pairing-token');
      // No ttlSeconds: the server default (600s) is what the operator wants and
      // the DTO rejects anything outside 60..1800.
      expect(backend.only.data, <String, Object?>{});
    });
  });

  group('camera devices', () {
    test('create posts only the community id and the display name', () async {
      backend.onPost('/livestream/devices', {
        'id': 'device-9',
        'communityId': communityId,
        'name': 'Court 1 phone',
        'status': 'UNPAIRED',
      });

      final created = await repository.createDevice(
        communityId: communityId,
        name: 'Court 1 phone',
      );

      expect(created.id, 'device-9');
      expect(created.name, 'Court 1 phone');
      expect(created.status, CameraDeviceStatus.unpaired);
      expect(backend.only.method, 'POST');
      expect(backend.only.path, '/livestream/devices');
      // The community is addressed in the body, never in the path or query,
      // and nothing else may be sent: the server owns every device secret.
      expect(backend.only.queryParameters, isEmpty);
      expect(backend.only.data, <String, Object?>{
        'communityId': communityId,
        'name': 'Court 1 phone',
      });
    });
  });

  group('facebook page connection', () {
    test('status read sends communityId as a query parameter', () async {
      backend.onGet('/livestream/facebook/connection', {
        'id': 'conn-1',
        'communityId': communityId,
        'pageId': 'page-1',
        'pageName': 'Sporto FC',
        'status': 'ACTIVE',
        'lastValidatedAt': '2026-01-01T00:00:00.000Z',
      });

      final connection = await repository.getFacebookConnection(communityId);

      expect(connection?.status, FacebookPageConnectionStatus.active);
      expect(connection?.pageName, 'Sporto FC');
      expect(backend.only.method, 'GET');
      expect(backend.only.path, '/livestream/facebook/connection');
      expect(backend.only.queryParameters, {'communityId': communityId});
    });

    test(
      'a null data payload reads as no connection, not as the envelope',
      () async {
        backend.onGet('/livestream/facebook/connection', null);

        expect(await repository.getFacebookConnection(communityId), isNull);
      },
    );

    test('connect returns only the authorization URL', () async {
      backend.onGet('/livestream/facebook/connect', {
        'authorizationUrl': 'https://www.facebook.com/v23.0/dialog/oauth?x=1',
        'stateExpiresAt': '2026-01-01T00:10:00.000Z',
      });

      final url = await repository.createFacebookOAuthUrl(communityId);

      expect(url, 'https://www.facebook.com/v23.0/dialog/oauth?x=1');
      expect(backend.only.path, '/livestream/facebook/connect');
      expect(backend.only.queryParameters, {'communityId': communityId});
    });

    test('connect refuses to hand back a URL it cannot launch', () async {
      backend.onGet('/livestream/facebook/connect', <String, dynamic>{
        'stateExpiresAt': '2026-01-01T00:10:00.000Z',
      });

      await expectLater(
        repository.createFacebookOAuthUrl(communityId),
        throwsStateError,
      );
    });

    test(
      'revalidate sends connectionId as a query parameter, not a body',
      () async {
        backend.onPost('/livestream/facebook/validate', {
          'id': 'conn-1',
          'communityId': communityId,
          'pageId': 'page-1',
          'pageName': 'Sporto FC',
          'status': 'REVOKED',
        });

        final connection = await repository.validateFacebookConnection(
          'conn-1',
        );

        expect(connection.status, FacebookPageConnectionStatus.revoked);
        expect(backend.only.method, 'POST');
        expect(backend.only.path, '/livestream/facebook/validate');
        expect(backend.only.queryParameters, {'connectionId': 'conn-1'});
        expect(backend.only.data, isNull);
      },
    );

    test(
      'disconnect deletes the collection route with communityId in the query',
      () async {
        backend.onDelete('/livestream/facebook/connection', {
          'id': 'conn-1',
          'communityId': communityId,
          'pageId': 'page-1',
          'pageName': 'Sporto FC',
          'status': 'DISCONNECTED',
        });

        final connection = await repository.disconnectFacebookConnection(
          communityId,
        );

        expect(connection?.status, FacebookPageConnectionStatus.disconnected);
        expect(backend.only.method, 'DELETE');
        expect(backend.only.path, '/livestream/facebook/connection');
        expect(backend.only.queryParameters, {'communityId': communityId});
        expect(backend.only.data, isNull);
      },
    );
  });

  group('server authorization', () {
    test(
      'a 403 surfaces as a DioException the UI can render as forbidden',
      () async {
        backend.failWith(403);

        await expectLater(
          repository.listSessions(tournamentId),
          throwsA(
            isA<DioException>().having(
              (e) => e.response?.statusCode,
              'statusCode',
              403,
            ),
          ),
        );
      },
    );
  });
}
