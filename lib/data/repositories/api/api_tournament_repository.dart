import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/data/models/tournament_model.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_repository.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_workspace.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_registration.dart';

class ApiTournamentRepository implements ITournamentRepository {
  static const _log = AppLogger('ApiTournamentRepo');
  final DioClient _dioClient;

  ApiTournamentRepository(this._dioClient);

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
      default:
        return {
          'kind': 'BADMINTON',
          'setsToWin': 2,
          'pointsPerSet': 21,
          'mustWinByTwo': true,
        };
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
  Future<Tournament?> getById(String id) async {
    _log.debug('Fetching tournament by id via API: $id');
    try {
      final response = await _dioClient.dio.get('/tournaments/$id');
      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data != null) {
          return Tournament.fromJson(data, id);
        }
      }
      return null;
    } catch (e, stack) {
      _log.error('Error fetching tournament by id', e, stack);
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
    final response = await _dioClient.dio.get(
      '/tournaments/$tournamentId/divisions',
    );
    final rawData = response.data['data'];
    if (rawData is! List) return const [];
    return rawData
        .whereType<Map>()
        .map(
          (item) => TournamentDivisionOption.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .where((division) => division.id.isNotEmpty)
        .toList();
  }

  @override
  Future<TournamentRegistrationResult> registerParticipant({
    required String tournamentId,
    required String teamName,
    String? divisionId,
    String? inviteCode,
    String? partnerEmailOrPhone,
  }) async {
    final response = await _dioClient.dio.post(
      '/tournaments/$tournamentId/register',
      data: {
        'teamName': teamName.trim(),
        'divisionId': divisionId,
        if (inviteCode != null && inviteCode.trim().isNotEmpty)
          'inviteCode': inviteCode.trim(),
        if (partnerEmailOrPhone != null && partnerEmailOrPhone.trim().isNotEmpty)
          'partnerEmailOrPhone': partnerEmailOrPhone.trim(),
      },
    );
    final rawData = response.data['data'];
    if (rawData is! Map) {
      throw const FormatException('Phản hồi đăng ký không hợp lệ.');
    }
    return TournamentRegistrationResult.fromJson(
      Map<String, dynamic>.from(rawData),
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
        if (bankName != null) 'bankName': bankName,
        if (bankAccountNumber != null) 'bankAccountNumber': bankAccountNumber,
        if (bankAccountName != null) 'bankAccountName': bankAccountName,
        if (divisionId != null) 'tournamentDivisionId': divisionId,
      },
    );
    return (response.data is Map) ? response.data as Map<String, dynamic> : {};
  }

  @override
  Stream<Tournament?> watch(String id) async* {
    yield await getById(id);
    yield* Stream.periodic(const Duration(seconds: 10))
        .asyncMap((_) => getById(id));
  }

  List<Tournament> _parseTournamentList(dynamic rawData) {
    if (rawData == null) return [];
    List<dynamic> list = [];
    if (rawData is Map<String, dynamic>) {
      if (rawData['data'] is List) {
        list = rawData['data'] as List<dynamic>;
      } else if (rawData['items'] is List) {
        list = rawData['items'] as List<dynamic>;
      }
    } else if (rawData is List) {
      list = rawData;
    }
    
    final List<Tournament> result = [];
    for (final item in list) {
      if (item is! Map<String, dynamic>) continue;
      try {
        final t = Tournament.fromJson(item, item['id']?.toString() ?? '');
        result.add(t);
      } catch (err) {
        _log.warning('Skipping malformed tournament item: $err');
      }
    }
    return result;
  }

  @override
  Stream<List<Tournament>> watchAll() async* {
    try {
      final response = await _dioClient.dio.get('/tournaments/public');
      if (response.statusCode == 200) {
        final raw = response.data['data'];
        yield _parseTournamentList(raw);
      } else {
        yield <Tournament>[];
      }
    } catch (e, stack) {
      _log.error('Error fetching initial public tournaments', e, stack);
      yield <Tournament>[];
    }

    yield* Stream.periodic(const Duration(seconds: 15))
        .asyncMap((_) async {
          try {
            final response = await _dioClient.dio.get('/tournaments/public');
            if (response.statusCode == 200) {
              final raw = response.data['data'];
              return _parseTournamentList(raw);
            }
          } catch (e, stack) {
            _log.error('Error polling public tournaments', e, stack);
          }
          return <Tournament>[];
        });
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

  // ─── Bracket API ─────────────────────────────────────────────────────────

  /// Gọi GET /tournaments/:id/bracket và trả về danh sách matches đã có
  /// đầy đủ roundNumber, matchOrder, bracketBranch, isBye, nextMatchId.
  /// Đây là endpoint ĐÚNG để render bracket diagram (khác với /matches flat list).
  @override
  Future<List<MatchModel>> getBracketMatches(String tournamentId) async {
    _log.debug('Fetching bracket matches for tournament $tournamentId');
    try {
      final response = await _dioClient.dio.get('/tournaments/$tournamentId/bracket');
      if (response.statusCode != 200) return [];
      final data = response.data['data'];
      if (data == null) return [];

      final stages = data['stages'] as List<dynamic>? ?? [];
      final allMatches = <MatchModel>[];

      if (stages.isNotEmpty) {
        final stage = stages.last;
        final groups = stage['groups'] as List<dynamic>? ?? [];
        for (final group in groups) {
          final rawMatches = group['matches'] as List<dynamic>? ?? [];
          for (final json in rawMatches) {
            if (json is! Map<String, dynamic>) continue;
            try {
              allMatches.add(_parseBracketMatch(json));
            } catch (e) {
              _log.warning('Failed to parse bracket match: $e');
            }
          }
        }
      }

      // Sort: round ascending, then matchOrder ascending
      allMatches.sort((a, b) {
        final r = a.round.compareTo(b.round);
        return r != 0 ? r : a.matchNumber.compareTo(b.matchNumber);
      });

      _log.info('Bracket: ${allMatches.length} matches loaded for $tournamentId');
      return allMatches;
    } catch (e, stack) {
      _log.error('Error fetching bracket matches', e, stack);
      return [];
    }
  }

  @override
  Stream<List<MatchModel>> watchBracketMatches(String tournamentId) async* {
    yield await getBracketMatches(tournamentId);
    yield* Stream.periodic(const Duration(seconds: 10))
        .asyncMap((_) => getBracketMatches(tournamentId));
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

  static MatchModel _parseBracketMatch(Map<String, dynamic> json) {
    final p1 = json['participant1'] as Map<String, dynamic>?;
    final p2 = json['participant2'] as Map<String, dynamic>?;
    final team1Name = p1?['teamName']?.toString() ?? '';
    final team2Name = p2?['teamName']?.toString() ?? '';
    final rosters1 = (p1?['members'] ?? p1?['rosters']) as List<dynamic>?;
    final team1Members = rosters1?.map((r) => r['fullName']?.toString() ?? '').where((n) => n.isNotEmpty).toList() ?? <String>[];
    final rosters2 = (p2?['members'] ?? p2?['rosters']) as List<dynamic>?;
    final team2Members = rosters2?.map((r) => r['fullName']?.toString() ?? '').where((n) => n.isNotEmpty).toList() ?? <String>[];

    final roundNumber = (json['roundNumber'] as int?) ?? 1;
    final matchOrder = (json['matchOrder'] as int?) ?? 1;
    final branch = _mapBracketBranch(json['bracketBranch'] as String?);

    return MatchModel(
      id: json['id']?.toString() ?? '',
      round: roundNumber,
      matchNumber: matchOrder,
      team1Id: p1?['id']?.toString() ?? '',
      team1Name: team1Name.isNotEmpty ? team1Name : 'TBD',
      team2Id: p2?['id']?.toString() ?? '',
      team2Name: team2Name.isNotEmpty ? team2Name : 'TBD',
      score1: (json['p1SetsWon'] as int?) ?? 0,
      score2: (json['p2SetsWon'] as int?) ?? 0,
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
      scoreDetails: json['scoreDetails'] as Map<String, dynamic>?,
      team1Members: team1Members,
      team2Members: team2Members,
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
