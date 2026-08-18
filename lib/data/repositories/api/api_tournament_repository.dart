import 'dart:async';

import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/core/services/match_socket_service.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/data/models/tournament_model.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_repository.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_workspace.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_registration.dart';
import 'package:dio/dio.dart';

class ApiTournamentRepository implements ITournamentRepository {
  static const _log = AppLogger('ApiTournamentRepo');
  final DioClient _dioClient;
  final MatchSocketService? _matchSocketService;
  final Map<String, Tournament> _tournamentCache = {};

  ApiTournamentRepository(this._dioClient, [this._matchSocketService]);

  @override
  Future<Tournament> create(Tournament tournament) async {
    _log.info('Creating tournament via API: ${tournament.name}');
    final categoryId = await _resolveCategoryId(tournament.sport);
    final matchType = _resolveMatchType(
      format: tournament.format,
      category: tournament.category,
    );
    final genderRestriction = _resolveGenderRestriction(tournament.category);
    final payload = <String, dynamic>{
      'name': tournament.name,
      'categoryId': categoryId,
      'tournamentType': 'PUBLIC',
      'visibility': tournament.visibility.isNotEmpty ? tournament.visibility : 'PUBLIC',
      'matchType': matchType,
      'description': tournament.description,
      'entryFee': 0,
      'maxParticipants': tournament.maxTeams,
      'isRanked': false,
      'sportRules': _buildSportRules(tournament.sport),
      'tournamentConfig': {
        'bracketType': _normalizeBracketType(tournament.bracketType),
        'maxTeams': tournament.maxTeams,
        'roundRobinLegs': tournament.roundCount,
      },
    };
    if (genderRestriction != null) {
      payload['genderRestriction'] = genderRestriction;
    }
    final response = await _dioClient.dio.post('/tournaments', data: payload);
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data['data'];
      return Tournament.fromJson(data, data['id']);
    }
    throw Exception('Failed to create tournament via API');
  }

  Future<String> _resolveCategoryId(String sportSlug) async {
    final response = await _dioClient.dio.get('/categories');
    final raw = response.data;
    final data = raw is Map<String, dynamic>
        ? (raw['data'] as List<dynamic>? ?? const [])
        : (raw as List<dynamic>? ?? const []);

    for (final item in data) {
      if (item is! Map<String, dynamic>) continue;
      final slug = (item['slug'] ?? '').toString().toLowerCase();
      if (slug == sportSlug.toLowerCase()) {
        if (item['isActive'] != true && item['is_active'] != true) continue;
        final id = (item['id'] ?? '').toString();
        if (id.isNotEmpty) {
          return id;
        }
      }
    }

    throw Exception('Không tìm thấy bộ môn "${sportSlug.isEmpty ? 'không xác định' : sportSlug}" trên hệ thống');
  }

  String _resolveMatchType({
    required String format,
    required String? category,
  }) {
    if (category == AppConstants.categoryMixedDoubles) {
      return 'MIXED_DOUBLES';
    }
    if (format.toLowerCase() == AppConstants.formatDoubles) {
      return 'DOUBLES';
    }
    return 'SINGLES';
  }

  String? _resolveGenderRestriction(String? category) {
    switch (category) {
      case AppConstants.categoryMenSingles:
      case AppConstants.categoryMenDoubles:
        return 'MALE';
      case AppConstants.categoryWomenSingles:
      case AppConstants.categoryWomenDoubles:
        return 'FEMALE';
      case AppConstants.categoryMixedDoubles:
        return 'MIXED';
      default:
        return null;
    }
  }

  Map<String, dynamic> _buildSportRules(String sport) {
    switch (sport) {
      case AppConstants.sportTennis:
        return {
          'kind': 'TENNIS',
          'setsToWin': 2,
          'pointsPerSet': 6,
          'mustWinByTwo': true,
          'tiebreakPoints': 7,
        };
      case AppConstants.sportPickleball:
        return {
          'kind': 'PICKLEBALL',
          'setsToWin': 2,
          'pointsPerSet': 11,
          'mustWinByTwo': true,
        };
      case AppConstants.sportTableTennis:
        return {
          'kind': 'TABLE_TENNIS',
          'setsToWin': 3,
          'pointsPerSet': 11,
          'mustWinByTwo': true,
        };
      case AppConstants.sportBadminton:
        return {
          'kind': 'BADMINTON',
          'setsToWin': 2,
          'pointsPerSet': 21,
          'mustWinByTwo': true,
        };
      case AppConstants.sportFootball:
        return {
          'kind': 'FOOTBALL',
          'halvesCount': 2,
          'halfDuration': 45,
          'allowDraw': true,
          'bestOf': 1,
        };
      default:
        throw ArgumentError('Unsupported sport: $sport');
    }
  }

  String _normalizeBracketType(String bracketType) {
    switch (bracketType.toLowerCase()) {
      case AppConstants.bracketDoubleElimination:
        return 'DOUBLE_ELIMINATION';
      case AppConstants.bracketRoundRobin:
        return 'ROUND_ROBIN';
      case AppConstants.bracketGroupStageKnockout:
        return 'GROUP_STAGE_KNOCKOUT';
      case AppConstants.bracketSingleElimination:
      default:
        return 'SINGLE_ELIMINATION';
    }
  }

  @override
  Future<Tournament?> getById(String id, {String? inviteCode}) async {
    _log.debug('Fetching tournament by id via API: $id');
    try {
      final query = <String, dynamic>{
        if (inviteCode != null && inviteCode.trim().isNotEmpty)
          'invite': inviteCode.trim(),
      };

      final response = await _dioClient.dio.get(
        '/tournaments/$id',
        queryParameters: query.isEmpty ? null : query,
      );
      Response<dynamic>? divResponse;
      try {
        divResponse = await _dioClient.dio.get('/tournaments/$id/divisions');
      } catch (_) {
        // Tournament details remain usable when the optional divisions call fails.
      }

      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data != null) {
          if ((data['divisions'] == null ||
                  (data['divisions'] is List && (data['divisions'] as List).isEmpty)) &&
              divResponse != null &&
              divResponse.statusCode == 200) {
            final divData = divResponse.data['data'] ?? divResponse.data;
            if (divData is List && divData.isNotEmpty) {
              data['divisions'] = divData;
            }
          }
          final tournament = Tournament.fromJson(data, id);
          _tournamentCache[id] = tournament;
          return tournament;
        }
      }
      return null;
    } catch (e, stack) {
      _log.error('Error fetching tournament by id', e, stack);
      // Rate limits and transient network errors must not turn an existing
      // tournament into a false "not found" screen.
      return _tournamentCache[id];
    }
  }

  @override
  Future<Tournament?> getByInviteCode(String code) async {
    _log.debug('Resolving tournament by invite code via API: $code');
    try {
      final response = await _dioClient.dio.get('/tournaments/join/$code');
      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data != null) {
          final id = data['id']?.toString() ?? '';
          return Tournament.fromJson(data, id);
        }
      }
      return null;
    } catch (e, stack) {
      _log.error('Error resolving tournament by invite code', e, stack);
      return null;
    }
  }

  @override
  Future<TournamentWorkspace> getMyWorkspace() async {
    _log.debug('Fetching tournament workspace for current user');
    try {
      final response = await _dioClient.dio.get('/tournaments/workspace/me');
      final raw = response.data;
      final data = raw is Map<String, dynamic>
          ? (raw['data'] as Map<String, dynamic>? ?? raw)
          : <String, dynamic>{};
      return TournamentWorkspace.fromJson(data);
    } catch (e, stack) {
      _log.error('Error fetching tournament workspace', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> respondToRefereeInvite({
    required String tournamentId,
    required String refereeId,
    required String action,
  }) async {
    _log.info('Responding referee invite: $tournamentId / $refereeId -> $action');
    await _dioClient.dio.patch(
      '/tournaments/$tournamentId/referees/$refereeId/respond',
      data: {'action': action},
    );
  }

  @override
  Future<List<TournamentDivisionOption>> getDivisions(
    String tournamentId,
  ) async {
    try {
      final response = await _dioClient.dio.get(
        '/tournaments/$tournamentId/divisions',
      );
      final rawData = response.data['data'];
      if (rawData is List && rawData.isNotEmpty) {
        final list = rawData
            .whereType<Map>()
            .map(
              (item) => TournamentDivisionOption.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .where((division) => division.id.isNotEmpty)
            .toList();
        if (list.isNotEmpty) return list;
      }
    } catch (e) {
      _log.warning('Failed to fetch divisions via API, creating fallback: $e');
    }

    // Fallback: return default division using tournament details
    try {
      final tournament = await getById(tournamentId);
      if (tournament != null) {
        final isDoubles = tournament.format.toLowerCase() == 'doubles' ||
            tournament.name.toLowerCase().contains('đôi');
        return [
          TournamentDivisionOption(
            id: 'default_$tournamentId',
            name: tournament.name.isNotEmpty ? tournament.name : 'Nội dung chính',
            matchType: isDoubles ? 'DOUBLES' : 'SINGLES',
            entryFee: tournament.entryFee,
            maxParticipants: tournament.maxTeams,
          ),
        ];
      }
    } catch (_) {}

    return const [];
  }

  @override
  Future<TournamentRegistrationResult> registerParticipant({
    required String tournamentId,
    required String teamName,
    String? divisionId,
    String? inviteCode,
    String? partnerEmailOrPhone,
    String? footballTeamId,
    List<String>? memberIds,
    List<String>? reserveMemberIds,
    bool rankingConsent = false,
  }) async {
    final queryParameters = <String, dynamic>{};
    if (inviteCode != null && inviteCode.trim().isNotEmpty) {
      queryParameters['invite'] = inviteCode.trim();
    }

    final validDivisionId = (divisionId != null && !divisionId.startsWith('default_') && divisionId.isNotEmpty)
        ? divisionId
        : null;

    final response = await _dioClient.dio.post(
      '/tournaments/$tournamentId/register',
      data: {
        'teamName': teamName.trim(),
        ...?(validDivisionId == null ? null : {'divisionId': validDivisionId}),
        if (partnerEmailOrPhone != null && partnerEmailOrPhone.trim().isNotEmpty)
          'partnerEmailOrPhone': partnerEmailOrPhone.trim(),
        if (footballTeamId != null && footballTeamId.trim().isNotEmpty)
          'footballTeamId': footballTeamId.trim(),
        if (memberIds != null && memberIds.isNotEmpty) 'memberIds': memberIds,
        if (reserveMemberIds != null && reserveMemberIds.isNotEmpty) 'reserveMemberIds': reserveMemberIds,
        'rankingConsent': rankingConsent,
      },
      queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
    );
    final body = response.data;
    final rawData = body is Map && body['data'] is Map ? body['data'] : body;
    if (rawData is! Map) {
      throw const FormatException('Phản hồi đăng ký không hợp lệ.');
    }
    return TournamentRegistrationResult.fromJson(
      Map<String, dynamic>.from(rawData),
    );
  }

  @override
  Future<void> joinLite(String inviteCode) async {
    final code = inviteCode.trim();
    if (code.isEmpty) throw const FormatException('Mã tham gia giải không hợp lệ.');
    await _dioClient.dio.post('/tournaments/lite/join/$code');
  }

  @override
  Future<FootballRosterStatus> getFootballRosterStatus({required String tournamentId, required String participantId}) async {
    final response = await _dioClient.dio.get('/tournaments/$tournamentId/participants/$participantId/football-roster');
    final body = response.data;
    final data = body is Map && body['data'] is Map ? body['data'] : body;
    if (data is! Map) throw const FormatException('Phản hồi roster bóng đá không hợp lệ.');
    return FootballRosterStatus.fromJson(Map<String, dynamic>.from(data));
  }

  @override
  Future<FootballRosterStatus> updateFootballRoster({
    required String tournamentId,
    required String participantId,
    required List<String> memberIds,
    required List<String> reserveMemberIds,
  }) async {
    final response = await _dioClient.dio.patch(
      '/tournaments/$tournamentId/participants/$participantId/football-roster',
      data: {
        'memberIds': memberIds,
        'reserveMemberIds': reserveMemberIds,
      },
    );
    final body = response.data;
    final data = body is Map && body['data'] is Map ? body['data'] : body;
    if (data is! Map) throw const FormatException('Phản hồi cập nhật roster không hợp lệ.');
    return FootballRosterStatus.fromJson(Map<String, dynamic>.from(data));
  }

  @override
  Future<void> respondFootballRoster({required String tournamentId, required String participantId, required String action}) async {
    if (action != 'CONFIRM' && action != 'DECLINE') {
      throw ArgumentError.value(action, 'action', 'Must be CONFIRM or DECLINE');
    }
    await _dioClient.dio.post(
      '/tournaments/$tournamentId/participants/$participantId/football-roster/respond',
      data: {'action': action},
    );
  }

  @override
  Future<Map<String, dynamic>> withdraw({
    required String tournamentId,
    String? bankName,
    String? bankAccountNumber,
    String? bankAccountName,
    String? divisionId,
  }) async {
    final response = await _dioClient.dio.post(
      '/tournaments/$tournamentId/withdraw',
      data: {
        'bankName': ?bankName,
        'bankAccountNumber': ?bankAccountNumber,
        'bankAccountName': ?bankAccountName,
        'tournamentDivisionId': ?divisionId,
      },
    );
    return (response.data is Map) ? response.data as Map<String, dynamic> : {};
  }

  @override
  Stream<Tournament?> watch(String id) async* {
    // A transient timeout/429 must not turn a visible tournament into
    // "not found". Keep the last confirmed snapshot while polling.
    Tournament? lastKnown;
    final initial = await getById(id);
    if (initial != null) lastKnown = initial;
    yield lastKnown;

    final updates = StreamController<Tournament?>();
    Timer? refreshTimer;
    StreamSubscription<Map<String, dynamic>>? registrationSubscription;
    Future<void> refresh() async {
      try {
        final updated = await getById(id);
        if (updated != null) lastKnown = updated;
        if (!updates.isClosed) updates.add(lastKnown);
      } catch (error, stack) {
        _log.error('Keeping cached tournament after realtime refresh failure', error, stack);
      }
    }

    final socketService = _matchSocketService;
    if (socketService != null) {
      registrationSubscription = socketService.onRegistrationUpdate
          .where((payload) => payload['tournamentId']?.toString() == id)
          .listen((_) => refresh());
      socketService.connect(null, joinMatch: false);
      socketService.joinTournament(id);
    }
    refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) => refresh());

    try {
      yield* updates.stream;
    } finally {
      refreshTimer.cancel();
      if (registrationSubscription != null) {
        await registrationSubscription.cancel();
      }
      if (socketService != null) socketService.leaveTournament(id);
      await updates.close();
    }
  }

  List<Tournament> _parseTournamentList(dynamic rawData) {
    if (rawData == null) return [];
    List<dynamic> list = [];
    if (rawData is Map) {
      final dataField = rawData['data'];
      if (dataField is List) {
        list = dataField;
      } else if (dataField is Map && dataField['data'] is List) {
        list = dataField['data'] as List<dynamic>;
      } else if (rawData['items'] is List) {
        list = rawData['items'] as List<dynamic>;
      }
    } else if (rawData is List) {
      list = rawData;
    }
    
    final List<Tournament> result = [];
    for (final item in list) {
      if (item is! Map) continue;
      try {
        final mapItem = Map<String, dynamic>.from(item);
        final t = Tournament.fromJson(mapItem, mapItem['id']?.toString() ?? '');
        result.add(t);
      } catch (err) {
        _log.warning('Skipping malformed tournament item: $err');
      }
    }
    _log.info('_parseTournamentList: Extracted ${result.length} tournaments');
    return result;
  }

  /// Backend giới hạn limit tối đa 50/trang (QueryTournamentDto.limit @Max(50)).
  static const int _publicPageSize = 50;
  /// Tối đa số trang sẽ tải — giới hạn an toàn cho feed (tối đa 500 giải).
  static const int _publicMaxPages = 10;

  /// Tải toàn bộ giải đấu công khai theo trang (giống web), để app hiện
  /// đầy đủ giải đấu thay vì chỉ 1 trang 20 giải như trước.
  ///
  /// LƯU Ý: KHÔNG gửi `publicOnly` tới /tournaments/public — QueryTournamentDto
  /// không khai báo param này, ValidationPipe toàn cục (forbidNonWhitelisted)
  /// sẽ trả 400 làm feed trống (web cũng không gửi).
  Future<List<Tournament>> _fetchAllPublicTournaments() async {
    final List<Tournament> all = [];
    String? cursor;
    for (var page = 1; page <= _publicMaxPages; page++) {
      dynamic response;
      try {
        response = await _dioClient.dio.get(
          '/tournaments/public',
          queryParameters: {
            'limit': _publicPageSize,
            ...?(cursor == null ? null : {'cursor': cursor}),
          },
        );
      } catch (_) {
        response = await _dioClient.dio.get(
          '/tournaments',
          queryParameters: {
            'limit': _publicPageSize,
            ...?(cursor == null ? null : {'cursor': cursor}),
          },
        );
      }
      if (response.statusCode != 200) break;
      final parsed = _parseTournamentList(response.data);
      all.addAll(parsed);
      if (parsed.length < _publicPageSize) break; // đã hết dữ liệu
      final raw = response.data;
      final meta = raw is Map && raw['meta'] is Map
          ? Map<String, dynamic>.from(raw['meta'] as Map)
          : const <String, dynamic>{};
      cursor = meta['nextCursor']?.toString();
      if (cursor == null || cursor.isEmpty || meta['hasMore'] != true) break;
    }
    return all;
  }

  @override
  Stream<List<Tournament>> watchAll() async* {
    List<Tournament>? lastGoodValue;
    var retryDelay = const Duration(seconds: 5);

    while (true) {
      try {
        final value = await _fetchAllPublicTournaments();
        lastGoodValue = value;
        retryDelay = const Duration(seconds: 5);
        yield value;
        await Future<void>.delayed(const Duration(seconds: 45));
      } catch (e, stack) {
        _log.error('Error fetching tournaments in watchAll', e, stack);
        if (lastGoodValue != null) {
          yield lastGoodValue;
        } else {
          // Không biến lỗi API/401/429/5xx thành trạng thái "không có giải".
          // UI cần nhận error để hiển thị retry và log đúng nguyên nhân.
          yield* Stream<List<Tournament>>.error(e, stack);
        }
        await Future<void>.delayed(retryDelay);
        retryDelay = Duration(
          seconds: (retryDelay.inSeconds * 2).clamp(5, 60),
        );
      }
    }
  }

  @override
  Future<void> update(String id, Map<String, dynamic> data) async {
    _log.info('Updating tournament $id via API: $data');
    await _dioClient.dio.patch('/tournaments/$id', data: data);
  }

  @override
  Future<void> updateStatus(String id, String status) async {
    _log.info('Updating tournament status $id → $status');
    await _dioClient.dio.patch('/tournaments/$id', data: {'status': status});
  }

  @override
  Future<void> updateToken(String id, String role, String newToken) async {
    // Thường được Web Admin quản lý
    _log.warning('updateToken not supported/required directly from mobile API client.');
  }

  @override
  Future<void> delete(String id) async {
    _log.info('Deleting tournament $id via API');
    await _dioClient.dio.delete('/tournaments/$id');
  }

  // ─── Group Standings API ──────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> getGroupStandings(String tournamentId, {String? divisionId}) async {
    _log.debug('Fetching group standings for tournament $tournamentId');
    try {
      final queryParams = <String, dynamic>{};
      if (divisionId != null && divisionId.isNotEmpty) {
        queryParams['divisionId'] = divisionId;
      }
      final response = await _dioClient.dio.get(
        '/tournaments/$tournamentId/standings',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>? ?? response.data as Map<String, dynamic>? ?? {};
        return data;
      }
      return {};
    } catch (e, stack) {
      _log.error('Error fetching group standings', e, stack);
      return {};
    }
  }

  // ─── Bracket API ─────────────────────────────────────────────────────────

  /// Gọi GET /tournaments/:id/bracket và trả về danh sách matches đã có
  /// đầy đủ roundNumber, matchOrder, bracketBranch, isBye, nextMatchId.
  /// Đây là endpoint ĐÚNG để render bracket diagram (khác với /matches flat list).
  @override
  Future<List<MatchModel>> getBracketMatches(
    String tournamentId, {
    String? divisionId,
    bool allowAggregateFallback = true,
  }) async {
    _log.debug('Fetching bracket matches for tournament $tournamentId (division: $divisionId)');
    try {
      final response = await _dioClient.dio.get(
        '/tournaments/$tournamentId/bracket',
        queryParameters: divisionId != null && divisionId.isNotEmpty ? {'divisionId': divisionId} : null,
      );
      if (response.statusCode == 200 && response.data['data'] != null) {
        final rawPayload = response.data;
        final data = rawPayload is Map && rawPayload['data'] is Map
            ? rawPayload['data'] as Map
            : rawPayload as Map;
        final stages = data['stages'] is List
            ? List<dynamic>.from(data['stages'] as List)
            : const <dynamic>[];
        final allMatches = <MatchModel>[];

        if (stages.isNotEmpty) {
          for (final stage in stages) {
            final stageName = stage['name']?.toString();
            final stageType = stage['type']?.toString();
            final groups = stage['groups'] is List
                ? List<dynamic>.from(stage['groups'] as List)
                : const <dynamic>[];
            for (final group in groups) {
              final groupName = group['name']?.toString();
              final rawMatches = group['matches'] is List
                  ? List<dynamic>.from(group['matches'] as List)
                  : const <dynamic>[];
              for (final json in rawMatches) {
                if (json is! Map<String, dynamic>) continue;
                try {
                  allMatches.add(_parseBracketMatch(
                    json,
                    groupName: groupName,
                    stageName: stageName,
                    stageType: stageType,
                  ));
                } catch (e) {
                  _log.warning('Failed to parse bracket match: $e');
                }
              }
            }
          }
        }

        if (allMatches.isNotEmpty) {
          allMatches.sort((a, b) {
            final r = a.round.compareTo(b.round);
            return r != 0 ? r : a.matchNumber.compareTo(b.matchNumber);
          });
          _log.info('Bracket: ${allMatches.length} matches loaded for $tournamentId');
          return allMatches;
        }
      }

      // If a specific divisionId was queried and has no matches, return [] directly.
      if (divisionId != null && divisionId.isNotEmpty) {
        return [];
      }

      // Fallback for "Tất cả" (divisionId == null): Query all divisions & aggregate matches
      if (allowAggregateFallback && (divisionId == null || divisionId.isEmpty)) {
        final divOptions = await getDivisions(tournamentId);
        if (divOptions.isNotEmpty) {
          final aggregatedMatches = <MatchModel>[];
          final matchIds = <String>{};
          for (final div in divOptions) {
            final divMatches = await getBracketMatches(tournamentId, divisionId: div.id);
            for (final m in divMatches) {
              if (matchIds.add(m.id)) {
                aggregatedMatches.add(m);
              }
            }
          }
          if (aggregatedMatches.isNotEmpty) {
            aggregatedMatches.sort((a, b) {
              final r = a.round.compareTo(b.round);
              return r != 0 ? r : a.matchNumber.compareTo(b.matchNumber);
            });
            _log.info('Bracket fallback "Tất cả": ${aggregatedMatches.length} matches aggregated for $tournamentId');
            return aggregatedMatches;
          }
        }
      }

      return [];
    } catch (e, stack) {
      _log.error('Error fetching bracket matches', e, stack);
      return [];
    }
  }

  @override
  Stream<List<MatchModel>> watchBracketMatches(String tournamentId, {String? divisionId}) async* {
    yield await getBracketMatches(tournamentId, divisionId: divisionId);
    yield* Stream.periodic(const Duration(seconds: 30))
        .asyncMap((_) => getBracketMatches(tournamentId, divisionId: divisionId));
  }

  static String _mapBracketMatchStatus(String? status) {
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

  static MatchModel _parseBracketMatch(
    Map<String, dynamic> json, {
    String? groupName,
    String? stageName,
    String? stageType,
  }) {
    final p1 = json['participant1'] as Map<String, dynamic>?;
    final p2 = json['participant2'] as Map<String, dynamic>?;
    final team1Name = p1?['teamName']?.toString() ??
        json['team1Name']?.toString() ??
        json['participant1Name']?.toString() ??
        '';
    final team2Name = p2?['teamName']?.toString() ??
        json['team2Name']?.toString() ??
        json['participant2Name']?.toString() ??
        '';
    String? participantLogo(Map<String, dynamic>? participant) {
      final value = participant?['logoUrl'] ?? participant?['logo_url'];
      return value?.toString().trim().isNotEmpty == true ? value.toString() : null;
    }
    final rosters1 = (p1?['members'] ?? p1?['rosters']) as List<dynamic>?;
    final team1Members = rosters1?.map((r) => r['fullName']?.toString() ?? '').where((n) => n.isNotEmpty).toList() ?? <String>[];
    final rosters2 = (p2?['members'] ?? p2?['rosters']) as List<dynamic>?;
    final team2Members = rosters2?.map((r) => r['fullName']?.toString() ?? '').where((n) => n.isNotEmpty).toList() ?? <String>[];

    final roundNumber = json['roundNumber'] is num
        ? (json['roundNumber'] as num).toInt()
        : int.tryParse(json['roundNumber']?.toString() ?? '') ?? 1;
    final matchOrder = json['matchOrder'] is num
        ? (json['matchOrder'] as num).toInt()
        : int.tryParse(json['matchOrder']?.toString() ?? '') ?? 1;
    final branch = _mapBracketBranch(json['bracketBranch'] as String?);

    final rawGroup = json['group'] as Map<String, dynamic>?;
    final resolvedGroupName = groupName ?? rawGroup?['name']?.toString();
    final rawStage = rawGroup?['stage'] as Map<String, dynamic>?;
    final resolvedStageName = stageName ?? rawStage?['name']?.toString();
    final resolvedStageType =
        stageType ?? rawStage?['type']?.toString() ?? json['stageType']?.toString();

    int parseScore(dynamic value) {
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    final scoreDetails = json['scoreDetails'] is Map
        ? Map<String, dynamic>.from(json['scoreDetails'] as Map)
        : null;
    Map<String, dynamic>? asMap(dynamic value) {
      return value is Map ? Map<String, dynamic>.from(value) : null;
    }

    final tournamentJson = asMap(json['tournament']);
    final stageJson = asMap(rawStage);
    final sportRules = asMap(json['sportRules']) ??
        asMap(tournamentJson?['sportRules']) ??
        asMap(stageJson?['sportRules']) ??
        asMap(json['matchConfig']);
    final tournamentConfig = asMap(json['tournamentConfig']) ??
        asMap(tournamentJson?['tournamentConfig']);
    final rawSets = scoreDetails?['sets'] as List<dynamic>? ?? const [];
    final sets = rawSets.whereType<Map>().map((rawSet) {
      return SetScore(
        score1: parseScore(rawSet['team1Score'] ?? rawSet['score1'] ?? rawSet['p1']),
        score2: parseScore(rawSet['team2Score'] ?? rawSet['score2'] ?? rawSet['p2']),
      );
    }).toList();

    return MatchModel(
      id: json['id']?.toString() ?? '',
      round: roundNumber,
      matchNumber: matchOrder,
      team1Id: p1?['id']?.toString() ?? json['participant1Id']?.toString() ?? '',
      team1Name: team1Name.isNotEmpty ? team1Name : 'TBD',
      team1LogoUrl: participantLogo(p1) ?? json['team1LogoUrl']?.toString() ?? json['team1Logo']?.toString(),
      team2Id: p2?['id']?.toString() ?? json['participant2Id']?.toString() ?? '',
      team2Name: team2Name.isNotEmpty ? team2Name : 'TBD',
      team2LogoUrl: participantLogo(p2) ?? json['team2LogoUrl']?.toString() ?? json['team2Logo']?.toString(),
      score1: json['p1SetsWon'] is num
          ? (json['p1SetsWon'] as num).toInt()
          : int.tryParse(json['p1SetsWon']?.toString() ?? '') ?? 0,
      score2: json['p2SetsWon'] is num
          ? (json['p2SetsWon'] as num).toInt()
          : int.tryParse(json['p2SetsWon']?.toString() ?? '') ?? 0,
      sets: sets,
      status: _mapBracketMatchStatus(json['status'] as String?),
      bracketPosition: BracketPosition(
        bracket: branch,
        round: roundNumber,
        position: matchOrder,
      ),
      nextMatchId: json['nextMatchId']?.toString() ?? '',
      loserNextMatchId: json['loserNextMatchId']?.toString() ?? '',
      winnerId: json['winnerId']?.toString() ?? '',
      isBye: json['isBye'] as bool? ?? false,
      court: _buildCourtDisplay(
        court: json['court']?.toString(),
        courtName: json['courtName']?.toString(),
        courtAddress: json['courtAddress']?.toString(),
      ),
      courtAddress: json['courtAddress']?.toString() ?? '',
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      refereeId: json['refereeId']?.toString(),
      sportRules: sportRules,
      tournamentConfig: tournamentConfig,
      scoreDetails: scoreDetails,
      setsToWin: json['setsToWin'] is num
          ? (json['setsToWin'] as num).toInt()
          : sportRules?['setsToWin'] is num
              ? (sportRules?['setsToWin'] as num).toInt()
              : sportRules?['sets_to_win'] is num
                  ? (sportRules?['sets_to_win'] as num).toInt()
          : null,
      team1Members: team1Members,
      team2Members: team2Members,
      groupName: resolvedGroupName,
      stageName: resolvedStageName,
      stageType: resolvedStageType,
    );
  }

  // ─── Follow / Unfollow ────────────────────────────────────────────────────

  @override
  Future<void> followTournament(String id) async {
    _log.info('Following tournament $id');
    await _dioClient.dio.post('/tournaments/$id/follow');
  }

  @override
  Future<void> unfollowTournament(String id) async {
    _log.info('Unfollowing tournament $id');
    await _dioClient.dio.delete('/tournaments/$id/follow');
  }

  @override
  Future<bool> isFollowing(String id) async {
    try {
      final followed = await getFollowedTournaments();
      return followed.any((t) => t.id == id);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<Tournament>> getFollowedTournaments() async {
    try {
      final response = await _dioClient.dio.get('/tournaments/my/followed');
      if (response.statusCode == 200) {
        final data = response.data['data'] as List<dynamic>? ?? [];
        return data.map((json) => Tournament.fromJson(json as Map<String, dynamic>, json['id'])).toList();
      }
      return [];
    } catch (e, stack) {
      _log.error('Lỗi lấy danh sách theo dõi', e, stack);
      return [];
    }
  }
}
