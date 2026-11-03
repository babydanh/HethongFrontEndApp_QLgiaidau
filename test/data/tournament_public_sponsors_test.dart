import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/core/services/token_manager.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_tournament_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoTokenManager extends TokenManager {
  @override
  Future<String?> getAccessToken() async => null;
}

Map<String, dynamic> _tournamentJson() => {
  'id': 'tournament-1',
  'name': 'Sponsor cup',
  'sport': 'pickleball',
  'format': 'doubles',
  'status': 'in_progress',
  'maxTeams': 4,
  'createdAt': '2026-01-01T00:00:00Z',
  'updatedAt': '2026-01-01T00:00:00Z',
};

Map<String, dynamic> _sponsor(String id, String name, String logoUrl) => {
  'id': id,
  'displayName': name,
  'tier': 'GOLD',
  'logoUrl': logoUrl,
};

ApiTournamentRepository _repository(List<Map<String, dynamic>> sponsors) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1'))
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final data = switch (options.path) {
            '/tournaments/tournament-1' => {'data': _tournamentJson()},
            '/tournaments/tournament-1/sponsors' => {'data': sponsors},
            _ => {'data': <dynamic>[]},
          };
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
  return ApiTournamentRepository(
    DioClient(tokenManager: _NoTokenManager(), dio: dio),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.loadFromString(
      envString:
          'API_BASE_URL=https://api.example.test/api/v1\nAPP_API_KEY=fixture',
    );
    SharedPreferences.setMockInitialValues({});
  });

  test('TC-SPON-01 a public sponsor without a logo is still listed', () async {
    final repository = _repository([
      _sponsor('1', 'Co logo', 'https://cdn.example.test/a.png'),
      _sponsor('2', 'Chua co logo', ''),
    ]);

    final sponsors = await repository.getPublicSponsors('tournament-1');

    expect(sponsors.map((s) => s.displayName), ['Co logo', 'Chua co logo']);
  });

  test('TC-SPON-02 a sponsor without a name is still dropped', () async {
    final repository = _repository([_sponsor('1', '', '')]);

    expect(await repository.getPublicSponsors('tournament-1'), isEmpty);
  });

  test(
    'TC-SPON-03 the tournament keeps a logo-less sponsor so the tab shows',
    () async {
      final repository = _repository([_sponsor('2', 'Chua co logo', '')]);

      final tournament = await repository.getById('tournament-1');

      expect(tournament?.sponsors.map((s) => s.displayName), ['Chua co logo']);
    },
  );
}
