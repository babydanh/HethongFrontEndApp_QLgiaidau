import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/core/services/token_manager.dart';
import 'package:app_quanly_giaidau/data/models/social_session_model.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_social_session_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoTokenManager extends TokenManager {
  @override
  Future<String?> getAccessToken() async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  dotenv.loadFromString(
    envString:
        'API_BASE_URL=https://api.example.test/api/v1\nAPP_API_KEY=fixture',
  );

  late ApiSocialSessionRepository repository;
  late Dio dio;
  final requests = <RequestOptions>[];

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    requests.clear();
    dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1'));
    repository = ApiSocialSessionRepository(
      DioClient(tokenManager: _NoTokenManager(), dio: dio),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          dynamic data = {'data': {}};
          if (options.path == '/social-sessions') {
            data = {
              'data': {
                'id': 'session-1',
                'hostUserId': 'host-1',
                'title': 'Open play',
                'playFormat': 'Giao lưu',
                'startAt': '2026-10-01T10:00:00Z',
                'venueName': 'Venue',
                'venueAddress': 'Address',
                'venueId': 'venue-1',
                'courtId': 'court-1',
                'genderRequirement': 'MIXED',
                'sport': 'pickleball',
                'sportName': 'Pickleball',
              },
            };
          } else if (options.path == '/social-sessions/session-1/requests') {
            data = {
              'data': {
                'items': [
                  {
                    'participant': {
                      'id': 'participant-1',
                      'userId': 'player-1',
                      'sessionId': 'session-1',
                      'status': 'REQUESTED',
                      'ticketCount': 2,
                      'requestedAt': '2026-09-26T10:00:00Z',
                    },
                    'fullName': 'Player One',
                    'avatarUrl': null,
                  },
                ],
                'meta': {'page': 1, 'limit': 20, 'total': 1},
              },
            };
          }
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: data,
            ),
          );
        },
      ),
    );
  });

  test(
    'create sends the idempotency header and supported venue fields',
    () async {
      final request = CreateSocialSessionRequest(
        sport: 'pickleball',
        title: 'Open play',
        startAt: DateTime.utc(2026, 10, 1, 10),
        venueName: 'Venue',
        venueAddress: 'Address',
        venueId: 'venue-1',
        courtId: 'court-1',
        genderRequirement: 'MIXED',
      );

      final session = await repository.create(
        request,
        idempotencyKey: 'stable-retry-key',
      );

      expect(requests.single.path, '/social-sessions');
      expect(requests.single.headers['Idempotency-Key'], 'stable-retry-key');
      expect(requests.single.data['venueId'], 'venue-1');
      expect(requests.single.data['courtId'], 'court-1');
      expect(requests.single.data['genderRequirement'], 'MIXED');
      expect(session.venueId, 'venue-1');
      expect(session.genderRequirement, 'MIXED');
    },
  );

  test(
    'join request list parses pending participants and pagination',
    () async {
      final response = await repository.listJoinRequests(
        'session-1',
        page: 1,
        limit: 20,
      );

      expect(requests.single.path, '/social-sessions/session-1/requests');
      expect(requests.single.queryParameters, {'page': 1, 'limit': 20});
      expect(response.total, 1);
      expect(response.items.single.status, 'REQUESTED');
      expect(response.items.single.ticketCount, 2);
      expect(response.items.single.fullName, 'Player One');
    },
  );

  test(
    'request decisions use only the declared Social Sessions routes',
    () async {
      await repository.requestToJoin('session-1', ticketCount: 2);
      await repository.approveJoinRequest('session-1', 'participant-1');
      await repository.rejectJoinRequest('session-1', 'participant-1');
      await repository.withdrawJoinRequest('session-1');

      expect(requests.map((request) => '${request.method} ${request.path}'), [
        'POST /social-sessions/session-1/requests',
        'POST /social-sessions/session-1/requests/participant-1/approve',
        'POST /social-sessions/session-1/requests/participant-1/reject',
        'DELETE /social-sessions/session-1/requests/self',
      ]);
      expect(requests.first.data, {'ticketCount': 2});
    },
  );
}
