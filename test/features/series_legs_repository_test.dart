import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/core/services/token_manager.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_series_legs_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/series_legs_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoTokenManager extends TokenManager {
  @override
  Future<String?> getAccessToken() async => null;
}

/// Records the request the repository really builds and answers it with
/// [status] / [body] (the response envelope is the caller's job).
class _Backend {
  _Backend(Dio dio) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          final response = Response<dynamic>(
            requestOptions: options,
            statusCode: status,
            data: body,
          );
          if (status >= 400) {
            handler.reject(
              DioException(
                requestOptions: options,
                response: response,
                type: DioExceptionType.badResponse,
              ),
            );
            return;
          }
          handler.resolve(response);
        },
      ),
    );
  }

  final List<RequestOptions> requests = <RequestOptions>[];
  int status = 200;
  Object? body;
}

Map<String, dynamic> _legJson(String id, {int order = 1}) => {
  'id': id,
  'seriesId': 's-1',
  'name': 'Leg $order',
  'order': order,
  'startDate': '2026-05-01T00:00:00.000Z',
  'endDate': null,
  'status': 'UPCOMING',
  'directEntrySlots': 2,
  'wildcardSlots': 16,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const baseUrl = 'https://api.example.test/api/v1';
  late _Backend backend;
  late ApiSeriesLegsRepository repository;

  setUpAll(() => dotenv.loadFromString(envString: 'API_BASE_URL=$baseUrl'));

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    final dio = Dio(BaseOptions(baseUrl: baseUrl));
    repository = ApiSeriesLegsRepository(
      DioClient(tokenManager: _NoTokenManager(), dio: dio),
    );
    backend = _Backend(dio);
  });

  group('reads', () {
    test('TC-SERIESLEGS-01: getLegs parses the enveloped leg list', () async {
      backend.body = {
        'data': [_legJson('l-1'), _legJson('l-2', order: 2)],
      };

      final legs = await repository.getLegs('s-1');

      expect(backend.requests.single.method, 'GET');
      expect(backend.requests.single.path, '/series/s-1/legs');
      expect(legs.map((l) => l.id), ['l-1', 'l-2']);
      expect(legs.first.name, 'Leg 1');
      expect(legs.first.startDate, DateTime.parse('2026-05-01T00:00:00.000Z'));
      expect(legs.first.endDate, isNull);
      expect(legs.first.directEntrySlots, 2);
      expect(legs.first.wildcardSlots, 16);
    });

    test(
      'TC-SERIESLEGS-02: getLegEvents reads the {event, tournament} rows',
      () async {
        backend.body = {
          'data': [
            {
              'event': {
                'id': 'e-1',
                'legId': 'l-1',
                'tournamentId': 't-1',
                'region': 'Tây Nguyên',
                'order': 3,
                'pointMultiplier': 1.5,
              },
              'tournament': {'id': 't-1', 'name': 'Giải A'},
            },
          ],
        };

        final events = await repository.getLegEvents('s-1', 'l-1');

        expect(backend.requests.single.method, 'GET');
        expect(backend.requests.single.path, '/series/s-1/legs/l-1/events');
        final event = events.single;
        expect(event.id, 'e-1');
        expect(event.tournamentId, 't-1');
        expect(event.tournamentName, 'Giải A');
        expect(event.order, 3);
        expect(event.region, 'Tây Nguyên');
        expect(event.pointMultiplier, 1.5);
      },
    );
  });

  group('leg writes', () {
    test('TC-SERIESLEGS-03: createLeg posts the leg body', () async {
      backend.body = {'data': _legJson('l-9')};

      await repository.createLeg(
        's-1',
        SeriesLegInput(
          name: 'Chặng 1',
          order: 1,
          startDate: DateTime.utc(2026, 5, 1),
          directEntrySlots: 2,
          wildcardSlots: 16,
        ),
      );

      final request = backend.requests.single;
      expect(request.method, 'POST');
      expect(request.path, '/organizer/series/s-1/legs');
      expect(request.data, {
        'name': 'Chặng 1',
        'order': 1,
        'startDate': '2026-05-01T00:00:00.000Z',
        'directEntrySlots': 2,
        'wildcardSlots': 16,
      });
    });

    test(
      'TC-SERIESLEGS-04: updateLeg patches and sends null to clear a date',
      () async {
        backend.body = {'data': _legJson('l-1')};

        await repository.updateLeg(
          's-1',
          'l-1',
          const SeriesLegInput(
            name: 'Đổi tên',
            order: 2,
            directEntrySlots: 0,
            wildcardSlots: 4,
          ),
        );

        final request = backend.requests.single;
        expect(request.method, 'PATCH');
        expect(request.path, '/organizer/series/s-1/legs/l-1');
        expect(request.data, {
          'name': 'Đổi tên',
          'order': 2,
          'startDate': null,
          'endDate': null,
          'directEntrySlots': 0,
          'wildcardSlots': 4,
        });
      },
    );

    test('TC-SERIESLEGS-05: deleteLeg sends DELETE on the leg', () async {
      backend.body = {'data': _legJson('l-1')};

      await repository.deleteLeg('s-1', 'l-1');

      expect(backend.requests.single.method, 'DELETE');
      expect(backend.requests.single.path, '/organizer/series/s-1/legs/l-1');
    });
  });

  group('event writes', () {
    test(
      'TC-SERIESLEGS-06: linkTournament posts tournament, order and optionals',
      () async {
        backend.body = {
          'data': {'id': 'e-1'},
        };

        await repository.linkTournament(
          's-1',
          'l-1',
          const SeriesLinkInput(
            tournamentId: 't-1',
            order: 2,
            region: 'Miền Bắc',
            pointMultiplier: 1.5,
          ),
        );

        final request = backend.requests.single;
        expect(request.method, 'POST');
        expect(request.path, '/organizer/series/s-1/legs/l-1/events');
        expect(request.data, {
          'tournamentId': 't-1',
          'order': 2,
          'region': 'Miền Bắc',
          'pointMultiplier': 1.5,
        });
      },
    );

    test(
      'TC-SERIESLEGS-07: linkTournament omits a blank region and multiplier',
      () async {
        backend.body = {
          'data': {'id': 'e-1'},
        };

        await repository.linkTournament(
          's-1',
          'l-1',
          const SeriesLinkInput(tournamentId: 't-1', order: 1, region: '  '),
        );

        expect(backend.requests.single.data, {
          'tournamentId': 't-1',
          'order': 1,
        });
      },
    );

    test(
      'TC-SERIESLEGS-08: unlinkTournament deletes the event under the leg',
      () async {
        backend.body = {
          'data': {'id': 'e-1'},
        };

        await repository.unlinkTournament('s-1', 'l-1', 'e-1');

        expect(backend.requests.single.method, 'DELETE');
        expect(
          backend.requests.single.path,
          '/organizer/series/s-1/legs/l-1/events/e-1',
        );
      },
    );

    test(
      'TC-SERIESLEGS-09: a backend 400 (already linked) reaches the caller',
      () async {
        backend
          ..status = 400
          ..body = {
            'message': 'Giải đấu đã được liên kết với một chuỗi giải khác.',
          };

        await expectLater(
          repository.linkTournament(
            's-1',
            'l-1',
            const SeriesLinkInput(tournamentId: 't-1', order: 1),
          ),
          throwsA(
            isA<DioException>().having(
              (e) => e.response?.statusCode,
              'status',
              400,
            ),
          ),
        );
      },
    );
  });
}
