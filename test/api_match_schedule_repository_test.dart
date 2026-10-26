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
  Object? Function(RequestOptions options) reply, {
  int status = 200,
}) {
  final requests = <RequestOptions>[];
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        requests.add(options);
        final response = Response<dynamic>(
          requestOptions: options,
          statusCode: status,
          data: reply(options),
        );
        if (status >= 400) {
          handler.reject(
            DioException.badResponse(
              statusCode: status,
              requestOptions: options,
              response: response,
            ),
          );
          return;
        }
        handler.resolve(response);
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

  group('previewScheduleWithAi', () {
    Map<String, dynamic> aiBody() => {
      'statusCode': 200,
      'message': 'AI schedule previewed',
      'data': {
        'intent': {
          'date': '2026-05-20',
          'roundNumbers': [1],
          'startTime': '08:00',
          'endTime': '22:00',
          'minimumStartIntervalMinutes': 15,
          'timingModel': 'PER_SET',
          'needsReview': true,
          'explanation': 'Vòng 1 từ 8h',
        },
        'preview': {
          'durationMinutes': 30,
          'assignments': [
            {
              'matchId': 'match-1',
              'courtId': 'court-1',
              'scheduledAt': '2026-05-20T01:00:00.000Z',
            },
          ],
          'skipped': [
            {'matchId': 'match-2', 'reason': 'WAITING_FOR_TEAM'},
          ],
          'readiness': {'eligibleCount': 2},
        },
      },
    };

    test('posts the command to the AI route and parses plan + intent', () async {
      final harness = _harness((options) => aiBody());

      final result = await harness.repository.previewScheduleWithAi(
        'tournament-1',
        command: 'vòng 1 từ 8h',
        day: DateTime(2026, 5, 20),
        courtIds: const ['court-1'],
        divisionId: 'division-1',
        windowStart: DateTime.utc(2026, 5, 20, 1),
        windowEnd: DateTime.utc(2026, 5, 20, 15),
        gridIncrementMinutes: 15,
        locale: 'vi',
      );

      final request = harness.requests.single;
      expect(request.method, 'POST');
      expect(request.path, '/ai/tournaments/tournament-1/schedule-preview');
      final body = request.data as Map;
      expect(body['command'], 'vòng 1 từ 8h');
      expect(body['date'], '2026-05-20');
      expect(body['courtIds'], ['court-1']);
      expect(body['divisionId'], 'division-1');
      expect(body['gridIncrementMinutes'], 15);
      expect(body['locale'], 'vi');
      expect(body['operatingWindow'], {
        'start': '2026-05-20T01:00:00.000Z',
        'end': '2026-05-20T15:00:00.000Z',
      });

      expect(result.needsReview, isTrue);
      expect(result.explanation, 'Vòng 1 từ 8h');
      expect(result.plan.durationMinutes, 30);
      expect(result.plan.assignments.single.matchId, 'match-1');
      expect(result.plan.skipped.single.reason, 'WAITING_FOR_TEAM');
    });

    test('omits divisionId when none is selected', () async {
      final harness = _harness((options) => aiBody());

      await harness.repository.previewScheduleWithAi(
        'tournament-1',
        command: 'x',
        day: DateTime(2026, 5, 20),
        courtIds: const ['court-1'],
        windowStart: DateTime.utc(2026, 5, 20, 1),
        windowEnd: DateTime.utc(2026, 5, 20, 15),
      );

      expect((harness.requests.single.data as Map).containsKey('divisionId'), isFalse);
    });

    test('throws AiScheduleUnavailableException when the route answers 404', () async {
      final harness = _harness(
        (options) => {'statusCode': 404, 'message': 'Cannot POST'},
        status: 404,
      );

      expect(
        harness.repository.previewScheduleWithAi(
          'tournament-1',
          command: 'x',
          day: DateTime(2026, 5, 20),
          courtIds: const ['court-1'],
          windowStart: DateTime.utc(2026, 5, 20, 1),
          windowEnd: DateTime.utc(2026, 5, 20, 15),
        ),
        throwsA(isA<AiScheduleUnavailableException>()),
      );
    });

    test('keeps other HTTP errors as DioException so the server message shows', () async {
      final harness = _harness(
        (options) => {'statusCode': 400, 'message': 'Không có trận phù hợp'},
        status: 400,
      );

      expect(
        harness.repository.previewScheduleWithAi(
          'tournament-1',
          command: 'x',
          day: DateTime(2026, 5, 20),
          courtIds: const ['court-1'],
          windowStart: DateTime.utc(2026, 5, 20, 1),
          windowEnd: DateTime.utc(2026, 5, 20, 15),
        ),
        throwsA(isA<DioException>()),
      );
    });
  });
}
