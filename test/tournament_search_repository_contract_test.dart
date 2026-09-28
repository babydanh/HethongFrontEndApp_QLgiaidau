import 'dart:collection';
import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/core/services/token_manager.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_tournament_repository.dart';
import 'package:app_quanly_giaidau/domain/usecases/tournament/finalize_tournament_use_case.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoTokenManager extends TokenManager {
  @override
  Future<String?> getAccessToken() async => null;
}

class _StringificationTrackingMap extends MapBase<String, dynamic> {
  _StringificationTrackingMap(this._values);

  final Map<String, dynamic> _values;
  bool wasStringified = false;

  @override
  dynamic operator [](Object? key) => _values[key];

  @override
  void operator []=(String key, dynamic value) => _values[key] = value;

  @override
  void clear() => _values.clear();

  @override
  Iterable<String> get keys => _values.keys;

  @override
  dynamic remove(Object? key) => _values.remove(key);

  @override
  String toString() {
    wasStringified = true;
    return _values.toString();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  dotenv.loadFromString(
    envString:
        'API_BASE_URL=https://api.example.test/api/v1\nAPP_API_KEY=fixture',
  );

  late Dio dio;
  late ApiTournamentRepository repository;
  final requests = <RequestOptions>[];

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    requests.clear();
    dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1'));
    repository = ApiTournamentRepository(
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
                'data': <dynamic>[],
                'meta': {'nextCursor': null, 'hasMore': false},
              },
            ),
          );
        },
      ),
    );
  });

  test('selected category uses existing public tournament DTO key', () async {
    const categoryId = '1e7d7ef1-8d31-4a62-9cb2-3a57a80ad7a2';

    final result = await repository.getPublicTournamentsPaged(
      categoryId: categoryId,
      rethrowOnError: true,
    );

    expect(result.tournaments, isEmpty);
    expect(requests, hasLength(1));
    expect(requests.single.method, 'GET');
    expect(requests.single.path, '/tournaments/public');
    expect(requests.single.queryParameters, {
      'limit': 6,
      'categoryId': categoryId,
    });
    expect(requests.single.queryParameters.keys, isNot(contains('sport')));
  });

  test('finalize sends only the supported status field', () async {
    await FinalizeTournamentUseCase(repository).call('tournament-1');

    expect(requests, hasLength(1));
    expect(requests.single.method, 'PATCH');
    expect(requests.single.path, '/tournaments/tournament-1');
    expect(requests.single.data, {'status': 'COMPLETED'});
  });

  test('tournament update logs never stringify the settings payload', () async {
    final data = _StringificationTrackingMap({
      'tournamentConfig': {'privateValue': 'do-not-log'},
    });

    await repository.update('tournament-1', data);

    expect(requests.single.method, 'PATCH');
    expect(requests.single.data, same(data));
    expect(data.wasStringified, isFalse);
  });
}
