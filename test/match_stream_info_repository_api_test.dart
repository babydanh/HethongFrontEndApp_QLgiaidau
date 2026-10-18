import 'dart:convert';
import 'dart:typed_data';

import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/core/services/token_manager.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_match_playback_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _matchId = '550e8400-e29b-41d4-a716-446655440001';

class _NoTokenManager extends TokenManager {
  @override
  Future<String?> getAccessToken() async => null;
}

class _StreamInfoAdapter implements HttpClientAdapter {
  _StreamInfoAdapter(this._data);

  /// Giá trị đặt trong `data` của phản hồi; null nghĩa là thiếu `data`.
  final Map<String, Object?>? _data;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path != '/livestream/matches/$_matchId/stream-info') {
      return ResponseBody.fromString(
        jsonEncode(<String, Object?>{'message': 'not found'}),
        404,
        headers: <String, List<String>>{
          Headers.contentTypeHeader: <String>[Headers.jsonContentType],
        },
      );
    }
    final body = _data == null
        ? <String, Object?>{'message': 'no data'}
        : <String, Object?>{'data': _data};
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ApiMatchPlaybackRepository _repository(_StreamInfoAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1'))
    ..httpClientAdapter = adapter;
  return ApiMatchPlaybackRepository(
    DioClient(tokenManager: _NoTokenManager(), dio: dio),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.loadFromString(
      envString: 'API_BASE_URL=https://api.example.test/api/v1',
    );
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('stream-info đọc đúng thông tin video và FPS', () async {
    final repository = _repository(
      _StreamInfoAdapter(<String, Object?>{
        'matchId': _matchId,
        'available': true,
        'video': <String, Object?>{
          'codec': 'h264',
          'width': 1920,
          'height': 1080,
          'fps': 29.97,
        },
      }),
    );

    final info = await repository.getMatchStreamInfo(_matchId);

    expect(info.matchId, _matchId);
    expect(info.available, isTrue);
    expect(info.video?.codec, 'h264');
    expect(info.video?.width, 1920);
    expect(info.video?.height, 1080);
    expect(info.fps, 29.97);
  });

  test('AQP không có luồng: available false, FPS là null', () async {
    final repository = _repository(
      _StreamInfoAdapter(<String, Object?>{
        'matchId': _matchId,
        'available': false,
        'video': null,
      }),
    );

    final info = await repository.getMatchStreamInfo(_matchId);

    expect(info.available, isFalse);
    expect(info.video, isNull);
    expect(info.fps, isNull);
  });

  test('phản hồi thiếu data bị báo là không hợp lệ', () async {
    final repository = _repository(_StreamInfoAdapter(null));

    await expectLater(
      repository.getMatchStreamInfo(_matchId),
      throwsA(isA<FormatException>()),
    );
  });
}
