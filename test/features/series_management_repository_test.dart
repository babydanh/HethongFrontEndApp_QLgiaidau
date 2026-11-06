import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/core/services/token_manager.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_series_management_repository.dart';
import 'package:app_quanly_giaidau/domain/entities/managed_series.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoTokenManager extends TokenManager {
  @override
  Future<String?> getAccessToken() async => null;
}

/// Answers only the routes a test registered (keyed by method and path) and
/// records the request the repository really built.
class _FakeBackend {
  _FakeBackend(Dio dio) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          final reply = _routes['${options.method} ${options.path}'];
          if (reply == null) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.badResponse,
                response: Response<dynamic>(
                  requestOptions: options,
                  statusCode: 404,
                  data: {'message': 'No fixture'},
                ),
              ),
            );
            return;
          }
          // Non-2xx fixtures are rejected like Dio does for bad status codes.
          final response = Response<dynamic>(
            requestOptions: options,
            statusCode: reply.$1,
            data: reply.$2,
          );
          if (reply.$1 >= 400) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.badResponse,
                response: response,
              ),
            );
            return;
          }
          handler.resolve(response);
        },
      ),
    );
  }

  final List<RequestOptions> requests = [];
  final Map<String, (int, Object?)> _routes = {};

  void on(String method, String path, Object? body, {int status = 200}) =>
      _routes['$method $path'] = (status, body);

  RequestOptions get only {
    expect(requests, hasLength(1));
    return requests.single;
  }
}

Map<String, dynamic> _envelope(Object? data) => {
  'statusCode': 200,
  'message': 'Success',
  'data': data,
};

Map<String, dynamic> _seriesJson({String id = 's-1'}) => {
  'id': id,
  'slug': 'cup-2026-ab12',
  'name': 'Cup 2026',
  'description': '  ',
  'bannerUrl': null,
  'logoUrl': 'https://x.test/l.png',
  'status': 'ACTIVE',
  'visibility': 'PRIVATE',
  'startDate': '2026-05-01T00:00:00.000Z',
  'endDate': null,
  'totalPrize': '500000.00',
  'rules': {
    'pointsByRank': {'1': 100, '3': '60'},
    'directEntryThreshold': 2,
    'wildcardCount': 16,
    'exclusionRule': true,
    'exclusionScope': 'ALL',
    'description': 'Luat',
  },
};

