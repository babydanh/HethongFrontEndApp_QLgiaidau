import 'dart:convert';
import 'dart:typed_data';

import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/core/services/token_manager.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_team_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoTokenManager extends TokenManager {
  @override
  Future<String?> getAccessToken() async => null;
}

/// Trả participants cho `/participants`, danh sách rỗng cho mọi route khác.
class _ParticipantsAdapter implements HttpClientAdapter {
  _ParticipantsAdapter(this.participants);

  final List<Map<String, dynamic>> participants;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final body = options.path.endsWith('/participants')
        ? {'data': participants}
        : {'data': <Object>[]};
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

ApiTeamRepository _repositoryWith(List<Map<String, dynamic>> participants) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1'))
    ..httpClientAdapter = _ParticipantsAdapter(participants);
  return ApiTeamRepository(DioClient(tokenManager: _NoTokenManager(), dio: dio));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  dotenv.loadFromString(
    envString: 'API_BASE_URL=https://api.example.test/api/v1',
  );

  test('guest athletes become members without a profile link', () async {
    final teams = await _repositoryWith([
      {
        'id': 'p-import',
        'teamName': 'Hà Nội Pickleball Team',
        'teamStatus': 'COMPLETE',
        'registeredBy': {'id': 'organizer-1', 'fullName': 'BTC'},
        'members': <Object>[],
        'guestNames': ['Lê Hoàng Nam', 'Phạm Đức Huy'],
      },
    ]).getAllByTournament('tournament-1');

    final team = teams.single;
    expect(team.name, 'Hà Nội Pickleball Team');
    expect(team.members, ['Lê Hoàng Nam', 'Phạm Đức Huy']);
    expect(team.memberInfos.map((info) => info.fullName), [
      'Lê Hoàng Nam',
      'Phạm Đức Huy',
    ]);
    expect(team.memberInfos.every((info) => info.userId == null), isTrue);
  });

  test('a guest follows the roster member of a half-linked pair', () async {
    final teams = await _repositoryWith([
      {
        'id': 'p-half',
        'teamName': 'Đà Nẵng Pickleball Club',
        'teamStatus': 'COMPLETE',
        'members': [
          {'userId': 'user-khanh', 'fullName': 'Đặng Gia Khánh'},
        ],
        'guestNames': ['Võ Thành Đạt'],
      },
    ]).getAllByTournament('tournament-1');

    expect(teams.single.members, ['Đặng Gia Khánh', 'Võ Thành Đạt']);
    expect(teams.single.memberInfos.first.userId, 'user-khanh');
  });

  test('an older backend without guestNames keeps the team name only', () async {
    final teams = await _repositoryWith([
      {
        'id': 'p-old',
        'teamName': 'CLB Pickleball Cần Thơ',
        'teamStatus': 'COMPLETE',
        'members': <Object>[],
      },
    ]).getAllByTournament('tournament-1');

    expect(teams.single.name, 'CLB Pickleball Cần Thơ');
    expect(teams.single.members, isEmpty);
  });
}
