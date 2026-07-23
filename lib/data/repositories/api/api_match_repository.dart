import 'dart:async';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/core/services/match_socket_service.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/data/models/match_event_model.dart';
import 'package:app_quanly_giaidau/data/models/penalty_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_repository.dart';
import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';

Map<String, dynamic>? _readSportRules(Map<String, dynamic> json) {
  Map<String, dynamic>? asMap(Object? value) {
    return value is Map ? Map<String, dynamic>.from(value) : null;
  }

  final effectiveRules = asMap(json['effectiveSportRules']);
  if (effectiveRules != null && effectiveRules.isNotEmpty) {
    return effectiveRules;
  }
  final matchRules = asMap(json['sportRules']);
  if (matchRules != null && matchRules.isNotEmpty) {
    return matchRules;
  }
  final tournament = asMap(json['tournament']);
  return asMap(tournament?['sportRules']);
}

class ApiMatchRepository implements IMatchRepository {
  static const _log = AppLogger('ApiMatchRepo');
  final DioClient _dioClient;
  final MatchSocketService _socketService;

  ApiMatchRepository(this._dioClient, this._socketService);

  @override
  Future<MatchModel> create(String tournamentId, MatchModel match) async {
    throw UnimplementedError('Mobile app cannot create matches directly. Generated via Backend Bracket.');
  }

  @override
  Future<void> createBatch(String tournamentId, List<MatchModel> matches) async {
    throw UnimplementedError('Mobile app cannot batch create matches directly.');
  }

  final Map<String, List<MatchModel>> _matchesCache = {};

