import 'dart:convert';
import 'dart:typed_data';

import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/core/services/match_socket_service.dart';
import 'package:app_quanly_giaidau/core/services/token_manager.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_match_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoTokenManager extends TokenManager {
  @override
  Future<String?> getAccessToken() async => null;
}

class _SilentSocketService extends Fake implements MatchSocketService {}

/// Trả một trang `/matches` cố định.
class _PageAdapter implements HttpClientAdapter {
  _PageAdapter(this.matches);

  final List<Map<String, dynamic>> matches;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode({
        'data': matches,
        'meta': {'hasMore': false, 'nextCursor': null},
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ApiMatchRepository _repositoryWith(_PageAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1'))
    ..httpClientAdapter = adapter;
  return ApiMatchRepository(
    DioClient(tokenManager: _NoTokenManager(), dio: dio),
    _SilentSocketService(),
  );
}

Map<String, dynamic> _match({
  required List<Object> members,
  Object? guestNames,
}) => {
  'id': 'match-1',
  'tournamentId': 'tournament-1',
  'status': 'SCHEDULED',
  'roundNumber': 3,
  'matchOrder': 12,
  'participant1Id': 'p-1',
  'participant2Id': 'p-2',
  'participant1': {
    'id': 'p-1',
    'teamName': 'CLB Pickleball Sài Gòn',
    'members': members,
    'guestNames': ?guestNames,
  },
  'participant2': {
    'id': 'p-2',
    'teamName': 'Biên Hòa Pickleball',
    'members': <Object>[],
  },
  'updatedAt': '2026-10-19T09:38:56.232Z',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  dotenv.loadFromString(
    envString: 'API_BASE_URL=https://api.example.test/api/v1',
  );

  test('guest athletes follow the account members, names only', () async {
    final repository = _repositoryWith(
      _PageAdapter([
        _match(
          members: [
            {
              'userId': 'user-a',
              'fullName': 'Hoang Linh',
              'avatarUrl': 'https://example.test/linh.png',
            },
          ],
          guestNames: ['Trần Quốc Bảo', '  '],
        ),
      ]),
    );

    final [match] = await repository.getAllByTournament('tournament-1');

    expect(match.team1MemberInfos.map((m) => m.fullName), [
      'Hoang Linh',
      'Trần Quốc Bảo',
    ]);
    expect(match.team1MemberInfos.last.userId, isNull);
    expect(match.team1MemberInfos.last.avatarUrl, isNull);
    expect(match.team1Members, ['Hoang Linh', 'Trần Quốc Bảo']);
  });

  test('a pair without accounts still has two athletes', () async {
    final repository = _repositoryWith(
      _PageAdapter([
        _match(
          members: const [],
          guestNames: ['Nguyễn Minh Anh', 'Trần Quốc Bảo'],
        ),
      ]),
    );

    final [match] = await repository.getAllByTournament('tournament-1');

    expect(match.team1Members, ['Nguyễn Minh Anh', 'Trần Quốc Bảo']);
    expect(match.team2MemberInfos, isEmpty);
  });

  test('an older payload without guestNames reads as before', () async {
    final repository = _repositoryWith(
      _PageAdapter([_match(members: const [])]),
    );

    final [match] = await repository.getAllByTournament('tournament-1');

    expect(match.team1MemberInfos, isEmpty);
  });
}