SeriesInput _input({String? status}) => SeriesInput(
  name: 'Đường đến Superstars!',
  description: 'Mô tả',
  visibility: 'PUBLIC',
  startDate: DateTime.utc(2026, 5, 1),
  totalPrize: 1000,
  status: status,
  rules: const SeriesRules(
    pointsByRank: {1: 100, 2: 80},
    directEntryThreshold: 2,
    wildcardCount: 8,
    exclusionRule: false,
    exclusionScope: 'CATEGORY',
    description: 'Luat',
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeBackend backend;
  late ApiSeriesManagementRepository repository;

  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=https://api.example.test');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'));
    repository = ApiSeriesManagementRepository(
      DioClient(tokenManager: _NoTokenManager(), dio: dio),
    );
    backend = _FakeBackend(dio);
  });

  test(
    'TC-SERIESMGMT-01 listMine filters by organizer on GET /series',
    () async {
      backend.on(
        'GET',
        '/series',
        _envelope([_seriesJson(), _seriesJson(id: 's-2')]),
      );

      final list = await repository.listMine('org-1');

      expect(backend.only.method, 'GET');
      expect(backend.only.path, '/series');
      expect(backend.only.queryParameters, {
        'organizerId': 'org-1',
        'limit': 50,
      });
      expect(list.map((s) => s.id), ['s-1', 's-2']);
    },
  );

  test('TC-SERIESMGMT-02 listMine returns empty list for empty data', () async {
    backend.on('GET', '/series', _envelope(<dynamic>[]));
    expect(await repository.listMine('org-1'), isEmpty);
  });

  test(
    'TC-SERIESMGMT-03 model parses Backend row (numeric string, blanks)',
    () async {
      backend.on('GET', '/series', _envelope([_seriesJson()]));

      final s = (await repository.listMine('org-1')).single;

      expect(s.totalPrize, 500000);
      expect(s.description, isNull);
      expect(s.bannerUrl, isNull);
      expect(s.logoUrl, 'https://x.test/l.png');
      expect(s.visibility, 'PRIVATE');
      expect(s.endDate, isNull);
      expect(s.startDate!.toUtc(), DateTime.utc(2026, 5, 1));
      expect(s.rules.pointsByRank, {1: 100, 3: 60});
      expect(s.rules.exclusionScope, 'ALL');
    },
  );

  test(
    'TC-SERIESMGMT-04 getById reads data.series of GET /series/:id',
    () async {
      backend.on(
        'GET',
        '/series/s-1',
        _envelope({'series': _seriesJson(), 'legs': <dynamic>[]}),
      );

      final s = await repository.getById('s-1');

      expect(backend.only.method, 'GET');
      expect(s.name, 'Cup 2026');
    },
  );

  test(
    'TC-SERIESMGMT-05 create posts DTO fields plus a generated slug',
    () async {
      backend.on(
        'POST',
        '/organizer/series',
        _envelope(_seriesJson()),
        status: 201,
      );

      final created = await repository.create(_input());

      final req = backend.only;
      expect(req.method, 'POST');
      expect(req.path, '/organizer/series');
      final body = req.data as Map<String, dynamic>;
      expect(
        body['slug'],
        matches(RegExp(r'^duong-den-superstars-[a-z0-9]{4}$')),
      );
      expect(body['name'], 'Đường đến Superstars!');
      expect(body['description'], 'Mô tả');
      expect(body['visibility'], 'PUBLIC');
      expect(body['startDate'], '2026-05-01T00:00:00.000Z');
      expect(body['totalPrize'], 1000);
      expect(body.containsKey('endDate'), isFalse);
      expect(body.containsKey('bannerUrl'), isFalse);
      expect(body.containsKey('status'), isFalse);
      expect(body['rules'], {
        'pointsByRank': {'1': 100, '2': 80},
        'directEntryThreshold': 2,
        'wildcardCount': 8,
        'exclusionRule': false,
        'exclusionScope': 'CATEGORY',
        'description': 'Luat',
      });
      expect(created.id, 's-1');
    },
  );

  test('TC-SERIESMGMT-06 update patches by id without slug', () async {
    backend.on('PATCH', '/organizer/series/s-1', _envelope(_seriesJson()));

    await repository.update('s-1', _input(status: 'ACTIVE'));

    final req = backend.only;
    expect(req.method, 'PATCH');
    expect(req.path, '/organizer/series/s-1');
    final body = req.data as Map<String, dynamic>;
    expect(body.containsKey('slug'), isFalse);
    expect(body['status'], 'ACTIVE');
    expect(body['name'], 'Đường đến Superstars!');
    // A cleared optional value is sent so the Backend really clears it.
    expect(body.containsKey('endDate'), isTrue);
    expect(body['endDate'], isNull);
    expect(body['bannerUrl'], '');
  });

  test('TC-SERIESMGMT-07 delete sends DELETE by id', () async {
    backend.on('DELETE', '/organizer/series/s-1', _envelope(_seriesJson()));

    await repository.delete('s-1');

    expect(backend.only.method, 'DELETE');
    expect(backend.only.path, '/organizer/series/s-1');
  });

  test('TC-SERIESMGMT-08 a 409 from create reaches the caller', () async {
    backend.on('POST', '/organizer/series', {
      'message': 'Slug đã tồn tại',
    }, status: 409);

    await expectLater(
      repository.create(_input()),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'status',
          409,
        ),
      ),
    );
  });
}
