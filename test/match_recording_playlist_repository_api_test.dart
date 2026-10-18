import 'dart:convert';
import 'dart:typed_data';

import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/core/services/token_manager.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_match_recording_catalog_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _matchId = '550e8400-e29b-41d4-a716-446655440001';

class _NoTokenManager extends TokenManager {
  @override
  Future<String?> getAccessToken() async => null;
}

class _PlaylistAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (options.path != '/livestream/matches/$_matchId/recordings/playlist' ||
        options.queryParameters['period'] != '2026-10-09') {
      return ResponseBody.fromString(
        jsonEncode(<String, Object?>{'message': 'not found'}),
        404,
        headers: <String, List<String>>{
          Headers.contentTypeHeader: <String>[Headers.jsonContentType],
        },
      );
    }

    final data = <String, Object?>{
      'segments': <Object?>[
        <String, Object?>{
          'name': 'part-02.mp4',
          'startAt': '2026-10-09T10:20:00Z',
          'url': 'https://media.example.test/part-02.mp4',
        },
        <String, Object?>{
          'name': 'part-01.mp4',
          'startAt': '2026-10-09T10:00:00Z',
          'url': 'https://media.example.test/part-01.mp4',
        },
        // Tên có `..`: phải bị loại.
        <String, Object?>{
          'name': '../escape.mp4',
          'url': 'https://media.example.test/escape.mp4',
        },
        // URL http (không https): phải bị loại.
        <String, Object?>{
          'name': 'plain-http.mp4',
          'url': 'http://media.example.test/plain-http.mp4',
        },
        // Thiếu URL: phải bị loại.
        <String, Object?>{'name': 'no-url.mp4'},
      ],
    };
    return ResponseBody.fromString(
      jsonEncode(<String, Object?>{'data': data}),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.loadFromString(
      envString: 'API_BASE_URL=https://api.example.test/api/v1',
    );
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'playlist chỉ giữ đoạn an toàn và giữ đúng thứ tự server trả về',
    () async {
      final adapter = _PlaylistAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1'))
        ..httpClientAdapter = adapter;
      final repository = ApiMatchRecordingCatalogRepository(
        DioClient(tokenManager: _NoTokenManager(), dio: dio),
      );

      final playlist = await repository.getPlaylist(
        _matchId,
        period: '2026-10-09',
      );

      expect(playlist.period, '2026-10-09');
      expect(playlist.segments.map((segment) => segment.name), <String>[
        'part-02.mp4',
        'part-01.mp4',
      ]);
      expect(
        playlist.segments.first.url,
        Uri.parse('https://media.example.test/part-02.mp4'),
      );
      expect(
        playlist.segments.first.startAt,
        DateTime.parse('2026-10-09T10:20:00Z'),
      );
      expect(adapter.requests.single.queryParameters, <String, Object?>{
        'period': '2026-10-09',
      });
    },
  );
}
