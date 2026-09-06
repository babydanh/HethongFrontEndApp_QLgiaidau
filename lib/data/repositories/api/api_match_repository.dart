import 'dart:async';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/core/services/match_socket_service.dart';
import 'package:app_quanly_giaidau/core/utils/date_parser.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/data/models/match_event_model.dart';
import 'package:app_quanly_giaidau/data/models/penalty_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_repository.dart';
import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

Map<String, dynamic>? _readSportRules(Map<String, dynamic> json) {
  Map<String, dynamic>? asMap(Object? value) {
    return value is Map ? Map<String, dynamic>.from(value) : null;
  }

  Map<String, dynamic>? tournamentConfig(Map<String, dynamic>? tournament) {
    return asMap(json['tournamentConfig']) ??
        asMap(tournament?['tournamentConfig']);
  }

  Map<String, dynamic>? carryOpenScoringMarker(
    Map<String, dynamic>? rules,
    Map<String, dynamic>? config,
  ) {
    if (rules == null || config == null) return rules;
    final marker =
        config['scoringMode'] ??
        config['scoring_mode'] ??
        config['rulesPreset'];
    if (marker == null ||
        rules.containsKey('scoringMode') ||
        rules.containsKey('scoring_mode') ||
        rules.containsKey('rulesPreset')) {
      return rules;
    }
    // Match snapshots often carry sportRules and tournamentConfig separately.
    // Preserve the scoring contract in the same map so an older socket/list
    // payload cannot silently resolve an open Quick/Lite match as BO3.
    return {...rules, 'scoringMode': marker};
  }

  final tournament = asMap(json['tournament']);
  final config = tournamentConfig(tournament);
  final effectiveRules = asMap(json['effectiveSportRules']);
  if (effectiveRules != null && effectiveRules.isNotEmpty) {
    return carryOpenScoringMarker(effectiveRules, config);
  }
  final matchRules = asMap(json['sportRules']);
  if (matchRules != null && matchRules.isNotEmpty) {
    return carryOpenScoringMarker(matchRules, config);
  }
  final tournamentRules =
      asMap(tournament?['sportRules']) ??
      asMap(
        tournament?['tournamentConfig'] is Map
            ? (tournament?['tournamentConfig'] as Map)['sportRules']
            : null,
      ) ??
      asMap(
        json['tournamentConfig'] is Map
            ? (json['tournamentConfig'] as Map)['sportRules']
            : null,
      );
  return carryOpenScoringMarker(tournamentRules, config);
}

class ApiMatchRepository implements IMatchRepository {
  static const _log = AppLogger('ApiMatchRepo');
  final DioClient _dioClient;
  final MatchSocketService _socketService;

  ApiMatchRepository(this._dioClient, this._socketService);

  AppLocalizations get _l10n =>
      lookupAppLocalizations(PlatformDispatcher.instance.locale);

  @override
  Future<MatchModel> create(String tournamentId, MatchModel match) async {
    throw UnimplementedError(_l10n.matchCreateUnsupported);
  }

  @override
  Future<void> createBatch(
    String tournamentId,
    List<MatchModel> matches,
  ) async {
    throw UnimplementedError(_l10n.matchBatchCreateUnsupported);
  }

  final Map<String, List<MatchModel>> _matchesCache = {};
  final Map<String, Future<List<MatchModel>>> _inflightTournamentMatches = {};
  Future<List<MatchModel>>? _inflightPublicMatches;
  List<MatchModel>? _publicMatchesCache;
  DateTime? _publicMatchesFetchedAt;

  static const _publicMatchesCacheTtl = Duration(seconds: 10);

  List<dynamic> _extractList(dynamic payload) {
    dynamic value = payload;
    for (var i = 0; i < 3; i++) {
      if (value is List) return value;
      if (value is Map && value['data'] != null) {
        value = value['data'];
      } else {
        break;
      }
    }
    return value is List ? value : const <dynamic>[];
  }

  String? _extractNextCursor(dynamic payload) {
    if (payload is! Map) return null;
    final meta = payload['meta'];
    if (meta is Map) {
      final cursor = meta['nextCursor'];
      return cursor is String && cursor.isNotEmpty ? cursor : null;
    }
    final data = payload['data'];
    return data is Map ? _extractNextCursor(data) : null;
  }

