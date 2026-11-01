
import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/core/services/token_manager.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_team_repository.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_tournament_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoTokenManager extends TokenManager {
  @override
  Future<String?> getAccessToken() async => null;
}

/// Dio giả giữ mọi request trong một khoảng ngắn để đo số request bay cùng lúc.
/// Nếu repository gọi nối đuôi thì đỉnh đồng thời chỉ là 1.
class _ConcurrencyProbe {
  int inFlight = 0;
  int peak = 0;
  final paths = <String>[];

  Dio build(Object Function(String path) body) {
    return Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1'))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            paths.add(options.path);
            inFlight++;
            if (inFlight > peak) peak = inFlight;
            await Future<void>.delayed(const Duration(milliseconds: 60));
            inFlight--;
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: body(options.path),
              ),
            );
          },
        ),
      );
  }
}

Map<String, dynamic> _tournamentJson() => {
  'id': 'tournament-1',
  'name': 'Open speed cup',
  'sport': 'pickleball',
  'format': 'doubles',
  'status': 'in_progress',
  'maxTeams': 4,
  'createdAt': '2026-01-01T00:00:00Z',
  'updatedAt': '2026-01-01T00:00:00Z',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.loadFromString(
      envString:
          'API_BASE_URL=https://api.example.test/api/v1\nAPP_API_KEY=fixture',
    );
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'TC-OPEN-SPEED-01 getById sends detail, divisions and sponsors together',
    () async {
      final probe = _ConcurrencyProbe();
      final dio = probe.build(
        (path) => switch (path) {
          '/tournaments/tournament-1' => {'data': _tournamentJson()},
          _ => {'data': <dynamic>[]},
        },
      );
      final repository = ApiTournamentRepository(
        DioClient(tokenManager: _NoTokenManager(), dio: dio),
      );

      final tournament = await repository.getById('tournament-1');

      expect(tournament?.name, 'Open speed cup');
      expect(probe.paths, hasLength(3));
      expect(probe.peak, 3);
    },
  );

  test(
    'TC-OPEN-SPEED-02 optional divisions failure still returns the tournament',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1'))
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              if (options.path.endsWith('/divisions')) {
                handler.reject(
                  DioException(requestOptions: options, message: 'boom'),
                );
                return;
              }
              handler.resolve(
                Response<dynamic>(
                  requestOptions: options,
                  statusCode: 200,
                  data: options.path == '/tournaments/tournament-1'
                      ? {'data': _tournamentJson()}
                      : {'data': <dynamic>[]},
                ),
              );
            },
          ),
        );
      final repository = ApiTournamentRepository(
        DioClient(tokenManager: _NoTokenManager(), dio: dio),
      );

      final tournament = await repository.getById('tournament-1');

      expect(tournament?.id, 'tournament-1');
    },
  );

  test(
    'TC-OPEN-SPEED-03 team list loads participants and divisions together',
    () async {
      final probe = _ConcurrencyProbe();
      final dio = probe.build((_) => {'data': <dynamic>[]});
      final repository = ApiTeamRepository(
        DioClient(tokenManager: _NoTokenManager(), dio: dio),
      );

      final teams = await repository.getAllByTournament('tournament-1');

      expect(teams, isEmpty);
      expect(probe.paths, hasLength(2));
      expect(probe.peak, 2);
    },
  );
}
