import 'dart:async';

import 'package:app_quanly_giaidau/core/services/match_socket_service.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_match_repository.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_api_adapter.dart';

/// Socket giả im lặng: chỉ đủ để `watchMatch` đăng ký.
class _QuietSocket extends Fake implements MatchSocketService {
  final _empty = StreamController<Map<String, dynamic>>.broadcast();

  @override
  Future<void> connect(String? matchId, {bool joinMatch = true}) async {}

  @override
  void leave(String matchId) {}

  @override
  void joinTournament(String tournamentId) {}

  @override
  void leaveTournament(String tournamentId) {}

  @override
  Stream<Map<String, dynamic>> get onScoreUpdate => _empty.stream;

  @override
  Stream<Map<String, dynamic>> get onMatchStatus => _empty.stream;

  @override
  Stream<Map<String, dynamic>> get onTournamentMatchUpdate => _empty.stream;

  @override
  Stream<Map<String, dynamic>> get onScoreboardVisibility => _empty.stream;

  @override
  Stream<Map<String, dynamic>> get onOverlayVisibility => _empty.stream;
}

const _tournamentMatch = {
  'id': 'm1',
  'tournamentId': 't1',
  'status': 'ONGOING',
  'roundNumber': 1,
  'matchOrder': 1,
  'participant1Id': 'p1',
  'participant2Id': 'p2',
  'participant1': {'id': 'p1', 'teamName': 'Alpha', 'members': <Object>[]},
  'participant2': {'id': 'p2', 'teamName': 'Beta', 'members': <Object>[]},
  'updatedAt': '2026-10-19T09:38:56.232Z',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  dotenv.loadFromString(
    envString: 'API_BASE_URL=https://api.example.test/api/v1',
  );

  test('TC-LIVEWATCH-01 opened without a tournament id: a tournament match '
      'still loads with its real team names', () async {
    // The club-session endpoint answers 200 with `data: null` for a match
    // that is not a session match. That is "not found", not an empty match.
    final adapter = FakeApiAdapter({
      'GET /club-match-sessions/matches/m1': const FakeReply(200, {
        'statusCode': 200,
        'message': 'ok',
        'data': null,
      }),
      'GET /matches/m1': const FakeReply(200, {
        'statusCode': 200,
        'message': 'ok',
        'data': _tournamentMatch,
      }),
    });
    final repo = ApiMatchRepository(fakeDioClient(adapter), _QuietSocket());

    final match = await repo.watchMatch('', 'm1').first;

    expect(match?.team1Name, 'Alpha');
    expect(match?.team2Name, 'Beta');
  });
}
