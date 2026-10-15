import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/core/services/match_socket_service.dart';
import 'package:app_quanly_giaidau/core/services/token_manager.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_match_repository.dart';
import 'package:app_quanly_giaidau/domain/entities/match_schedule.dart';
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

/// Repository nối vào Dio có interceptor: ghi lại request và trả về [reply].
({ApiMatchRepository repository, List<RequestOptions> requests}) _harness(
  Object? Function(RequestOptions options) reply,
) {
  final requests = <RequestOptions>[];
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        requests.add(options);
        handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            statusCode: 200,
            data: reply(options),
          ),
        );
      },
    ),
  );
  final repository = ApiMatchRepository(
    DioClient(tokenManager: _NoTokenManager(), dio: dio),
    _UnusedMatchSocketService(),
  );
  return (repository: repository, requests: requests);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  dotenv.loadFromString(
    envString: 'API_BASE_URL=https://api.example.test/api/v1',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'updateSchedule sends only the fields it was given, never null for the rest',
    () async {
      final harness = _harness(
        (options) => {
          'status': 'success',
          'data': {
            'id': 'match-1',
            'courtId': 'court-1',
            'courtName': 'Sân 1',
            'scheduledAt': '2026-05-20T01:30:00.000Z',
          },
        },
      );

      await harness.repository.updateSchedule(
        'tournament-1',
        'match-1',
        courtId: 'court-1',
        courtName: 'Sân 1',
        scheduledAt: DateTime.utc(2026, 5, 20, 1, 30),
      );

      final request = harness.requests.single;
      expect(request.method, 'PATCH');
      expect(request.path, '/matches/match-1/schedule');
      expect(request.data, {
        'courtId': 'court-1',
        'courtName': 'Sân 1',
        'scheduledAt': '2026-05-20T01:30:00.000Z',
      });
    },
  );

  test('updateSchedule sends null only for fields listed in clear', () async {
    final harness = _harness(
      (options) => {
        'status': 'success',
        'data': {'id': 'match-1', 'courtId': null, 'scheduledAt': null},
      },
    );

    final snapshot = await harness.repository.updateSchedule(
      'tournament-1',
      'match-1',
      clear: {
        MatchScheduleField.courtId,
        MatchScheduleField.courtName,
        MatchScheduleField.courtAddress,
        MatchScheduleField.scheduledAt,
      },
    );

    expect(harness.requests.single.data, {
      'courtId': null,
      'courtName': null,
      'courtAddress': null,
      'scheduledAt': null,
    });
    expect(snapshot.scheduledAt, isNull);
    expect(snapshot.courtId, isNull);
  });

  test(
    'updateSchedule with only a duration writes matchConfig and nothing else',
    () async {
      final harness = _harness(
        (options) => {
          'status': 'success',
          'data': {'id': 'match-1'},
        },
      );

      await harness.repository.updateSchedule(
        'tournament-1',
        'match-1',
        durationMinutes: 45,
      );

      expect(harness.requests.single.data, {
        'matchConfig': {'durationMinutes': 45},
      });
    },
  );

  test(
    'updateSchedule returns the schedule the server kept when it reflowed the match',
    () async {
      final harness = _harness(
        (options) => {
          'status': 'success',
          'data': {
            'id': 'match-1',
            'courtId': 'court-2',
            'courtName': 'Sân 2',
            'scheduledAt': '2026-05-20T02:00:00.000Z',
          },
        },
      );

      final snapshot = await harness.repository.updateSchedule(
        'tournament-1',
        'match-1',
        courtId: 'court-1',
        courtName: 'Sân 1',
        scheduledAt: DateTime.utc(2026, 5, 20, 1, 30),
      );

      expect(snapshot.courtId, 'court-2');
      expect(snapshot.courtName, 'Sân 2');
      expect(snapshot.scheduledAt, isNotNull);
      expect(
        snapshot.scheduledAt!.isAtSameMomentAs(DateTime.utc(2026, 5, 20, 2)),
        isTrue,
      );
    },
  );

  test(
    'previewSchedulePlan posts the planner window and parses assignments',
    () async {
      final harness = _harness(
        (options) => {
          'status': 'success',
          'data': {
            'durationMinutes': 45,
            'assignments': [
              {
                'matchId': 'match-1',
                'courtId': 'court-1',
                'scheduledAt': '2026-05-20T01:00:00.000Z',
              },
            ],
            'skipped': [
              {'matchId': 'match-2', 'reason': 'BYE'},
            ],
            'readiness': {'eligibleCount': 2, 'assignedCount': 1},
          },
        },
      );

      final preview = await harness.repository.previewSchedulePlan(
        'tournament-1',
        day: DateTime(2026, 5, 20),
        courtIds: const ['court-1'],
        matchIds: const ['match-1', 'match-2'],
        windowStart: DateTime.utc(2026, 5, 20),
        windowEnd: DateTime.utc(2026, 5, 20, 15),
        durationMinutes: 45,
      );

      final request = harness.requests.single;
      expect(request.method, 'POST');
      expect(request.path, '/tournaments/tournament-1/schedule-plans');
      final body = request.data as Map;
      expect(body['date'], '2026-05-20');
      expect(body['courtIds'], ['court-1']);
      expect(body['matchIds'], ['match-1', 'match-2']);
      expect(body['durationMinutes'], 45);
      expect(body['changeoverMinutes'], 0);
      expect(body['minimumStartIntervalMinutes'], 15);
      expect(body['operatingWindow'], {
        'start': '2026-05-20T00:00:00.000Z',
        'end': '2026-05-20T15:00:00.000Z',
      });
      expect(body['strategy'], 'ROUND_ORDER_EARLIEST_AVAILABLE');

      expect(preview.durationMinutes, 45);
      expect(preview.eligibleCount, 2);
      expect(preview.assignments.single.matchId, 'match-1');
      expect(preview.assignments.single.courtId, 'court-1');
      expect(
        preview.assignments.single.scheduledAt,
        DateTime.utc(2026, 5, 20, 1).toLocal(),
      );
      expect(preview.skipped.single.reason, 'BYE');
    },
  );
}
