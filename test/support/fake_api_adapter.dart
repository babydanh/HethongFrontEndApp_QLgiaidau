import 'dart:convert';
import 'dart:typed_data';

import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/core/services/token_manager.dart';
import 'package:dio/dio.dart';

class NoTokenManager extends TokenManager {
  @override
  Future<String?> getAccessToken() async => null;
}

class FakeReply {
  const FakeReply(this.statusCode, this.body);

  final int statusCode;
  final Object body;
}

class FakeRequest {
  const FakeRequest(this.method, this.path, this.body);

  final String method;
  final String path;
  final Map<String, dynamic>? body;
}

/// Trả lời theo khoá "METHOD /path". Route chưa mock trả 404 và vẫn được ghi lại.
class FakeApiAdapter implements HttpClientAdapter {
  FakeApiAdapter(this.routes);

  final Map<String, FakeReply> routes;
  final List<FakeRequest> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final data = options.data;
    requests.add(
      FakeRequest(
        options.method,
        options.path,
        data is Map ? Map<String, dynamic>.from(data) : null,
      ),
    );
    final reply =
        routes['${options.method} ${options.path}'] ??
        const FakeReply(404, {'message': 'not mocked'});
    return ResponseBody.fromString(
      jsonEncode(reply.body),
      reply.statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}

  Iterable<FakeRequest> postsTo(String path) =>
      requests.where((r) => r.method == 'POST' && r.path == path);
}

/// DioClient thật (interceptor và parse như production), chỉ thay adapter mạng.
DioClient fakeDioClient(FakeApiAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1'))
    ..httpClientAdapter = adapter;
  return DioClient(tokenManager: NoTokenManager(), dio: dio);
}