  @override
  Stream<List<MatchModel>> watchByTournament(String tournamentId, {String? divisionId}) async* {
    final cacheKey = '$tournamentId-${divisionId ?? 'all'}';
    final initial = await getAllByTournament(tournamentId, divisionId: divisionId);
    if (initial.isNotEmpty) {
      _matchesCache[cacheKey] = initial;
      yield initial;
    } else {
      yield _matchesCache[cacheKey] ?? [];
    }

    yield* Stream.periodic(const Duration(seconds: 10)).asyncMap((_) async {
      final updated = await getAllByTournament(tournamentId, divisionId: divisionId);
      if (updated.isNotEmpty) {
        _matchesCache[cacheKey] = updated;
        return updated;
      }
      return _matchesCache[cacheKey] ?? [];
    });
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

  Future<MatchModel?> _getMatchById(String matchId) async {
    try {
      final response = await _dioClient.dio.get('/matches/$matchId');
      if (response.statusCode == 200) {
        final json = response.data['data'] ?? response.data;
        return _parseMatch(json);
      }
    } catch (_) {}
    return null;
  }

  // ── Status mapping ───────────────────────────────────────────────────────
  static String _mapMatchStatus(String? status) {
    switch (status?.toUpperCase()) {
      case 'ONGOING':
      case 'IN_PROGRESS':
        return 'live';
      case 'COMPLETED':
        return 'completed';
      case 'WALKOVER':
        return 'walkover';
      case 'CANCELLED':
        return 'cancelled';
      default:
        return 'scheduled';
    }
  }

  // ── Bracket branch mapping ────────────────────────────────────────────────
  static String _mapBracketBranch(String? branch) {
    switch (branch?.toUpperCase()) {
      case 'MAIN':
        return 'winners';
      case 'LOSERS':
        return 'losers';
      case 'GRAND_FINALS':
        return 'grand_final';
      default:
        return 'winners';
    }
  }

  static String _buildCourtDisplay({
    String? court,
    String? courtName,
    String? courtAddress,
  }) {
    final name = (courtName ?? court ?? '').toString().trim();
    final address = (courtAddress ?? '').toString().trim();
    if (name.isEmpty) return address;
    if (address.isEmpty) return name;
    if (name.contains(address)) return name;
    return '$name - $address';
  }

  MatchModel _parseMatch(Map<String, dynamic> json) {
    final team1Name = json['participant1']?['teamName'] ?? json['team1Name'] ?? 'TBD';
    final team2Name = json['participant2']?['teamName'] ?? json['team2Name'] ?? 'TBD';
    final rosters1 = json['participant1']?['rosters'] as List<dynamic>?;
    final team1Members = rosters1?.map((r) => r['fullName']?.toString() ?? '').where((n) => n.isNotEmpty).toList() ?? <String>[];
    final rosters2 = json['participant2']?['rosters'] as List<dynamic>?;
    final team2Members = rosters2?.map((r) => r['fullName']?.toString() ?? '').where((n) => n.isNotEmpty).toList() ?? <String>[];

    int parseNum(dynamic val) {
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    // Match web frontend logic (MatchesTab.tsx / MatchCard.tsx):
    // Display p1SetsWon vs p2SetsWon if available, else score1 vs score2
    int score1 = json['p1SetsWon'] != null
        ? parseNum(json['p1SetsWon'])
        : parseNum(json['score1'] ?? json['participant1Score']);

    int score2 = json['p2SetsWon'] != null
        ? parseNum(json['p2SetsWon'])
        : parseNum(json['score2'] ?? json['participant2Score']);

    return MatchModel(
      id: json['id'] ?? '',
      round: json['roundNumber'] ?? 1,
      matchNumber: json['matchOrder'] ?? json['matchNumber'] ?? 1,
      team1Id: json['team1Id'] ?? '',
      team1Name: team1Name,
      team2Id: json['team2Id'] ?? '',
      team2Name: team2Name,
      score1: score1,
      score2: score2,
      status: _mapMatchStatus(json['status'] as String?),
      bracketPosition: json['bracketBranch'] != null
          ? BracketPosition(
              bracket: _mapBracketBranch(json['bracketBranch'] as String?),
              round: json['roundNumber'] ?? 1,
              position: json['matchOrder'] ?? json['matchNumber'] ?? 0,
            )
          : const BracketPosition(round: 1, position: 0),
      nextMatchId: json['nextMatchId'] ?? '',
      loserNextMatchId: json['loserNextMatchId'] ?? '',
      winnerId: json['winnerId'] ?? '',
      isBye: json['isBye'] ?? json['is_bye'] ?? false,
      court: _buildCourtDisplay(
        court: json['court']?.toString(),
        courtName: json['courtName']?.toString(),
        courtAddress: json['courtAddress']?.toString(),
      ),
      courtAddress: json['courtAddress']?.toString() ?? '',
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
      refereeId: json['refereeId']?.toString(),
      refereeName: json['refereeName']?.toString(),
      sportRules: _readSportRules(json),
      scoreDetails: json['scoreDetails'] as Map<String, dynamic>?,
      setsToWin: json['setsToWin'] as int?,
      team1Members: team1Members,
      team2Members: team2Members,
    );
  }

  @override
  Stream<MatchModel?> watchMatch(String tournamentId, String matchId) {
    late StreamController<MatchModel?> controller;
    StreamSubscription? scoreSub;
    StreamSubscription? statusSub;
    MatchModel? latestMatch;

    controller = StreamController<MatchModel?>(
      onListen: () async {
        _log.info('Connecting socket listener for match $matchId');
        _socketService.connect(matchId);

        // Fetch initial state
        final initialMatch = await _getMatchById(matchId);
        latestMatch = initialMatch;
        if (!controller.isClosed) {
          controller.add(initialMatch);
        }

        scoreSub = _socketService.onScoreUpdate.listen((data) {
          if (data['id'] == matchId && !controller.isClosed) {
            _log.info('Score update received for $matchId via socket');
            final newMatch = _parseMatch(data);
            final mergedMatch = newMatch.copyWith(
              team1Name: newMatch.team1Name == 'TBD' && latestMatch != null ? latestMatch!.team1Name : newMatch.team1Name,
              team2Name: newMatch.team2Name == 'TBD' && latestMatch != null ? latestMatch!.team2Name : newMatch.team2Name,
            );
            latestMatch = mergedMatch;
            controller.add(mergedMatch);
          }
        });

        statusSub = _socketService.onMatchStatus.listen((data) {
          if (data['id'] == matchId && !controller.isClosed) {
            _log.info('Status update received for $matchId via socket');
            final newMatch = _parseMatch(data);
            final mergedMatch = newMatch.copyWith(
              team1Name: newMatch.team1Name == 'TBD' && latestMatch != null ? latestMatch!.team1Name : newMatch.team1Name,
              team2Name: newMatch.team2Name == 'TBD' && latestMatch != null ? latestMatch!.team2Name : newMatch.team2Name,
            );
            latestMatch = mergedMatch;
            controller.add(mergedMatch);
          }
        });
      },
      onCancel: () {
        _log.info('Disconnecting socket listener for match $matchId');
        scoreSub?.cancel();
        statusSub?.cancel();
        _socketService.leave(matchId);
        controller.close();
      },
    );

    return controller.stream;
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
  Future<void> updateScoreDetails(
    String tournamentId,
    String matchId, {
    required int p1SetsWon,
    required int p2SetsWon,
    required List<SetScoreData> scoreDetails,
    String? winnerId,
    String? overrideReason,
  }) async {
    _log.info('Updating score details for match $matchId: sets=$p1SetsWon-$p2SetsWon');
    final payload = <String, dynamic>{
      'p1SetsWon': p1SetsWon,
      'p2SetsWon': p2SetsWon,
      'scoreDetails': {
        'sets': scoreDetails.map((s) => s.toJson()).toList(),
      },
    };
    if (winnerId != null) payload['winnerId'] = winnerId;
    if (overrideReason != null) payload['overrideReason'] = overrideReason;

    await _dioClient.dio.patch('/matches/$matchId/score', data: payload);
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
  Future<List<MatchModel>> getAllByTournament(String tournamentId, {String? divisionId}) async {
    _log.debug('Fetching all matches for tournament $tournamentId via API (division: $divisionId)');
    try {
      final queryParameters = <String, dynamic>{
        'tournamentId': tournamentId,
      };
      if (divisionId != null) {
        queryParameters['divisionId'] = divisionId;
      }
      final response = await _dioClient.dio.get('/matches', queryParameters: queryParameters);
      if (response.statusCode == 200) {
        final List<dynamic> list = response.data['data'] ?? response.data ?? [];
        return list.map((json) => _parseMatch(Map<String, dynamic>.from(json))).toList();
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
        return list.map((json) => _parseMatch(Map<String, dynamic>.from(json))).toList();
      }
      return [];
    } catch (e, stack) {
      _log.error('Error fetching global matches from API', e, stack);
      return [];
    }
  }
}
