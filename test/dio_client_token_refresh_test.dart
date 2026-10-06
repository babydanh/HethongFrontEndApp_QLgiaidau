import 'dart:convert';
import 'dart:typed_data';

import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/core/services/token_manager.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeTokenManager extends TokenManager {
  _FakeTokenManager() : refreshToken = 'refresh-old';

  String? refreshToken;
  String? accessToken;
  bool cleared = false;
  int saves = 0;

  @override
  Future<String?> getRefreshToken() async => refreshToken;

  @override
  Future<String?> getAccessToken() async => accessToken;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    String? role,
  }) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
    saves += 1;
  }

  @override
  Future<void> clearTokens() async {
    accessToken = null;
    refreshToken = null;
    cleared = true;
  }
}

/// Trả lần lượt các kịch bản đã dựng sẵn. Mỗi phần tử là `DioException` (để
/// mô phỏng lỗi mạng) hoặc `Map` (response 200).
class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this.steps);

  final List<Object> steps;
  final List<String> urls = [];
  int _calls = 0;

  int get calls => _calls;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    urls.add('${options.method} ${options.path}');
    final step = steps[_calls < steps.length ? _calls : steps.length - 1];
    _calls += 1;
    if (step is DioException) throw step;
    return ResponseBody.fromString(
      jsonEncode(step),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

DioException _connectionTimeout() => DioException(
  requestOptions: RequestOptions(path: '/auth/mobile/refresh'),
  type: DioExceptionType.connectionTimeout,
  error: 'mạng chết lúc mở kết nối',
);

const _tokens = {
  'data': {'accessToken': 'access-new', 'refreshToken': 'refresh-new'},
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=https://api.example.test');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Dio buildClient({
    required TokenManager tokens,
    required HttpClientAdapter adapter,
    required HttpClientAdapter refreshAdapter,
  }) {
    return DioClient(
      tokenManager: tokens,
      dio: Dio(BaseOptions(baseUrl: 'https://api.example.test'))
        ..httpClientAdapter = adapter,
      refreshDio: Dio(BaseOptions(baseUrl: 'https://api.example.test'))
        ..httpClientAdapter = refreshAdapter,
    ).dio;
  }

  group('refresh token với lỗi mạng tạm thời', () {
    test('refresh timeout lần đầu vẫn ghi được, không mất phiên', () async {
      final tokens = _FakeTokenManager();
      // PATCH lần 1 -> 401, PATCH sau refresh -> 200.
      final api = _ScriptedAdapter([
        DioException(
          requestOptions: RequestOptions(path: '/social-sessions/abc'),
          response: Response(
            requestOptions: RequestOptions(path: '/social-sessions/abc'),
            statusCode: 401,
          ),
          type: DioExceptionType.badResponse,
        ),
        {
          'data': {'id': 'abc', 'title': 'đã lưu'},
        },
      ]);
      // Refresh lần 1 hết giờ, lần 2 thành công.
      final refresh = _ScriptedAdapter([_connectionTimeout(), _tokens]);
      final dio = buildClient(
        tokens: tokens,
        adapter: api,
        refreshAdapter: refresh,
      );

      final response = await dio.patch<dynamic>('/social-sessions/abc');

      expect(response.statusCode, 200);
      expect((response.data as Map)['data'], containsPair('title', 'đã lưu'));
      expect(refresh.calls, 2, reason: 'phải thử lại refresh khi timeout');
      expect(api.calls, 2, reason: 'phải phát lại request gốc với token mới');
      expect(tokens.saves, 1);
      expect(tokens.cleared, isFalse, reason: 'lỗi mạng không được xoá token');
    });

    test(
      'refresh lỗi mạng thì lỗi báo ra là lỗi mạng, không phải hết phiên',
      () async {
        final tokens = _FakeTokenManager();
        final api = _ScriptedAdapter([
          DioException(
            requestOptions: RequestOptions(path: '/social-sessions/abc'),
            response: Response(
              requestOptions: RequestOptions(path: '/social-sessions/abc'),
              statusCode: 401,
            ),
            type: DioExceptionType.badResponse,
          ),
        ]);
        final refresh = _ScriptedAdapter([_connectionTimeout()]);
        final dio = buildClient(
          tokens: tokens,
          adapter: api,
          refreshAdapter: refresh,
        );

        Object? thrown;
        try {
          await dio.patch<dynamic>('/social-sessions/abc');
        } catch (error) {
          thrown = error;
        }

        final exception = thrown as DioException?;
        expect(exception, isNotNull);
        expect(
          exception!.type,
          DioExceptionType.connectionTimeout,
          reason: 'phải báo lỗi mạng để UI không tưởng là hết phiên đăng nhập',
        );
        expect(tokens.cleared, isFalse);
      },
    );
  });

  group('refresh token với token bị từ chối', () {
    test('refresh trả 401 thì xoá token, request gốc fail với 401', () async {
      final tokens = _FakeTokenManager();
      final api = _ScriptedAdapter([
        DioException(
          requestOptions: RequestOptions(path: '/social-sessions/abc'),
          response: Response(
            requestOptions: RequestOptions(path: '/social-sessions/abc'),
            statusCode: 401,
          ),
          type: DioExceptionType.badResponse,
        ),
      ]);
      final refresh = _ScriptedAdapter([
        DioException(
          requestOptions: RequestOptions(path: '/auth/mobile/refresh'),
          response: Response(
            requestOptions: RequestOptions(path: '/auth/mobile/refresh'),
            statusCode: 401,
          ),
          type: DioExceptionType.badResponse,
        ),
      ]);
      final dio = buildClient(
        tokens: tokens,
        adapter: api,
        refreshAdapter: refresh,
      );

      Object? thrown;
      try {
        await dio.patch<dynamic>('/social-sessions/abc');
      } catch (error) {
        thrown = error;
      }

      expect((thrown as DioException).response?.statusCode, 401);
      expect(
        tokens.cleared,
        isTrue,
        reason: 'refresh bị từ chối thì phải xoá token',
      );
    });
  });
}
