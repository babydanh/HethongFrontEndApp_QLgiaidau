import 'dart:convert';
import 'dart:typed_data';

import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/core/services/token_manager.dart';
import 'package:app_quanly_giaidau/data/models/social_bracket_model.dart';
import 'package:app_quanly_giaidau/data/models/social_session_model.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_social_session_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoTokenManager extends TokenManager {
  @override
  Future<String?> getAccessToken() async => null;
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this.status, this.body);

  final int status;
  final Map<String, dynamic> body;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
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

(ApiSocialSessionRepository, _Adapter) _repo(
  int status,
  Map<String, dynamic> body,
) {
  final adapter = _Adapter(status, body);
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1'))
    ..httpClientAdapter = adapter;
  return (
    ApiSocialSessionRepository(
      DioClient(tokenManager: _NoTokenManager(), dio: dio),
    ),
    adapter,
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

  test('TC-SOCIAL-BRACKET-APP-01: tạo bracket POST đúng route + body, đọc data', () async {
    final (repo, adapter) = _repo(201, {
      'data': {
        'tournamentId': 't1',
        'bracketType': 'SINGLE_ELIMINATION',
        'matchType': 'DOUBLES',
        'participantCount': 4,
      },
    });

    final result = await repo.createBracket(
      's1',
      bracketType: 'SINGLE_ELIMINATION',
      matchType: 'DOUBLES',
      participantUserIds: ['u1', 'u2', 'u3', 'u4'],
    );

    final request = adapter.requests.single;
    expect(request.method, 'POST');
    expect(request.path, '/social-sessions/s1/bracket');
    expect(request.data, {
      'bracketType': 'SINGLE_ELIMINATION',
      'matchType': 'DOUBLES',
      'participantUserIds': ['u1', 'u2', 'u3', 'u4'],
    });
    expect(request.extra['noRetry'], isTrue);
    expect(result.tournamentId, 't1');
    expect(result.participantCount, 4);
  });

  test('TC-SOCIAL-BRACKET-APP-02: 409 SOCIAL_BRACKET_EXISTS kèm tournamentId -> exception riêng', () async {
    final (repo, _) = _repo(409, {
      'statusCode': 409,
      'code': 'SOCIAL_BRACKET_EXISTS',
      'message': 'Lỗi hệ thống',
      'tournamentId': 'old-1',
    });

    await expectLater(
      repo.createBracket(
        's1',
        bracketType: 'ROUND_ROBIN',
        matchType: 'SINGLES',
        participantUserIds: ['u1', 'u2'],
      ),
      throwsA(
        isA<SocialBracketExistsException>().having(
          (e) => e.tournamentId,
          'tournamentId',
          'old-1',
        ),
      ),
    );
  });

  test('TC-SOCIAL-BRACKET-APP-03: lỗi 400 khác giữ nguyên code để form chọn câu hiển thị', () async {
    final (repo, _) = _repo(400, {
      'statusCode': 400,
      'code': 'BRACKET_PARTICIPANTS_INVALID',
      'message': 'Lỗi hệ thống',
    });

    await expectLater(
      repo.createBracket(
        's1',
        bracketType: 'ROUND_ROBIN',
        matchType: 'SINGLES',
        participantUserIds: ['u1'],
      ),
      throwsA(
        isA<SocialApiException>()
            .having((e) => e.statusCode, 'statusCode', 400)
            .having((e) => e.code, 'code', 'BRACKET_PARTICIPANTS_INVALID'),
      ),
    );
  });

  test('TC-SOCIAL-BRACKET-APP-04: SocialSessionModel đọc bracketTournamentId (có và null)', () {
    Map<String, dynamic> json(Object? bracketId) => {
      'id': 's1',
      'hostUserId': 'h1',
      'title': 'Kèo',
      'playFormat': 'DOUBLES',
      'startAt': '2026-11-10T10:00:00.000Z',
      'bracketTournamentId': bracketId,
    };

    expect(SocialSessionModel.fromJson(json('t9')).bracketTournamentId, 't9');
    expect(SocialSessionModel.fromJson(json(null)).bracketTournamentId, isNull);
    expect(
      SocialSessionModel.fromJson({...json(null)}..remove('bracketTournamentId'))
          .bracketTournamentId,
      isNull,
    );
  });
}
