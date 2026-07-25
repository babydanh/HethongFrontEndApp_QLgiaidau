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
      case 'LIVE':
        return 'live';
      case 'COMPLETED':
      case 'FINISHED':
      case 'DONE':
      case 'ENDED':
        return 'completed';
      case 'WALKOVER':
        return 'walkover';
      case 'CANCELLED':
        return 'cancelled';
      default:
        return 'scheduled';
    }
  }

  /// Chuẩn hóa status UI (live/completed/scheduled) sang backend enum
  /// (ONGOING/COMPLETED/SCHEDULED) cho PATCH /matches/:id/status.
  static String _normalizeStatusToBackend(String status) {
    switch (status.toUpperCase()) {
      case 'LIVE':
      case 'IN_PROGRESS':
      case 'ONGOING':
        return 'ONGOING';
      case 'COMPLETED':
      case 'FINISHED':
      case 'DONE':
      case 'ENDED':
        return 'COMPLETED';
      case 'SCHEDULED':
      case 'PENDING':
        return 'SCHEDULED';
      default:
        return status.toUpperCase();
    }
  }

  // ── Bracket branch mapping ────────────────────────────────────────────────
  static String _mapBracketBranch(String? branch) {
    switch (branch?.toUpperCase()) {
      case 'MAIN':
      case 'WINNERS':
        return 'winners';
      case 'LOSERS':
        return 'losers';
      case 'GRAND_FINALS':
        return 'grand_final';
      case 'PLAYOFF':
        return 'playoff';
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

    int score1 = parseNum(json['score1'] ?? json['participant1Score']);
    int score2 = parseNum(json['score2'] ?? json['participant2Score']);

    // Check scoreDetails.sets for point scores of the set
    if (score1 == 0 && score2 == 0 && json['scoreDetails'] != null) {
      try {
        final details = json['scoreDetails'];
        if (details is Map && details['sets'] is List) {
          final sets = details['sets'] as List;
          if (sets.isNotEmpty) {
            final lastSet = sets.last;
            if (lastSet is Map) {
              score1 = parseNum(lastSet['score1'] ?? lastSet['p1'] ?? lastSet['team1Score']);
              score2 = parseNum(lastSet['score2'] ?? lastSet['p2'] ?? lastSet['team2Score']);
            }
          }
        }
      } catch (_) {}
    }

    // Only fallback to set count if point scores are 0-0
    if (score1 == 0 && score2 == 0) {
      score1 = parseNum(json['p1SetsWon']);
      score2 = parseNum(json['p2SetsWon']);
    }

    final rawGroup = json['groupName'] ??
        json['group_name'] ??
        (json['group'] is Map ? json['group']['name'] : json['group']);
    final groupName = rawGroup?.toString();

    final rawStage = json['stageName'] ??
        json['stage_name'] ??
        json['stage'] ??
        json['stageType'];
    final stageName = rawStage?.toString();

    final nextMatchId = (json['nextMatchId'] ?? '').toString();
    final loserNextMatchId = (json['loserNextMatchId'] ?? '').toString();
    final hasBracketChain = nextMatchId.isNotEmpty || loserNextMatchId.isNotEmpty;

    String bracketName = 'winners';
    if (json['bracketBranch'] != null) {
      bracketName = _mapBracketBranch(json['bracketBranch'] as String?);
    } else if (hasBracketChain) {
      bracketName = 'winners';
    } else if ((stageName != null && stageName.toUpperCase().contains('GROUP')) ||
        (json['stage']?.toString().toUpperCase() == 'GROUP_STAGE')) {
      bracketName = 'group_stage';
    } else if (groupName != null &&
        groupName.isNotEmpty &&
        !groupName.toUpperCase().contains('KNOCKOUT') &&
        !groupName.toUpperCase().contains('PLAYOFF')) {
      bracketName = 'group_stage';
    }

    return MatchModel(
      id: json['id'] ?? '',
      round: json['roundNumber'] ?? json['round'] ?? 1,
      matchNumber: json['matchOrder'] ?? json['matchNumber'] ?? 1,
      team1Id: json['team1Id'] ?? '',
      team1Name: team1Name,
      team2Id: json['team2Id'] ?? '',
      team2Name: team2Name,
      score1: score1,
      score2: score2,
      status: _mapMatchStatus(json['status'] as String?),
      bracketPosition: BracketPosition(
        bracket: bracketName,
        round: json['roundNumber'] ?? json['round'] ?? 1,
        position: json['matchOrder'] ?? json['matchNumber'] ?? 0,
      ),
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
      groupName: groupName,
      stageName: stageName,
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

    final hasScore = score1 != null || score2 != null;
    final hasStatus = status != null;
    final hasConfig =
        maxScore != null || winByTwo != null || timeLimitMinutes != null || refereeName != null;

    // Status-only (không có score flat) → PATCH /matches/:id/status
    if (hasStatus && !hasScore) {
      final backendStatus = _normalizeStatusToBackend(status);
      _log.info('Status update for $matchId via /status: $status -> $backendStatus');
      await _dioClient.dio.patch('/matches/$matchId/status', data: {
        'status': backendStatus,
      });
      return;
    }

    // Score có mặt nhưng không có set data → backend /score không chấp nhận
    if (hasScore) {
      _log.warning(
        'updateLiveState gửi score1/score2 (flat) không được backend PATCH /matches/:id/score hỗ trợ. '
        'Sử dụng updateScoreDetails() với p1SetsWon/p2SetsWon/scoreDetails.',
      );
      throw UnsupportedError(
        'Flat score1/score2 không được backend PATCH /matches/:id/score hỗ trợ. '
        'Sử dụng updateScoreDetails() với p1SetsWon/p2SetsWon/scoreDetails.',
      );
    }

    // Config-only params (maxScore/winByTwo/timeLimitMinutes/refereeName) — không có endpoint backend
    if (hasConfig) {
      _log.warning(
        'updateLiveState config-only params không có endpoint backend phù hợp. '
        'Các tham số maxScore/winByTwo/timeLimitMinutes/refereeName không thể cập nhật sau khi trận đấu bắt đầu.',
      );
      throw UnsupportedError(
        'Backend không hỗ trợ cập nhật cấu hình trận đấu (maxScore/winByTwo/timeLimitMinutes/refereeName) sau khi bắt đầu. '
        'Thiết lập các tham số này qua startMatch().',
      );
    }

    // Events/penalties only — không có endpoint
    _log.warning('updateLiveState chỉ gồm events/penalties — không có endpoint backend, bỏ qua');
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
    _log.warning(
      'completeMatch không được backend /score hỗ trợ — cần p1SetsWon/p2SetsWon/scoreDetails. '
      'Sử dụng updateScoreDetails() hoặc completeMatchWithDetails() thay thế.',
    );
    throw UnsupportedError(
      'Backend PATCH /matches/:id/score yêu cầu p1SetsWon/p2SetsWon/scoreDetails. '
      'Sử dụng updateScoreDetails() thay vì completeMatch().',
    );
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

  // ── Cheer ──────────────────────────────────────────────────────────────────

  @override
  Future<void> cheerMatch(String matchId) async {
    _log.info('Sending cheer for match $matchId');
    await _dioClient.dio.post('/matches/$matchId/cheer');
  }

  @override
  Future<int> getCheerCount(String matchId) async {
    try {
      final response = await _dioClient.dio.get('/matches/$matchId/cheer-count');
      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        if (data is int) return data;
        if (data is Map) return (data['count'] ?? data['cheerCount'] ?? 0) as int;
      }
    } catch (e) {
      _log.error('Error fetching cheer count for match $matchId', e);
    }
    return 0;
  }

  // ── Match Operation ─────────────────────────────────────────────────────────

  @override
  Future<void> matchOperation(
    String matchId, {
    required String action,
    required String reason,
    String? winnerId,
  }) async {
    _log.info('Match operation: $action for match $matchId');
    final payload = <String, dynamic>{
      'action': action,
      'reason': reason,
    };
    if (winnerId != null) payload['winnerId'] = winnerId;

    await _dioClient.dio.patch('/matches/$matchId/operation', data: payload);
  }

  @override
  Future<void> walkover(
    String tournamentId,
    String matchId, {
    required String winnerId,
    required String loserId,
  }) async {
    _log.info('Applying walkover to match $matchId via operation endpoint');
    await matchOperation(
      matchId,
      action: 'WALKOVER',
      reason: 'Đội đối thủ bỏ cuộc',
      winnerId: winnerId,
    );
  }
}