  Future<List<MatchModel>> _getMatchPages(
    Map<String, dynamic> baseQuery,
  ) async {
    const pageSize = 100;
    const maxPages = 50;
    final result = <MatchModel>[];
    String? cursor;
    for (var page = 0; page < maxPages; page++) {
      final query = <String, dynamic>{...baseQuery, 'limit': pageSize};
      if (cursor != null) query['cursor'] = cursor;
      final response = await _dioClient.dio.get(
        '/matches',
        queryParameters: query,
      );
      if (response.statusCode != 200) {
        throw StateError(
          _l10n.matchUnexpectedResponse(response.statusCode.toString()),
        );
      }
      final payload = response.data;
      final list = _extractList(payload);
      result.addAll(
        list.map((json) => _parseMatch(Map<String, dynamic>.from(json))),
      );
      final nextCursor = _extractNextCursor(payload);
      if (nextCursor == null || nextCursor == cursor || list.isEmpty) break;
      cursor = nextCursor;
    }
    return result;
  }

  Future<List<MatchModel>> _getPublicMatchesSnapshot({
    bool forceRefresh = false,
  }) {
    final cached = _publicMatchesCache;
    final fetchedAt = _publicMatchesFetchedAt;
    if (!forceRefresh &&
        cached != null &&
        fetchedAt != null &&
        DateTime.now().difference(fetchedAt) < _publicMatchesCacheTtl) {
      return Future.value(List<MatchModel>.of(cached));
    }
    final inflight = _inflightPublicMatches;
    if (inflight != null) return inflight;

    final request = _getMatchPages(const <String, dynamic>{'publicOnly': true});
    _inflightPublicMatches = request;
    return request
        .then((matches) {
          _publicMatchesCache = List<MatchModel>.of(matches);
          _publicMatchesFetchedAt = DateTime.now();
          return matches;
        })
        .whenComplete(() {
          if (identical(_inflightPublicMatches, request)) {
            _inflightPublicMatches = null;
          }
        });
  }

