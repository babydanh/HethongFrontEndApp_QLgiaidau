import 'dart:convert';
import 'dart:typed_data';

import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/core/services/token_manager.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoTokenManager extends TokenManager {
  @override
  Future<String?> getAccessToken() async => null;
}

/// Trả về một response JSON cố định cho mọi request.
class _JsonAdapter implements HttpClientAdapter {
  _JsonAdapter({required this.statusCode, required this.body});

  final int statusCode;
  final Map<String, dynamic> body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}

Dio _dioWith(HttpClientAdapter adapter) =>
    Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = adapter;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final logs = <String>[];
  void Function(String? message, {int? wrapWidth})? previousDebugPrint;

  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=https://api.example.test');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    logs.clear();
    previousDebugPrint = debugPrint;
    // Gom mọi dòng debugPrint của DioClient để kiểm tra nội dung log.
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) logs.add(message);
    };
  });

  tearDown(() {
    debugPrint = previousDebugPrint!;
  });

  group('DioClient HTTP debug log', () {
    test('ghi route và che giá trị query nhạy cảm', () async {
      final client = DioClient(
        tokenManager: _NoTokenManager(),
        dio: _dioWith(_JsonAdapter(statusCode: 200, body: {'status': 'OK', 'data': []})),
      );

      await client.dio.get<dynamic>(
        '/tournaments/42/players',
        queryParameters: {
          'token': 'secret-token-value',
          'email': 'player@example.test',
          'limit': 10,
        },
      );

      final output = logs.join('\n');
      expect(output, contains('[DioClient] [HTTP] start GET /tournaments/:id/players'));
      expect(output, contains('token:<redacted>'));
      expect(output, contains('email:<redacted>'));
      expect(output, contains('limit:10'));
      expect(output, isNot(contains('secret-token-value')));
      expect(output, isNot(contains('player@example.test')));
      expect(output, contains('[DioClient] [HTTP] done GET /tournaments/:id/players status=200'));
    });

    test('giữ giá trị của các query key nằm trong allow-list', () async {
      final client = DioClient(
        tokenManager: _NoTokenManager(),
        dio: _dioWith(_JsonAdapter(statusCode: 200, body: {'status': 'OK', 'data': []})),
      );

      await client.dio.get<dynamic>(
        '/matches',
        queryParameters: {
          'page': 2,
          'limit': 10,
          'status': 'LIVE',
          'sort': 'startAt',
          'order': 'asc',
          'publicOnly': true,
        },
      );

      final output = logs.join('\n');
      expect(output, contains('page:2'));
      expect(output, contains('limit:10'));
      expect(output, contains('status:LIVE'));
      expect(output, contains('sort:startAt'));
      expect(output, contains('order:asc'));
      expect(output, contains('publicOnly:true'));
      expect(output, isNot(contains('<redacted>')));
    });

    test('log request và lỗi 4xx không chứa body, báo đúng status', () async {
      final client = DioClient(
        tokenManager: _NoTokenManager(),
        dio: _dioWith(_JsonAdapter(statusCode: 400, body: {'message': 'bad request'})),
      );

      await expectLater(
        client.dio.post<dynamic>(
          '/payments/payout',
          data: {
            'bankAccountNumber': 'sensitive-account-number',
            'amountRequested': 25000,
          },
        ),
        throwsA(isA<DioException>()),
      );

      final output = logs.join('\n');
      expect(
        output,
        contains('[DioClient] [HTTP] start POST /payments/payout query={} request_bytes='),
      );
      expect(output, contains('[DioClient] [HTTP] error POST /payments/payout status=400'));
      expect(output, contains('type=badResponse'));
      expect(output, isNot(contains('sensitive-account-number')));
    });
  });
}
