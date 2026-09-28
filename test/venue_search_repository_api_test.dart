import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/core/services/token_manager.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_venue_search_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoTokenManager extends TokenManager {
  @override
  Future<String?> getAccessToken() async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  dotenv.loadFromString(
    envString:
        'API_BASE_URL=https://api.example.test/api/v1\nAPP_API_KEY=fixture',
  );

  late ApiVenueSearchRepository repository;
  late Dio dio;
  final requests = <RequestOptions>[];
  var responseRows = <dynamic>[];

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    requests.clear();
    responseRows = <dynamic>[
      {
        'id': 'venue-1',
        'name': 'Sân Quận 10',
        'locationAddress': 'Quận 10, TP. Hồ Chí Minh',
        'ownerUserId': 'not-rendered',
      },
      {'id': 'venue-2', 'name': 'Thiếu địa chỉ', 'locationAddress': '  '},
      'malformed-row',
    ];
    dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1'));
    repository = ApiVenueSearchRepository(
      DioClient(tokenManager: _NoTokenManager(), dio: dio),
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
                'statusCode': 200,
                'message': 'Success',
                'data': options.path == '/venues/venue-1'
                    ? {
                        'id': 'venue-1',
                        'name': 'Sân Quận 10',
                        'locationAddress': 'Quận 10, TP. Hồ Chí Minh',
                        'courts': [
                          {
                            'id': 'court-1',
                            'courtName': 'Court 1',
                            'status': 'AVAILABLE',
                          },
                          {
                            'id': 'court-2',
                            'courtName': 'Court 2',
                            'status': 'MAINTENANCE',
                          },
                        ],
                      }
                    : responseRows,
                'meta': {'page': 1, 'limit': 8, 'total': 3},
              },
            ),
          );
        },
      ),
    );
  });

  test(
    'search uses the public venue contract and filters unusable rows',
    () async {
      final venues = await repository.search('  Quận 10  ', limit: 20);

      expect(requests, hasLength(1));
      expect(requests.single.method, 'GET');
      expect(requests.single.path, '/venues');
      expect(requests.single.queryParameters, {
        'search': 'Quận 10',
        'page': 1,
        'limit': 8,
      });
      expect(venues, hasLength(1));
      expect(venues.single.id, 'venue-1');
      expect(venues.single.name, 'Sân Quận 10');
      expect(venues.single.locationAddress, 'Quận 10, TP. Hồ Chí Minh');
    },
  );

  test(
    'venue details expose only available courts from the same venue',
    () async {
      final details = await repository.getById('venue-1');

      expect(requests.single.path, '/venues/venue-1');
      expect(details.venue.id, 'venue-1');
      expect(details.courts.map((court) => court.id), ['court-1']);
    },
  );

  test('short queries do not call the API', () async {
    final venues = await repository.search('  a  ');

    expect(venues, isEmpty);
    expect(requests, isEmpty);
  });
}
