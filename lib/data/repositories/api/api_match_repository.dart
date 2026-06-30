import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/data/models/match_event_model.dart';
import 'package:app_quanly_giaidau/data/models/penalty_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_repository.dart';

class ApiMatchRepository implements IMatchRepository {
  static const _log = AppLogger('ApiMatchRepo');
  final DioClient _dioClient;

  ApiMatchRepository(this._dioClient);

  @override
  Future<MatchModel> create(String tournamentId, MatchModel match) async {
    throw UnimplementedError('Mobile app cannot create matches directly. Generated via Backend Bracket.');
  }

  @override
  Future<void> createBatch(String tournamentId, List<MatchModel> matches) async {
    throw UnimplementedError('Mobile app cannot batch create matches directly.');
  }

  @override
  Stream<List<MatchModel>> watchByTournament(String tournamentId) async* {
    yield await getAllByTournament(tournamentId);
    yield* Stream.periodic(const Duration(seconds: 10))
        .asyncMap((_) => getAllByTournament(tournamentId));
  }

  @override
  Stream<List<MatchModel>> watchLive(String tournamentId) async* {
    final list = await getAllByTournament(tournamentId);
    yield list.where((m) => m.status == 'live' || m.status == 'ONGOING').toList();
    yield* Stream.periodic(const Duration(seconds: 8))
        .asyncMap((_) async {
          final currentList = await getAllByTournament(tournamentId);
          return currentList.where((m) => m.status == 'live' || m.status == 'ONGOING').toList();
        });
  }

  @override
  Stream<MatchModel?> watchMatch(String tournamentId, String matchId) async* {
    final list = await getAllByTournament(tournamentId);
    yield list.where((m) => m.id == matchId).firstOrNull;
    yield* Stream.periodic(const Duration(seconds: 5))
        .asyncMap((_) async {
          final currentList = await getAllByTournament(tournamentId);
          return currentList.where((m) => m.id == matchId).firstOrNull;
        });
  }

  @override
  Future<void> updateScore(
    String tournamentId,
    String matchId, {
    required int score1,
    required int score2,
  }) async {
    _log.info('Updating match score via API: $matchId → $score1-$score2');
    await _dioClient.dio.patch('/matches/$matchId/score', data: {
      'score1': score1,
      'score2': score2,
      'isCompleted': false,
    });
  }

  @override
  Future<void> updateLiveState(
    String tournamentId,
    String matchId, {
    int? score1,
    int? score2,
    List<MatchEvent>? events,
    String? status,
    int? maxScore,
    bool? winByTwo,
    int? timeLimitMinutes,
    String? refereeName,
    List<Penalty>? penalties,
  }) async {
    _log.info('Updating match live state: $matchId');
    final payload = <String, dynamic>{};
    if (score1 != null) payload['score1'] = score1;
    if (score2 != null) payload['score2'] = score2;
    if (status != null) payload['status'] = status;

    await _dioClient.dio.patch('/matches/$matchId/score', data: payload);
  }

  @override
  Future<void> startMatch(
    String tournamentId,
    String matchId, {
    int? maxScore,
    int? timeLimitMinutes,
    String? refereeName,
  }) async {
    _log.info('Starting match $matchId via API');
    await _dioClient.dio.patch('/matches/$matchId/status', data: {
      'status': 'ONGOING',
    });
  }

  @override
  Future<void> completeMatch(
    String tournamentId,
    String matchId, {
    required String winnerId,
    required String loserId,
    required int finalScore1,
    required int finalScore2,
  }) async {
    _log.info('Completing match $matchId via API: winner=$winnerId');
    await _dioClient.dio.patch('/matches/$matchId/score', data: {
      'score1': finalScore1,
      'score2': finalScore2,
      'isCompleted': true,
      'winnerId': winnerId,
    });
  }

  @override
  Future<void> updateSets(
    String tournamentId,
    String matchId,
    List<SetScore> sets,
  ) async {
    _log.info('Updating sets for match $matchId via API');
    final setDetails = sets.map((s) => {
      'score1': s.score1,
      'score2': s.score2,
    }).toList();

    await _dioClient.dio.patch('/matches/$matchId/score', data: {
      'setDetails': setDetails,
    });
  }

  @override
  Future<void> advanceWinner(
    String tournamentId,
    String nextMatchId, {
    required String winnerId,
    required String winnerName,
    required bool isTeam1,
  }) async {
    throw UnimplementedError('Handled automatically by backend completion workflow.');
  }

