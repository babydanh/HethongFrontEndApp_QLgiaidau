import 'dart:convert';
import 'dart:typed_data';

import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/core/services/token_manager.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_club_match_session_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoTokenManager extends TokenManager {
  @override
  Future<String?> getAccessToken() async => null;
}

class _Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final Object body = options.method == 'POST'
        ? {
            'data': {'id': 'm1', 'status': 'SCHEDULED'},
          }
        : {'data': <Object>[], 'meta': {'hasMore': false}};
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

(ApiClubMatchSessionRepository, _Adapter) _repo() {
  final adapter = _Adapter();
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1'))
    ..httpClientAdapter = adapter;
  return (
    ApiClubMatchSessionRepository(
      DioClient(tokenManager: _NoTokenManager(), dio: dio),
    ),
    adapter,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=https://api.example.test/api/v1');
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('liệt kê theo communityId gửi query communityId', () async {
    final (repo, adapter) = _repo();
    await repo.standaloneMatches('c1');
    expect(adapter.requests.single.queryParameters['communityId'], 'c1');
    expect(
      adapter.requests.single.queryParameters.containsKey('socialSessionId'),
      isFalse,
    );
  });

  test('liệt kê theo socialSessionId gửi query socialSessionId', () async {
    final (repo, adapter) = _repo();
    await repo.standaloneMatches(null, socialSessionId: 's1');
    final q = adapter.requests.single.queryParameters;
    expect(q['socialSessionId'], 's1');
    expect(q.containsKey('communityId'), isFalse);
  });

  test('tạo trận buổi cá nhân gửi socialSessionId, không gửi communityId', () async {
    final (repo, adapter) = _repo();
    await repo.createStandaloneMatch(
      socialSessionId: 's1',
      sideA: ['a1', 'a2'],
      sideB: ['b1', 'b2'],
      key: 'k',
      isRanked: false,
      matchType: 'DOUBLES',
    );
    final body = adapter.requests.single.data as Map;
    expect(body['socialSessionId'], 's1');
    expect(body.containsKey('communityId'), isFalse);
    expect(body['sideAUserIds'], ['a1', 'a2']);
    expect(body['matchType'], 'DOUBLES');
  });

  test('tạo trận theo CLB giữ nguyên: chỉ communityId', () async {
    final (repo, adapter) = _repo();
    await repo.createStandaloneMatch(
      communityId: 'c1',
      sideA: ['a1'],
      sideB: ['b1'],
      key: 'k',
      isRanked: false,
    );
    final body = adapter.requests.single.data as Map;
    expect(body['communityId'], 'c1');
    expect(body.containsKey('socialSessionId'), isFalse);
  });

  test('tạo trận thiếu hoặc đủ cả hai owner đều bị từ chối', () async {
    final (repo, adapter) = _repo();
    expect(
      () => repo.createStandaloneMatch(
        sideA: ['a'],
        sideB: ['b'],
        key: 'k',
        isRanked: false,
      ),
      throwsArgumentError,
    );
    expect(
      () => repo.createStandaloneMatch(
        communityId: 'c',
        socialSessionId: 's',
        sideA: ['a'],
        sideB: ['b'],
        key: 'k',
        isRanked: false,
      ),
      throwsArgumentError,
    );
    expect(adapter.requests, isEmpty);
  });
}
