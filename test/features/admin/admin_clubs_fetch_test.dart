import 'dart:convert';
import 'dart:typed_data';

import 'package:app_quanly_giaidau/features/admin/screens/admin_clubs_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Giả lập Backend: limit > 50 trả 400, có phân trang bằng cursor.
class _PagedBackend implements HttpClientAdapter {
  final List<Map<String, dynamic>> queries = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final query = Map<String, dynamic>.from(options.queryParameters);
    queries.add(query);
    final limit = query['limit'] as int;
    final Map<String, dynamic> body;
    final int status;
    if (limit > 50) {
      status = 400;
      body = {'message': 'limit must not be greater than 50'};
    } else {
      status = 200;
      final second = query['cursor'] == 'p2';
      body = {
        'data': [
          {'id': second ? 'c2' : 'c1', 'name': second ? 'B' : 'A'},
        ],
        'meta': {if (!second) 'nextCursor': 'p2'},
      };
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test(
    'admin club list pages with limit <= 50 and follows the cursor',
    () async {
      final backend = _PagedBackend();
      final dio = Dio(BaseOptions(baseUrl: 'https://x.test'))
        ..httpClientAdapter = backend;

      final clubs = await fetchAllAdminClubs(dio);

      expect(clubs.map((c) => c.id), ['c1', 'c2']);
      expect(backend.queries.every((q) => (q['limit'] as int) <= 50), isTrue);
      expect(backend.queries.length, 2);
    },
  );
}