  @override
  Stream<List<MatchModel>> watchByTournament(
    String tournamentId, {
    String? divisionId,
  }) {
    final cacheKey = '$tournamentId-${divisionId ?? 'all'}';
    late StreamController<List<MatchModel>> controller;
    StreamSubscription? socketSub;
    StreamSubscription? scoreSub;
    StreamSubscription? statusSub;
    Timer? refreshTimer;
    var refreshing = false;

    Future<void> refresh({bool forceRefresh = true}) async {
      if (refreshing) return;
      refreshing = true;
      try {
        final updated = await _fetchAllByTournament(
          tournamentId,
          divisionId: divisionId,
          forceRefresh: forceRefresh,
          usePublicSnapshot: false,
        );
        _matchesCache[cacheKey] = updated;
        if (!controller.isClosed) controller.add(updated);
      } catch (error, stack) {
        _log.error(
          'Keeping cached tournament matches after refresh failure',
          error,
          stack,
        );
        final cached = _matchesCache[cacheKey];
        if (cached == null) {
          if (!controller.isClosed) controller.addError(error, stack);
          return;
        }
        if (!controller.isClosed) controller.add(cached);
      } finally {
        refreshing = false;
      }
    }

    controller = StreamController<List<MatchModel>>(
      onListen: () {
        _socketService.connect(null, joinMatch: false);
        _socketService.joinTournament(tournamentId);
        unawaited(refresh());
        socketSub = _socketService.onTournamentMatchUpdate.listen((_) {
          unawaited(refresh());
        });
        scoreSub = _socketService.onScoreUpdate.listen((_) {
          unawaited(refresh());
        });
        statusSub = _socketService.onMatchStatus.listen((_) {
          unawaited(refresh());
        });
        refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
          _socketService.connect(null, joinMatch: false);
          _socketService.joinTournament(tournamentId);
          unawaited(refresh(forceRefresh: false));
        });
      },
      onCancel: () {
        socketSub?.cancel();
        scoreSub?.cancel();
        statusSub?.cancel();
        refreshTimer?.cancel();
        _socketService.leaveTournament(tournamentId);
      },
    );
    return controller.stream;
  }

  @override
  Stream<List<MatchModel>> watchLive(String tournamentId) {
    late StreamController<List<MatchModel>> controller;
    StreamSubscription? socketSub;
    Timer? refreshTimer;

    Future<void> refresh({bool forceRefresh = true}) async {
      List<MatchModel> currentList;
      try {
        currentList = await _fetchAllByTournament(
          tournamentId,
          forceRefresh: forceRefresh,
          usePublicSnapshot: true,
        );
        _matchesCache['$tournamentId-all'] = currentList;
      } catch (error, stack) {
        _log.error(
          'Keeping cached live matches after refresh failure',
          error,
          stack,
        );
        final cached = _matchesCache['$tournamentId-all'];
        if (cached == null) {
          if (!controller.isClosed) controller.addError(error, stack);
          return;
        }
        currentList = cached;
      }
      if (!controller.isClosed) {
        controller.add(currentList.where((m) => m.isLive).toList());
      }
    }

    StreamSubscription? scoreSub;
    StreamSubscription? statusSub;

    controller = StreamController<List<MatchModel>>(
      onListen: () {
        _socketService.connect(null, joinMatch: false);
        _socketService.joinTournament(tournamentId);
        unawaited(refresh());
        socketSub = _socketService.onTournamentMatchUpdate.listen((_) {
          unawaited(refresh());
        });
        scoreSub = _socketService.onScoreUpdate.listen((_) {
          unawaited(refresh());
        });
        statusSub = _socketService.onMatchStatus.listen((_) {
          unawaited(refresh());
        });
        refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
          _socketService.connect(null, joinMatch: false);
          _socketService.joinTournament(tournamentId);
          unawaited(refresh(forceRefresh: false));
        });
      },
      onCancel: () {
        socketSub?.cancel();
        scoreSub?.cancel();
        statusSub?.cancel();
        refreshTimer?.cancel();
        _socketService.leaveTournament(tournamentId);
      },
    );
    return controller.stream;
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
      case 'STARTED':
      case 'PLAYING':
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
    String? tournamentVenueName,
  }) {
    final namedCourt = (courtName ?? '').trim();
    if (namedCourt.isNotEmpty) return namedCourt;

    final courtValue = (court ?? '').trim();
    if (courtValue.isNotEmpty) return courtValue;

    return (tournamentVenueName ?? '').trim();
  }

  static String? _readTournamentVenueName(Map<String, dynamic> json) {
    final tournament = json['tournament'];
    if (tournament is! Map) return null;

    final venue = tournament['venue'];
    final value =
        tournament['venueName'] ?? (venue is Map ? venue['name'] : null);
    final name = value?.toString().trim() ?? '';
    return name.isEmpty ? null : name;
  }

  MatchModel _parseMatch(Map<String, dynamic> json) {
    String participantName(dynamic participant) {
      if (participant is! Map) return '';
      final value =
          participant['teamName'] ??
          participant['name'] ??
          participant['displayName'];
      return value?.toString().trim() ?? '';
    }

    final p1Name = participantName(json['participant1']);
    final p2Name = participantName(json['participant2']);
    final team1Name = p1Name.isNotEmpty
        ? p1Name
        : (json['team1Name'] ??
                      json['participant1Name'] ??
                      (json['team1'] is Map
                          ? (json['team1'] as Map)['name']
                          : null))
                  ?.toString() ??
              'TBD';
    final team2Name = p2Name.isNotEmpty
        ? p2Name
        : (json['team2Name'] ??
                      json['participant2Name'] ??
                      (json['team2'] is Map
                          ? (json['team2'] as Map)['name']
                          : null))
                  ?.toString() ??
              'TBD';
    final rosters1 = json['participant1']?['rosters'] as List<dynamic>?;
    final team1Members =
        rosters1
            ?.map((r) => r['fullName']?.toString() ?? '')
            .where((n) => n.isNotEmpty)
            .toList() ??
        <String>[];
    final rosters2 = json['participant2']?['rosters'] as List<dynamic>?;
    final team2Members =
        rosters2
            ?.map((r) => r['fullName']?.toString() ?? '')
            .where((n) => n.isNotEmpty)
            .toList() ??
        <String>[];

    int parseNum(dynamic val) {
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    int score1 = parseNum(json['score1'] ?? json['participant1Score']);
    int score2 = parseNum(json['score2'] ?? json['participant2Score']);
    final parsedSets = <SetScore>[];

    // Check scoreDetails.sets for point scores of the set
    if (json['scoreDetails'] != null) {
      try {
        final details = json['scoreDetails'];
        if (details is Map && details['sets'] is List) {
          final sets = details['sets'] as List;
          for (final rawSet in sets) {
            if (rawSet is! Map) continue;
            parsedSets.add(
              SetScore(
                score1: parseNum(
                  rawSet['team1Score'] ?? rawSet['score1'] ?? rawSet['p1'],
                ),
                score2: parseNum(
                  rawSet['team2Score'] ?? rawSet['score2'] ?? rawSet['p2'],
                ),
              ),
            );
          }
          if (sets.isNotEmpty) {
            final lastSet = sets.last;
            if (score1 == 0 && score2 == 0 && lastSet is Map) {
              score1 = parseNum(
                lastSet['score1'] ?? lastSet['p1'] ?? lastSet['team1Score'],
              );
              score2 = parseNum(
                lastSet['score2'] ?? lastSet['p2'] ?? lastSet['team2Score'],
              );
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

    final rawGroup =
        json['groupName'] ??
        json['group_name'] ??
        (json['group'] is Map ? json['group']['name'] : json['group']);
    final groupName = rawGroup?.toString();

    final rawStage =
        json['stageName'] ??
        json['stage_name'] ??
        (json['stage'] is Map
            ? (json['stage']['name'] ??
                  json['stage']['stageName'] ??
                  json['stage']['type'])
            : json['stage']) ??
        (json['group'] is Map && json['group']['stage'] is Map
            ? json['group']['stage']['name']
            : null) ??
        json['stageType'];
    final stageName = rawStage is Map
        ? (rawStage['name'] ?? rawStage['stageName'] ?? rawStage['type'])
              ?.toString()
        : rawStage?.toString();

    final nextMatchId = (json['nextMatchId'] ?? '').toString();
    final loserNextMatchId = (json['loserNextMatchId'] ?? '').toString();
    final hasBracketChain =
        nextMatchId.isNotEmpty || loserNextMatchId.isNotEmpty;

    final rawStageType =
        json['stageType'] ??
        json['stage_type'] ??
        (json['stage'] is Map ? json['stage']['type'] : null) ??
        (json['group'] is Map && json['group']['stage'] is Map
            ? json['group']['stage']['type']
            : null);
    final stageType = rawStageType?.toString();

    String bracketName = 'winners';
    if (json['bracketBranch'] != null) {
      bracketName = _mapBracketBranch(json['bracketBranch'] as String?);
    } else if (hasBracketChain) {
      bracketName = 'winners';
    } else if (stageType != null &&
        (stageType.toUpperCase() == 'ROUND_ROBIN' ||
            stageType.toUpperCase() == 'GROUP_STAGE')) {
      bracketName = 'group_stage';
    } else if ((stageName != null &&
            stageName.toUpperCase().contains('GROUP')) ||
        (json['stage']?.toString().toUpperCase() == 'GROUP_STAGE')) {
      bracketName = 'group_stage';
    } else if (groupName != null &&
        groupName.isNotEmpty &&
        !groupName.toUpperCase().contains('KNOCKOUT') &&
        !groupName.toUpperCase().contains('PLAYOFF') &&
        !groupName.toUpperCase().contains('BRACKET') &&
        !groupName.toUpperCase().contains('MAIN') &&
        !groupName.toUpperCase().contains('WINNER') &&
        !groupName.toUpperCase().contains('LOSER')) {
      bracketName = 'group_stage';
    }

    return MatchModel(
      id: json['id'] ?? '',
      tournamentId:
          json['tournamentId']?.toString() ??
          json['tournament_id']?.toString() ??
          (json['tournament'] is Map
              ? (json['tournament'] as Map)['id']?.toString()
              : null),
      round: json['roundNumber'] ?? json['round'] ?? 1,
      leg: json['leg'] is num
          ? (json['leg'] as num).toInt()
          : int.tryParse(json['leg']?.toString() ?? ''),
      matchNumber: json['matchOrder'] ?? json['matchNumber'] ?? 1,

      team1Id:
          json['team1Id']?.toString() ??
          json['participant1Id']?.toString() ??
          (json['participant1'] is Map
              ? json['participant1']['id']?.toString()
              : null) ??
          '',
      team1Name: team1Name,
      team2Id:
          json['team2Id']?.toString() ??
          json['participant2Id']?.toString() ??
          (json['participant2'] is Map
              ? json['participant2']['id']?.toString()
              : null) ??
          '',
      team2Name: team2Name,
      score1: score1,
      score2: score2,
      sets: parsedSets,
      status: _mapMatchStatus(json['status'] as String?),
      bracketPosition: BracketPosition(
        bracket: bracketName,
        round: json['roundNumber'] ?? json['round'] ?? 1,
        position: json['matchOrder'] ?? json['matchNumber'] ?? 0,
      ),
      nextMatchId: json['nextMatchId'] ?? '',
      loserNextMatchId: json['loserNextMatchId'] ?? '',
      winnerId: json['winnerId'] ?? '',
      loserId: json['loserId'] ?? '',
      isBye: json['isBye'] ?? json['is_bye'] ?? false,
      court: _buildCourtDisplay(
        court: json['court']?.toString(),
        courtName: json['courtName']?.toString(),
        tournamentVenueName: _readTournamentVenueName(json),
      ),

      courtAddress: json['courtAddress']?.toString() ?? '',
      scheduledTime: DateParser.parseDateOptional(
        json['scheduledTime'] ?? json['scheduled_at'],
      ),
      startedAt: DateParser.parseDateOptional(
        json['startedAt'] ?? json['started_at'],
      ),
      completedAt: DateParser.parseDateOptional(
        json['completedAt'] ?? json['completed_at'],
      ),
      updatedAt:
          DateParser.parseDateOptional(
            json['updatedAt'] ?? json['updated_at'],
          ) ??
          DateTime.now(),
      revision: json['revision'] as int?,
      refereeId: json['refereeId']?.toString(),
      refereeName: json['refereeName']?.toString(),
      sportRules: _readSportRules(json),
      tournamentConfig: json['tournamentConfig'] is Map
          ? Map<String, dynamic>.from(json['tournamentConfig'] as Map)
          : json['tournament'] is Map &&
                (json['tournament'] as Map)['tournamentConfig'] is Map
          ? Map<String, dynamic>.from(
              (json['tournament'] as Map)['tournamentConfig'] as Map,
            )
          : null,
      scoreDetails: json['scoreDetails'] is Map
          ? Map<String, dynamic>.from(json['scoreDetails'] as Map)
          : null,
      sportKey:
          json['sport']?.toString() ??
          json['sportKey']?.toString() ??
          (json['tournament'] is Map
              ? (json['tournament'] as Map)['sport']?.toString()
              : null),
      setsToWin: json['setsToWin'] as int?,
      team1Members: team1Members,
      team2Members: team2Members,
      groupName: groupName,
      stageName: stageName,
      stageType: stageType,
      divisionId:
          json['divisionId']?.toString() ??
          json['division_id']?.toString() ??
          (json['stage'] is Map
              ? (json['stage']['divisionId'] ?? json['stage']['division_id'])
                    ?.toString()
              : null) ??
          (json['group'] is Map
              ? (json['group']['divisionId'] ?? json['group']['division_id'])
                    ?.toString()
              : null) ??
          (json['scoreDetails'] is Map
              ? (json['scoreDetails']['division_id'] ??
                        json['scoreDetails']['divisionId'])
                    ?.toString()
              : null) ??
          (json['tournamentConfig'] is Map
              ? (json['tournamentConfig']['division_id'] ??
                        json['tournamentConfig']['divisionId'])
                    ?.toString()
              : null),
    );
  }

  @override
  Stream<MatchModel?> watchMatch(String tournamentId, String matchId) {
    late StreamController<MatchModel?> controller;
    StreamSubscription? scoreSub;
    StreamSubscription? statusSub;
    StreamSubscription? tournamentUpdateSub;
    Timer? reconciliationTimer;
    MatchModel? latestMatch;

    controller = StreamController<MatchModel?>(
      onListen: () async {
        _log.info('Connecting socket listener for match $matchId');
        _socketService.connect(matchId);

        // Fetch initial state
        // Do not let the Dio retry chain leave the live screen spinning for
        // tens of seconds. Socket/reconciliation can still recover the
        // current match after this bounded initial snapshot.
        final initialMatch = await _getMatchById(
          matchId,
        ).timeout(const Duration(seconds: 8), onTimeout: () => null);
        latestMatch = initialMatch;
        if (!controller.isClosed) {
          controller.add(initialMatch);
        }

        scoreSub = _socketService.onScoreUpdate.listen((data) {
          if (data['id'] == matchId && !controller.isClosed) {
            _log.info('Score update received for $matchId via socket');
            final newMatch = _parseMatch(data);
            final mergedMatch = _mergeMatchUpdate(newMatch, latestMatch, data);
            latestMatch = mergedMatch;
            controller.add(mergedMatch);
          }
        });

        statusSub = _socketService.onMatchStatus.listen((data) {
          if (data['id'] == matchId && !controller.isClosed) {
            _log.info('Status update received for $matchId via socket');
            final newMatch = _parseMatch(data);
            final mergedMatch = _mergeMatchUpdate(newMatch, latestMatch, data);
            latestMatch = mergedMatch;
            controller.add(mergedMatch);
          }
        });

        tournamentUpdateSub = _socketService.onTournamentMatchUpdate.listen((
          data,
        ) {
          if (data['id'] == matchId && !controller.isClosed) {
            final newMatch = _parseMatch(data);
            final mergedMatch = _mergeMatchUpdate(newMatch, latestMatch, data);
            latestMatch = mergedMatch;
            controller.add(mergedMatch);
          }
        });

        // Socket is the fast path; reconcile periodically so a dropped event or
        // a proxy that temporarily falls back to polling cannot leave stale score.
        reconciliationTimer = Timer.periodic(const Duration(seconds: 12), (
          _,
        ) async {
          final refreshed = await _getMatchById(matchId);
          if (refreshed != null && !controller.isClosed) {
            latestMatch = refreshed;
            controller.add(refreshed);
          }
        });
      },
      onCancel: () {
        _log.info('Disconnecting socket listener for match $matchId');
        scoreSub?.cancel();
        statusSub?.cancel();
        tournamentUpdateSub?.cancel();
        reconciliationTimer?.cancel();
        _socketService.leave(matchId);
        _socketService.leaveTournament(tournamentId);
        controller.close();
      },
    );

    return controller.stream;
  }

  MatchModel _mergeMatchUpdate(
    MatchModel incoming,
    MatchModel? previous,
    Map<String, dynamic> payload,
  ) {
    if (previous == null) return incoming;
    final hasScorePayload =
        payload.containsKey('scoreDetails') ||
        payload.containsKey('p1SetsWon') ||
        payload.containsKey('p2SetsWon') ||
        payload.containsKey('score1') ||
        payload.containsKey('score2') ||
        payload.containsKey('participant1Score') ||
        payload.containsKey('participant2Score');
    return incoming.copyWith(
      team1Id: incoming.team1Id.isEmpty ? previous.team1Id : incoming.team1Id,
      team2Id: incoming.team2Id.isEmpty ? previous.team2Id : incoming.team2Id,
      team1Name: incoming.team1Name == 'TBD'
          ? previous.team1Name
          : incoming.team1Name,
      team2Name: incoming.team2Name == 'TBD'
          ? previous.team2Name
          : incoming.team2Name,
      tournamentName: incoming.tournamentName ?? previous.tournamentName,
      sportKey: incoming.sportKey ?? previous.sportKey,
      sportRules: incoming.sportRules ?? previous.sportRules,
      tournamentConfig: incoming.tournamentConfig ?? previous.tournamentConfig,
      scoreDetails: hasScorePayload
          ? incoming.scoreDetails
          : previous.scoreDetails,
      score1: hasScorePayload ? incoming.score1 : previous.score1,
      score2: hasScorePayload ? incoming.score2 : previous.score2,
      sets: hasScorePayload ? incoming.sets : previous.sets,
      setsToWin: incoming.setsToWin ?? previous.setsToWin,
      maxScore: incoming.maxScore ?? previous.maxScore,
      timeLimitMinutes: incoming.timeLimitMinutes ?? previous.timeLimitMinutes,
      refereeName: incoming.refereeName ?? previous.refereeName,
      refereeId: incoming.refereeId ?? previous.refereeId,
      startedAt: incoming.startedAt ?? previous.startedAt,
      // Phải lấy revision MỚI từ payload echo. Nếu bỏ sót, local cứ giữ
      // revision cũ → mỗi lần nhập tiếp gửi expectedRevision sai → backend
      // trả 409 → điểm bị drop + màn "kẹt"/desync mãi. (fix #33)
      revision: incoming.revision ?? previous.revision,
      divisionId: incoming.divisionId ?? previous.divisionId,
    );
  }

  @override
  Future<void> updateSchedule(
    String tournamentId,
    String matchId, {
    String? courtName,
    String? courtAddress,
    String? refereeId,
    DateTime? scheduledAt,
  }) async {
    await _dioClient.dio.patch(
      '/matches/$matchId/schedule',
      data: {
        'courtName': courtName,
        'courtAddress': courtAddress,
        'refereeId': refereeId,
        'scheduledAt': scheduledAt?.toUtc().toIso8601String(),
      },
    );
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
        maxScore != null ||
        winByTwo != null ||
        timeLimitMinutes != null ||
        refereeName != null;

    // Status-only (không có score flat) → PATCH /matches/:id/status
    if (hasStatus && !hasScore) {
      final backendStatus = _normalizeStatusToBackend(status);
      _log.info(
        'Status update for $matchId via /status: $status -> $backendStatus',
      );
      await _dioClient.dio.patch(
        '/matches/$matchId/status',
        data: {'status': backendStatus},
      );
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
    _log.warning(
      'updateLiveState chỉ gồm events/penalties — không có endpoint backend, bỏ qua',
    );
  }

  @override
  Future<void> startMatch(
    String tournamentId,
    String matchId, {
    int? maxScore,
    int? timeLimitMinutes,
    String? refereeName,
    bool useLiteParticipantAccess = false,
  }) async {
    _log.info('Starting match $matchId via API');
    await _dioClient.dio.patch(
      useLiteParticipantAccess
          ? '/matches/$matchId/lite-status'
          : '/matches/$matchId/status',
      data: {'status': 'ONGOING'},
    );
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
    Map<String, dynamic>? scoreDetailsExtras,
    String? winnerId,
    String? overrideReason,
    int? expectedRevision,
    bool useLiteParticipantAccess = false,
  }) async {
    _log.info(
      'Updating score details for match $matchId: sets=$p1SetsWon-$p2SetsWon',
    );
    final payload = <String, dynamic>{
      'p1SetsWon': p1SetsWon,
      'p2SetsWon': p2SetsWon,
      'scoreDetails': {
        ...?scoreDetailsExtras,
        'sets': scoreDetails.map((s) => s.toJson()).toList(),
      },
    };
    if (winnerId != null) payload['winnerId'] = winnerId;
    if (overrideReason != null) payload['overrideReason'] = overrideReason;
    if (expectedRevision != null) {
      payload['expectedRevision'] = expectedRevision;
    }

    try {
      await _dioClient.dio.patch(
        useLiteParticipantAccess
            ? '/matches/$matchId/lite-score'
            : '/matches/$matchId/score',
        data: payload,
      );
    } on DioException catch (error) {
      final body = error.response?.data;
      final rawMessage = body is Map ? body['message'] : null;
      final message = rawMessage is List
          ? rawMessage
                .whereType<Object>()
                .map((item) => item.toString())
                .join('\n')
          : rawMessage?.toString();
      throw Exception(
        message?.trim().isNotEmpty == true
            ? message
            : _l10n.matchScoreUpdateError,
      );
    }
  }

  @override
  Future<void> advanceWinner(
    String tournamentId,
    String nextMatchId, {
    required String winnerId,
    required String winnerName,
    required bool isTeam1,
  }) async {
    throw UnimplementedError(
      'Handled automatically by backend completion workflow.',
    );
  }

  @override
  Future<List<MatchModel>> getAllByTournament(
    String tournamentId, {
    String? divisionId,
  }) async {
    _log.debug(
      'Fetching all matches for tournament $tournamentId via API (division: $divisionId)',
    );
    final cacheKey = '$tournamentId-${divisionId ?? 'all'}';
    final inflight = _inflightTournamentMatches[cacheKey];
    if (inflight != null) return inflight;

    final request = _fetchAllByTournament(tournamentId, divisionId: divisionId);
    _inflightTournamentMatches[cacheKey] = request;
    try {
      return await request;
    } catch (e, stack) {
      _log.error('Error fetching matches from API', e, stack);
      rethrow;
    } finally {
      if (identical(_inflightTournamentMatches[cacheKey], request)) {
        _inflightTournamentMatches.remove(cacheKey);
      }
    }
  }

  Future<List<MatchModel>> _fetchAllByTournament(
    String tournamentId, {
    String? divisionId,
    bool forceRefresh = false,
    bool usePublicSnapshot = false,
  }) async {
    // Home opens one stream per tournament. Reuse a short-lived public cursor
    // snapshot there instead of issuing one request per tournament. Division
    // views keep their scoped query because the MatchModel intentionally does
    // not infer division membership from display data.
    if (divisionId == null && usePublicSnapshot) {
      final snapshot = await _getPublicMatchesSnapshot(
        forceRefresh: forceRefresh,
      );
      final matches = snapshot
          .where((match) => match.tournamentId == tournamentId)
          .toList(growable: false);
      _matchesCache['$tournamentId-all'] = matches;
      return matches;
    }
    final queryParameters = <String, dynamic>{
      'tournamentId': tournamentId,
      'publicOnly': true,
    };
    if (divisionId != null) queryParameters['divisionId'] = divisionId;
    // The backend caps cursor pages at 100; _getMatchPages follows nextCursor
    // until the complete tournament feed is loaded.
    final matches = await _getMatchPages(queryParameters);
    _matchesCache['$tournamentId-${divisionId ?? 'all'}'] = matches;
    return matches;
  }

  @override
  Future<void> deleteAll(String tournamentId) async {
    throw UnimplementedError('Mobile app cannot delete matches.');
  }

  @override
  Future<List<MatchModel>> getMatches({
    String? status,
    bool? publicOnly,
  }) async {
    _log.debug(
      'Fetching matches globally with status: $status, publicOnly: $publicOnly',
    );
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;
      if (publicOnly != null) queryParams['publicOnly'] = publicOnly;
      return await _getMatchPages(queryParams);
    } catch (e, stack) {
      _log.error('Error fetching global matches from API', e, stack);
      rethrow;
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
      final response = await _dioClient.dio.get(
        '/matches/$matchId/cheer-count',
      );
      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        if (data is int) return data;
        if (data is Map) {
          return (data['count'] ?? data['cheerCount'] ?? 0) as int;
        }
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
    final payload = <String, dynamic>{'action': action, 'reason': reason};
    if (winnerId != null) payload['winnerId'] = winnerId;

    await _dioClient.dio.patch('/matches/$matchId/operation', data: payload);
  }

  @override
  Future<
    ({List<MatchModel> matches, String? nextCursor, bool hasMore, int total})
  >
  getTournamentMatchesPaged({
    required String tournamentId,
    String? status,
    String? cursor,
    int limit = 4,
  }) async {
    final query = <String, dynamic>{
      'tournamentId': tournamentId,
      'limit': limit,
    };
    if (status != null && status.isNotEmpty) {
      query['status'] = status.toUpperCase();
    }
    if (cursor != null && cursor.isNotEmpty) {
      query['cursor'] = cursor;
    }
    final response = await _dioClient.dio.get(
      '/matches',
      queryParameters: query,
    );
    final payload = response.data;
    final list = _extractList(payload);
    final matches = list
        .whereType<Map>()
        .map((json) => _parseMatch(Map<String, dynamic>.from(json)))
        .toList();
    final nextCursor = _extractNextCursor(payload);
    final meta = payload is Map && payload['meta'] is Map
        ? Map<String, dynamic>.from(payload['meta'] as Map)
        : null;
    final hasMore =
        meta?['hasMore'] == true ||
        (nextCursor != null && nextCursor.isNotEmpty);
    final total = meta?['total'] is num
        ? (meta!['total'] as num).toInt()
        : (meta?['totalCount'] is num
              ? (meta!['totalCount'] as num).toInt()
              : matches.length);
    return (
      matches: matches,
      nextCursor: nextCursor,
      hasMore: hasMore,
      total: total,
    );
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
