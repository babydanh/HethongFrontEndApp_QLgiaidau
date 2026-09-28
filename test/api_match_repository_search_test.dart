import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/core/services/match_socket_service.dart';
import 'package:app_quanly_giaidau/core/services/token_manager.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_match_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoTokenManager extends TokenManager {
  @override
  Future<String?> getAccessToken() async => null;
}

class _UnusedMatchSocketService implements MatchSocketService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  dotenv.loadFromString(
    envString: 'API_BASE_URL=https://api.example.test/api/v1',
  );

  test('public search maps nested tournament name into MatchModel', () async {
    SharedPreferences.setMockInitialValues({});
    final requests = <RequestOptions>[];
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1'));
    final repository = ApiMatchRepository(
      DioClient(tokenManager: _NoTokenManager(), dio: dio),
      _UnusedMatchSocketService(),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: {
                'data': [
                  {
                    'id': 'match-1',
                    'tournamentId': 'tournament-1',
                    'tournament': {'name': 'Bracket Cup'},
                    'participant1': {'teamName': 'Player Alpha'},
                    'participant2': {'teamName': 'Player Beta'},
                    'status': 'SCHEDULED',
                  },
                ],
                'meta': {'total': 1, 'hasMore': false},
              },
            ),
          );
        },
      ),
    );

    final page = await repository.getPublicMatchesPaged();

    expect(requests, hasLength(1));
    expect(requests.single.method, 'GET');
    expect(requests.single.path, '/matches');
    expect(page.matches.single.tournamentName, 'Bracket Cup');
  });
}
