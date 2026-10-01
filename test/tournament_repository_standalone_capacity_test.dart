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

/// Payload GET /tournaments/:id của giải đứng một mình (không cấu hình nội
/// dung con). Backend dán projection `capacity` cấp GIẢI vào chính payload này
/// khi `/divisions` rỗng, nên client vẫn biết sức chứa thật.
Map<String, dynamic> _standaloneTournament({
  required String format,
  required String name,
  required Map<String, dynamic> capacity,
}) {
  return {
    'id': 'tournament-1',
    'name': name,
    'sport': 'pickleball',
    'format': format,
    'status': 'registration',
    'registrationMode': 'OPEN',
    'maxTeams': 4,
    'maxPlayersPerTeam': format == 'doubles' ? 2 : 1,
    'createdAt': '2026-01-01T00:00:00Z',
    'updatedAt': '2026-01-01T00:00:00Z',
    '_count': {'participants': 8},
    'capacity': capacity,
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Repository với Dio giả: `/divisions` luôn rỗng (giải đứng một mình) nên
  /// đường dẫn tự dựng nội dung chính là đường đi thật của màn hình đăng ký.
  ApiTournamentRepository buildRepository(
    Map<String, dynamic> Function() tournament,
  ) {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1'))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            final data = switch (options.path) {
              '/tournaments/tournament-1' => {'data': tournament()},
              '/tournaments/tournament-1/divisions' => {
                'data': <dynamic>[],
              },
              '/tournaments/tournament-1/sponsors' => {'data': <dynamic>[]},
              _ => <String, dynamic>{'data': <dynamic>[]},
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

  setUpAll(() {
    dotenv.loadFromString(
      envString:
          'API_BASE_URL=https://api.example.test/api/v1\nAPP_API_KEY=fixture',
    );
    SharedPreferences.setMockInitialValues({});
  });

  group('getDivisions for a standalone tournament', () {
    test('synthesised doubles division keeps the full tournament projection', () async {
      final repository = buildRepository(
        () => _standaloneTournament(
          format: 'doubles',
          name: 'Community Doubles Cup',
          capacity: {
            'occupiedTeamSlots': 4,
            'occupiedMemberSlots': 8,
            'maxTeamSlots': 4,
            'isFull': true,
          },
        ),
      );

      final divisions = await repository.getDivisions('tournament-1');

      expect(
        divisions,
        hasLength(1),
        reason: 'giải không có nội dung con thì phải tự dựng nội dung chính',
      );
      final division = divisions.single;
      expect(division.id, 'default_tournament-1');
      expect(division.matchType, 'DOUBLES');
      expect(division.effectiveMaxTeamSlots, 4);
      // Projection cấp giải phải đi qua nội dung tự dựng; nếu rơi ở đây thì
      // màn hình đăng ký sẽ tưởng giải còn trống và cho claim vào chỗ đã đầy.
      expect(division.occupiedTeamSlots, 4.0);
      expect(division.teamSlotsLabel, '4/4');
      expect(division.isFull, isTrue);
    });

    test('synthesised singles division reports the projected occupancy, not zero', () async {
      final repository = buildRepository(
        () => _standaloneTournament(
          format: 'singles',
          name: 'Community Singles Cup',
          capacity: {
            'occupiedTeamSlots': 2,
            'occupiedMemberSlots': 2,
            'maxTeamSlots': 4,
            'isFull': false,
          },
        ),
      );

      final divisions = await repository.getDivisions('tournament-1');

      expect(divisions, hasLength(1));
      final division = divisions.single;
      expect(division.matchType, 'SINGLES');
      // Nội dung tự dựng không mang _count, nên nếu projection bị rơi thì đơn sẽ
      // hiện "0/4" — sai hoàn toàn so với 2 suất đã chiếm.
      expect(division.occupiedTeamSlots, 2.0);
      expect(division.teamSlotsLabel, '2/4');
      expect(division.isFull, isFalse);
    });
  });
}
