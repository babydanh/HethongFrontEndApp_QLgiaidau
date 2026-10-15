import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/core/services/match_socket_service.dart';
import 'package:app_quanly_giaidau/core/services/token_manager.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_match_repository.dart';
import 'package:app_quanly_giaidau/features/match/utils/pickleball_court.dart';
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

const _baseUrl = 'https://api.example.test/api/v1';

Map<String, dynamic> _matchJson(Map<String, dynamic> courtState) => {
  'id': 'match-1',
  'tournamentId': 'tournament-1',
  'status': 'LIVE',
  'scoreDetails': {'courtState': courtState},
};

ApiMatchRepository _repositoryFor(Dio dio) => ApiMatchRepository(
  DioClient(tokenManager: _NoTokenManager(), dio: dio),
  _UnusedMatchSocketService(),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  dotenv.loadFromString(envString: 'API_BASE_URL=$_baseUrl');

  group('updateCourtState', () {
    test('PATCHes court-state body and returns the saved court', () async {
      SharedPreferences.setMockInitialValues({});
      final dio = Dio(BaseOptions(baseUrl: _baseUrl));
      final requests = <RequestOptions>[];
      final sent = CourtState(startingRightTeam1: 1, autoSwitchEnds: false);
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options);
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: {'data': _matchJson(sent.toJson())},
              ),
            );
          },
        ),
      );

      final match = await _repositoryFor(
        dio,
      ).updateCourtState('match-1', sent.toJson());

      expect(requests, hasLength(1));
      expect(requests.single.method, 'PATCH');
      expect(requests.single.path, '/matches/match-1/court-state');
      expect(requests.single.data, {'courtState': sent.toJson()});
      expect(CourtState.fromJson(match.scoreDetails?['courtState']), sent);
    });

    test('throws the backend message when the server rejects it', () async {
      SharedPreferences.setMockInitialValues({});
      final dio = Dio(BaseOptions(baseUrl: _baseUrl));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.badResponse,
                response: Response<dynamic>(
                  requestOptions: options,
                  statusCode: 400,
                  data: {'message': 'Trận đã kết thúc'},
                ),
              ),
            );
          },
        ),
      );

      await expectLater(
        _repositoryFor(dio).updateCourtState('match-1', const {}),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('Trận đã kết thúc'),
          ),
        ),
      );
    });
  });

  group('mergeCourtState', () {
    test('keeps previous courtState when the payload lacks it', () {
      final previousCourt = {'version': 1, 'autoSwitchEnds': false};
      final incoming = {
        'sets': [
          {'score1': 3},
        ],
      };

      final merged = mergeCourtState(
        selected: incoming,
        incoming: incoming,
        previous: {'courtState': previousCourt, 'sets': <Object?>[]},
      );

      expect(merged, {
        'sets': [
          {'score1': 3},
        ],
        'courtState': previousCourt,
      });
    });

    test('uses the incoming courtState when the payload carries one', () {
      final incomingCourt = {'version': 1, 'autoSwitchEnds': true};

      final merged = mergeCourtState(
        selected: {'courtState': incomingCourt},
        incoming: {'courtState': incomingCourt},
        previous: {
          'courtState': {'version': 1, 'autoSwitchEnds': false},
        },
      );

      expect(merged?['courtState'], incomingCourt);
    });

    test('returns null when neither side has any scoreDetails', () {
      expect(
        mergeCourtState(selected: null, incoming: null, previous: null),
        isNull,
      );
    });
  });
}
