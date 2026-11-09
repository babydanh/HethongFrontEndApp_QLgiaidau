import 'dart:convert';
import 'dart:typed_data';

import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/core/services/token_manager.dart';
import 'package:app_quanly_giaidau/data/models/social_session_model.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_social_session_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoTokenManager extends TokenManager {
  _NoTokenManager() : super(secureStorage: null);
  @override
  Future<String?> getAccessToken() async => null;
}

/// Records every request and answers with a fixed JSON body.
class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this.body, {this.statusCode = 200});

  final Map<String, dynamic> body;
  final int statusCode;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ApiSocialSessionRepository _repoWith(_RecordingAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
    ..httpClientAdapter = adapter;
  return ApiSocialSessionRepository(
    DioClient(tokenManager: _NoTokenManager(), dio: dio),
  );
}

// Shape returned by GET /social-sessions/:id/messages (oldest -> newest).
const _backendMessage = {
  'id': 'm1',
  'senderId': 'u-host',
  'senderName': 'Nguyễn Văn A',
  'senderAvatarUrl': 'https://img.example.test/a.png',
  'messageText': 'Chiều nay 5h nha',
  'createdAt': '2026-11-10T09:30:00.000Z',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=https://api.example.test');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('TC-SOCIAL-CHAT-01 model reads messageText, senderId and avatar', () {
    final msg = SocialChatMessageModel.fromJson(
      Map<String, dynamic>.from(_backendMessage),
    );

    expect(msg.message, 'Chiều nay 5h nha');
    expect(msg.senderId, 'u-host');
    expect(msg.senderAvatar, 'https://img.example.test/a.png');
    expect(msg.senderName, 'Nguyễn Văn A');
  });

  test(
    'TC-SOCIAL-CHAT-02 getMessages sends limit only (no page) and parses data',
    () async {
      final adapter = _RecordingAdapter({
        'data': [_backendMessage],
        'meta': {'limit': 30, 'hasMore': false, 'nextCursor': null},
      });

      final messages = await _repoWith(adapter).getMessages('s1');

      final request = adapter.requests.single;
      expect(request.method, 'GET');
      expect(request.path, '/social-sessions/s1/messages');
      expect(request.queryParameters.containsKey('page'), isFalse);
      expect(request.queryParameters['limit'], 30);
      expect(messages.single.message, 'Chiều nay 5h nha');
    },
  );

  test('TC-SOCIAL-CHAT-03 sendMessage posts trimmed messageText', () async {
    final adapter = _RecordingAdapter({'data': _backendMessage});

    await _repoWith(adapter).sendMessage('s1', '  xin chào  ');

    final request = adapter.requests.single;
    expect(request.method, 'POST');
    expect(request.path, '/social-sessions/s1/messages');
    expect(request.data, {'messageText': 'xin chào'});
  });

  test('TC-SOCIAL-CHAT-03b sendMessage throws on a 4xx answer', () async {
    final adapter = _RecordingAdapter({
      'message': 'Kèo đã đóng',
    }, statusCode: 403);

    await expectLater(
      _repoWith(adapter).sendMessage('s1', 'hi'),
      throwsA(isA<SocialApiException>()),
    );
  });
}