  @override
  Future<void> walkover(
    String tournamentId,
    String matchId, {
    required String winnerId,
    required String loserId,
  }) async {
    _log.info('Applying walkover to match $matchId via API');
    await _dioClient.dio.patch('/matches/$matchId/status', data: {
      'status': 'WALKOVER',
      'winnerId': winnerId,
    });
  }

  @override
  Future<List<MatchModel>> getAllByTournament(String tournamentId) async {
    _log.debug('Fetching all matches for tournament $tournamentId via API');
    try {
      final response = await _dioClient.dio.get('/matches', queryParameters: {
        'tournamentId': tournamentId,
      });
      if (response.statusCode == 200) {
        final List<dynamic> list = response.data['data'] ?? response.data ?? [];
        return list.map((json) {
          final String id = json['id'] ?? '';
          final team1Name = json['participant1']?['teamName'] ?? json['team1Name'] ?? 'TBD';
          final team2Name = json['participant2']?['teamName'] ?? json['team2Name'] ?? 'TBD';
          
          return MatchModel(
            id: id,
            round: json['roundNumber'] ?? 1,
            matchNumber: json['matchNumber'] ?? 1,
            team1Id: json['team1Id'] ?? '',
            team1Name: team1Name,
            team2Id: json['team2Id'] ?? '',
            team2Name: team2Name,
            score1: json['score1'] ?? 0,
            score2: json['score2'] ?? 0,
            status: json['status'] == 'ONGOING' ? 'live' : (json['status'] == 'COMPLETED' ? 'completed' : 'scheduled'),
            bracketPosition: const BracketPosition(round: 1, position: 0),
            nextMatchId: json['nextMatchId'] ?? '',
            winnerId: json['winnerId'] ?? '',
            court: json['court'] ?? '',
            updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
            // Sport rules từ tournament setting
            sportRules: json['tournament'] is Map
                ? (json['tournament'] as Map)['sportRules'] as Map<String, dynamic>?
                : null,
            setsToWin: json['setsToWin'] as int?,
          );
        }).toList();
      }
      return [];
    } catch (e, stack) {
      _log.error('Error fetching matches from API', e, stack);
      return [];
    }
  }

  @override
  Future<void> deleteAll(String tournamentId) async {
    throw UnimplementedError('Mobile app cannot delete matches.');
  }

  @override
  Future<List<MatchModel>> getMatches({String? status, bool? publicOnly}) async {
    _log.debug('Fetching matches globally with status: $status, publicOnly: $publicOnly');
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;
      if (publicOnly != null) queryParams['publicOnly'] = publicOnly;
      final response = await _dioClient.dio.get('/matches', queryParameters: queryParams);
      if (response.statusCode == 200) {
        final List<dynamic> list = response.data['data'] ?? response.data ?? [];
        return list.map((json) {
          final String id = json['id'] ?? '';
          final team1Name = json['participant1']?['teamName'] ?? json['team1Name'] ?? 'TBD';
          final team2Name = json['participant2']?['teamName'] ?? json['team2Name'] ?? 'TBD';
          
          return MatchModel(
            id: id,
            round: json['roundNumber'] ?? 1,
            matchNumber: json['matchNumber'] ?? 1,
            team1Id: json['team1Id'] ?? '',
            team1Name: team1Name,
            team2Id: json['team2Id'] ?? '',
            team2Name: team2Name,
            score1: json['score1'] ?? 0,
            score2: json['score2'] ?? 0,
            status: json['status'] == 'ONGOING' ? 'live' : (json['status'] == 'COMPLETED' ? 'completed' : 'scheduled'),
            bracketPosition: const BracketPosition(round: 1, position: 0),
            nextMatchId: json['nextMatchId'] ?? '',
            winnerId: json['winnerId'] ?? '',
            court: json['court'] ?? '',
            updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
            // Sport rules từ tournament setting
            sportRules: json['tournament'] is Map
                ? (json['tournament'] as Map)['sportRules'] as Map<String, dynamic>?
                : null,
            setsToWin: json['setsToWin'] as int?,
          );
        }).toList();
      }
      return [];
    } catch (e, stack) {
      _log.error('Error fetching global matches from API', e, stack);
      return [];
    }
  }
}
