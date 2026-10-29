import 'dart:convert';
import 'dart:typed_data';

import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/core/services/token_manager.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_external_rating_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoTokenManager extends TokenManager {
  @override
  Future<String?> getAccessToken() async => null;
}

/// Records every request and answers with [handler].
class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this.handler);

  final ResponseBody Function(RequestOptions options) handler;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object body, [int status = 200]) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

({ApiExternalRatingRepository repo, _RecordingAdapter adapter}) _build(
  ResponseBody Function(RequestOptions options) handler,
) {
  final adapter = _RecordingAdapter(handler);
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1'))
    ..httpClientAdapter = adapter;
  return (
    repo: ApiExternalRatingRepository(
      DioClient(tokenManager: _NoTokenManager(), dio: dio),
    ),
    adapter: adapter,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  dotenv.loadFromString(
    envString: 'API_BASE_URL=https://api.example.test/api/v1',
  );

  test('getMyDuprRating sends the filters and prefers the API row', () async {
    final t = _build(
      (_) => _json({
        'statusCode': 200,
        'data': [
          {'source': 'SELF', 'value': 3.1},
          {'source': 'API', 'value': 3.4},
        ],
        'meta': {'total': 2, 'page': 1, 'limit': 100, 'totalPages': 1},
      }),
    );

    final rating = await t.repo.getMyDuprRating(
      categoryId: 'cat-1',
      matchType: 'DOUBLES',
    );

    expect(rating, 3.4);
    final request = t.adapter.requests.single;
    expect(request.method, 'GET');
    expect(request.path, '/users/me/external-ratings');
    expect(request.queryParameters, {
      'provider': 'DUPR',
      'categoryId': 'cat-1',
      'matchType': 'DOUBLES',
      'limit': 100,
    });
  });

  test('getMyDuprRating returns null when there are no rows', () async {
    final t = _build((_) => _json({'statusCode': 200, 'data': <Object>[]}));

    expect(
      await t.repo.getMyDuprRating(categoryId: 'cat-1', matchType: 'SINGLES'),
      isNull,
    );
  });

  test('getMyDuprRating rethrows network errors', () async {
    final t = _build(
      (options) => throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      ),
    );

    await expectLater(
      t.repo.getMyDuprRating(categoryId: 'cat-1', matchType: 'SINGLES'),
      throwsA(isA<DioException>()),
    );
  });

  test('saveMyDuprRating PUTs the declared rating', () async {
    final t = _build((_) => _json({'statusCode': 200, 'data': {'id': 'r1'}}));

    await t.repo.saveMyDuprRating(
      categoryId: 'cat-1',
      matchType: 'MIXED_DOUBLES',
      value: 3.62,
    );

    final request = t.adapter.requests.single;
    expect(request.method, 'PUT');
    expect(request.path, '/users/me/external-ratings');
    expect(request.data, {
      'categoryId': 'cat-1',
      'matchType': 'MIXED_DOUBLES',
      'provider': 'DUPR',
      'value': 3.62,
      'isPublic': true,
    });
  });

  test('saveMyDuprRating rethrows a rejected save', () async {
    final t = _build(
      (_) => _json({'statusCode': 400, 'message': 'bad value'}, 400),
    );

    await expectLater(
      t.repo.saveMyDuprRating(
        categoryId: 'cat-1',
        matchType: 'SINGLES',
        value: 99,
      ),
      throwsA(isA<DioException>()),
    );
  });
}
