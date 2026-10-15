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

const _bracketPayload = {
  'statusCode': 200,
  'message': 'Success',
  'data': {
    'stages': [
      {
        'name': 'Vòng loại',
        'type': 'SINGLE_ELIMINATION',
        'tournamentDivisionId': 'div-stage',
        'groups': [
          {
            'name': 'Nhánh chính',
            'matches': [
              {
                'id': 'bracket-match-1',
                'roundNumber': 1,
                'matchOrder': 1,
                'status': 'SCHEDULED',
                'isBye': false,
                'participant1': {'id': 'p1', 'teamName': 'Team A'},
                'participant2': {'id': 'p2', 'teamName': 'Team B'},
                'scheduledAt': '2026-10-14T01:00:00.000Z',
                'courtId': 'court-1',
                'courtName': 'Sân 1',
                'durationMinutes': 30,
                'updatedAt': '2026-10-13T00:00:00.000Z',
              },
              {
                'id': 'bracket-match-2',
                'divisionId': 'div-match',
                'roundNumber': 1,
                'matchOrder': 2,
                'status': 'SCHEDULED',
                'participant1': {'id': 'p3', 'teamName': 'Team C'},
                'participant2': {'id': 'p4', 'teamName': 'Team D'},
                'updatedAt': '2026-10-13T00:00:00.000Z',
              },
            ],
          },
        ],
      },
    ],
  },
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  dotenv.loadFromString(
    envString:
        'API_BASE_URL=https://api.example.test/api/v1\nAPP_API_KEY=fixture',
  );

  late ApiTournamentRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1'));
    repository = ApiTournamentRepository(
      DioClient(tokenManager: _NoTokenManager(), dio: dio),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: _bracketPayload,
            ),
          );
        },
      ),
    );
  });

  test('bracket match keeps its scheduled time, court and duration', () async {
    final matches = await repository.getBracketMatches('tournament-1');

    expect(matches, hasLength(2));
    final match = matches.first;
    expect(match.scheduledTime, isNotNull);
    expect(
      match.scheduledTime!.isAtSameMomentAs(
        DateTime.parse('2026-10-14T01:00:00.000Z'),
      ),
      isTrue,
    );
    expect(match.courtId, 'court-1');
    expect(match.courtName, 'Sân 1');
    expect(match.durationMinutes, 30);
  });

  // Lịch Lite đọc từ bracket: thiếu divisionId thì thẻ trận mất tên hạng mục.
  test(
    'bracket match carries its division from the match or its stage',
    () async {
      final matches = await repository.getBracketMatches('tournament-1');

      expect(matches.map((m) => m.divisionId), ['div-stage', 'div-match']);
    },
  );
}
