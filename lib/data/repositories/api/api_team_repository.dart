import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:app_quanly_giaidau/data/models/team_model.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/repositories/team_repository.dart';

class ApiTeamRepository implements ITeamRepository {
  static const _log = AppLogger('ApiTeamRepo');
  final DioClient _dioClient;

  ApiTeamRepository(this._dioClient);

  Future<List<FootballTeamSummary>> listMyFootballTeams() async {
    final response = await _dioClient.dio.get('/football-teams/mine');
    final raw = response.data is Map ? response.data['data'] : response.data;
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((row) => FootballTeamSummary.fromJson(Map<String, dynamic>.from(row))).toList();
  }

  Future<FootballTeamSummary> createFootballTeam({required String name, required String categoryId}) async {
    final response = await _dioClient.dio.post('/football-teams', data: {'name': name.trim(), 'categoryId': categoryId});
    final raw = response.data is Map ? response.data['data'] : response.data;
    if (raw is! Map) throw const FormatException('Phản hồi tạo đội không hợp lệ.');
    return FootballTeamSummary.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<FootballTeamSummary> getFootballTeam(String teamId) async {
    final response = await _dioClient.dio.get('/football-teams/$teamId');
    final raw = response.data is Map && response.data['data'] is Map
        ? response.data['data'] as Map
        : response.data as Map;
    return FootballTeamSummary.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<FootballTeamSummary> updateFootballTeam(String teamId, {String? name, String? logoUrl, String? status}) async {
    final payload = <String, dynamic>{
      ...?name == null ? null : {'name': name.trim()},
      ...?logoUrl == null ? null : {'logoUrl': logoUrl},
      ...?status == null ? null : {'status': status},
    };
    final response = await _dioClient.dio.patch('/football-teams/$teamId', data: {
      ...payload,
    });
    final raw = response.data is Map ? response.data['data'] : response.data;
    return FootballTeamSummary.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  Future<FootballTeamSummary> uploadFootballTeamLogo(String teamId, List<int> bytes, String fileName) async {
    final upload = await _dioClient.dio.post(
      '/upload/image',
      data: FormData.fromMap({'file': MultipartFile.fromBytes(bytes, filename: fileName)}),
      options: Options(headers: {'Content-Type': 'multipart/form-data'}),
    );
    final uploadData = upload.data is Map ? upload.data['data'] ?? upload.data : upload.data;
    final url = uploadData is Map ? uploadData['url']?.toString() : null;
    if (url == null || url.isEmpty) throw const FormatException('Ảnh logo không hợp lệ.');
    return updateFootballTeam(teamId, logoUrl: url);
  }

  Future<List<Map<String, dynamic>>> searchFootballTeamMembers(String teamId, String query) async {
    final response = await _dioClient.dio.get('/football-teams/$teamId/member-candidates', queryParameters: {'q': query, 'limit': 20});
    final raw = response.data is Map ? response.data['data'] : response.data;
    return raw is List ? raw.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList() : const [];
  }

  Future<void> inviteFootballTeamMember(String teamId, String userId) async {
    await _dioClient.dio.post('/football-teams/$teamId/invites', data: {'userId': userId});
  }

  Future<void> cancelFootballTeamInvite(String teamId, String userId) async {
    await _dioClient.dio.delete('/football-teams/$teamId/invites/$userId');
  }

  Future<void> respondToFootballTeamInvite(String teamId, String status) async {
    _log.info('Responding football team invite: $teamId -> $status');
    await _dioClient.dio.post(
      '/football-teams/$teamId/invites/respond',
      data: {'status': status},
    );
  }

  Future<void> updateFootballTeamMember(String teamId, String userId, String role) async {
    await _dioClient.dio.patch('/football-teams/$teamId/members/$userId', data: {'role': role});
  }

  Future<void> removeFootballTeamMember(String teamId, String userId) async {
    await _dioClient.dio.delete('/football-teams/$teamId/members/$userId');
  }

  Future<void> leaveFootballTeam(String teamId) async {
    await _dioClient.dio.delete('/football-teams/$teamId/members/me');
  }

  @override
  Future<Team> create(String tournamentId, Team team) async {
    _log.info('Creating team via API: ${team.name} inside $tournamentId');
    // Team sport: gửi memberIds (userId) để backend tạo roster thật; fallback playerNames.
    final memberIds = team.memberInfos
        .map((m) => m.userId)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    final payload = <String, dynamic>{
      'teamName': team.name,
      'contactPhone': team.contactEmail.isNotEmpty ? team.contactEmail : '0900000000',
      if (memberIds.isNotEmpty)
        'memberIds': memberIds
      else
        'playerNames': team.members.isNotEmpty ? team.members : [team.name],
    };
    final response = await _dioClient.dio.post('/tournaments/$tournamentId/register', data: payload);
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data['data']['participant'] ?? response.data['data'];
      return Team.fromJson(data, data['id']);
    }
    throw Exception('Failed to create/register team via API');
  }

  @override
  Future<void> importTeams(String tournamentId, List<Team> teams) async {
    _log.info('Importing teams via API to $tournamentId');
    for (final team in teams) {
      await create(tournamentId, team);
    }
  }

  @override
  Future<Team?> getById(String tournamentId, String teamId) async {
    _log.debug('Fetching team by id $teamId via API');
    final teams = await getAllByTournament(tournamentId);
    return teams.where((t) => t.id == teamId).firstOrNull;
  }

  @override
  Stream<List<Team>> watchByTournament(String tournamentId) async* {
    var lastKnown = await getAllByTournament(tournamentId);
    yield lastKnown;
    yield* Stream.periodic(const Duration(seconds: 15)).asyncMap((_) async {
      try {
        final updated = await getAllByTournament(tournamentId);
        lastKnown = updated;
      } catch (error, stack) {
        _log.error('Keeping cached teams after polling failure', error, stack);
      }
      return lastKnown;
    }).handleError((error, stack) {
      _log.error('Team stream recovered from polling error', error, stack);
    });
  }

  @override
  Future<List<Team>> getAllByTournament(String tournamentId) async {
    _log.debug('Fetching all participants/teams for tournament: $tournamentId');
    try {
      final response = await _dioClient.dio.get('/tournaments/$tournamentId/participants');
      dynamic divResponse;
      try {
        divResponse = await _dioClient.dio.get('/tournaments/$tournamentId/divisions');
      } catch (_) {
        divResponse = null;
      }

      final Map<String, String> divNameMap = {};
      if (divResponse != null && divResponse.statusCode == 200) {
        final divData = divResponse.data['data'] ?? divResponse.data;
        if (divData is List) {
          for (var d in divData) {
            if (d is Map) {
              final id = d['id']?.toString() ?? '';
              final name = d['name']?.toString() ?? '';
              if (id.isNotEmpty && name.isNotEmpty) {
                divNameMap[id] = name;
              }
            }
          }
        }
      }

      if (response.statusCode == 200) {
        final List<dynamic> list = response.data['data'] ?? response.data ?? [];
        return list.map((json) {
          final String id = json['id']?.toString() ?? '';
          final String teamName = json['teamName']?.toString() ?? '';
          final List<dynamic> rosters = json['rosters'] as List<dynamic>? ?? [];
          final List<String> members = rosters
              .map((r) => (r['fullName'] ?? r['user']?['fullName'] ?? '').toString())
              .where((n) => n.isNotEmpty)
              .toList();
          final memberInfos = rosters
              .whereType<Map>()
              .map((roster) => MatchMemberInfo.fromJson(
                    Map<String, dynamic>.from(roster),
                  ))
              .where((member) => member.fullName.isNotEmpty)
              .toList();

          final divisionMap = json['division'] as Map<String, dynamic>? ?? json['tournamentDivision'] as Map<String, dynamic>?;
          final divId = json['tournamentDivisionId']?.toString() ??
              json['divisionId']?.toString() ??
              divisionMap?['id']?.toString() ??
              '';
          final groupName = divisionMap?['name']?.toString() ??
              json['divisionName']?.toString() ??
              divNameMap[divId] ??
              '';

          return Team(
            id: id,
            name: teamName.isNotEmpty ? teamName : 'Đội $id',
            group: groupName,
            divisionId: divId,
            members: members.isNotEmpty ? members : [teamName.isNotEmpty ? teamName : 'VĐV'],
            memberInfos: memberInfos,
            contactEmail: json['contactPhone']?.toString() ?? '',
            qrCode: json['qrCode']?.toString() ?? id,
            approvalStatus:
                json['teamStatus']?.toString().toUpperCase() ??
                json['status']?.toString().toUpperCase() ??
                'PENDING',
            createdAt: json['createdAt'] != null
                ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
                : DateTime.now(),
          );
        }).toList();
      }
      return [];
    } catch (e, stack) {
      _log.error('Error fetching tournament participants', e, stack);
      return [];
    }
  }

  @override
  Future<void> update(String tournamentId, String teamId, Map<String, dynamic> data) async {
    _log.info('Updating team $teamId via API: $data');
    await _dioClient.dio.patch('/tournaments/$tournamentId/participants/$teamId', data: data);
  }

  @override
  Future<Team?> findByQrCode(String tournamentId, String qrCode) async {
    _log.info('Finding team by QR Code: $qrCode');
    final teams = await getAllByTournament(tournamentId);
    return teams.where((t) => t.qrCode == qrCode).firstOrNull;
  }

  @override
  Future<void> delete(String tournamentId, String teamId) async {
    _log.info('Deleting team $teamId via API');
    await _dioClient.dio.delete('/tournaments/$tournamentId/participants/$teamId');
  }

  @override
  Future<void> deleteAll(String tournamentId) async {
    _log.info('Deleting all teams in $tournamentId');
    final teams = await getAllByTournament(tournamentId);
    for (final t in teams) {
      await delete(tournamentId, t.id);
    }
  }

  @override
  Future<int> count(String tournamentId) async {
    final teams = await getAllByTournament(tournamentId);
    return teams.length;
  }
}

class FootballTeamSummary {
  const FootballTeamSummary({required this.id, required this.name, required this.categoryId, this.logoUrl, this.role, this.status = 'ACTIVE', this.members = const [], this.eloPoints = 1000, this.peakElo = 1000, this.matchesPlayed = 0, this.matchesWon = 0, this.winStreak = 0});
  final String id;
  final String name;
  final String categoryId;
  final String? logoUrl;
  final String? role;
  final String status;
  final List<FootballTeamMemberSummary> members;
  final int eloPoints;
  final int peakElo;
  final int matchesPlayed;
  final int matchesWon;
  final int winStreak;

  /// Thành viên đã tham gia (ACTIVE); loại INVITED/DECLINED/LEFT/REMOVED.
  List<FootballTeamMemberSummary> get activeMembers => members
      .where((member) => member.status == null || member.status!.toUpperCase() == 'ACTIVE')
      .toList();

  factory FootballTeamSummary.fromJson(Map<String, dynamic> json) {
    final team = json['team'] is Map ? Map<String, dynamic>.from(json['team']) : json;
    final membership = json['membership'] is Map ? Map<String, dynamic>.from(json['membership']) : null;
    return FootballTeamSummary(
      id: team['id']?.toString() ?? '',
      name: team['name']?.toString() ?? 'Đội bóng',
      categoryId: team['categoryId']?.toString() ?? team['category_id']?.toString() ?? '',
      logoUrl: team['logoUrl']?.toString() ?? team['logo_url']?.toString(),
      role: membership?['role']?.toString().toUpperCase(),
      status: team['status']?.toString().toUpperCase() ?? 'ACTIVE',
      members: (team['members'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => FootballTeamMemberSummary.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      eloPoints: ((json['rank'] is Map ? json['rank']['eloPoints'] : null) as num?)?.toInt() ?? 1000,
      peakElo: ((json['rank'] is Map ? json['rank']['peakElo'] : null) as num?)?.toInt() ?? 1000,
      matchesPlayed: ((json['rank'] is Map ? json['rank']['matchesPlayed'] : null) as num?)?.toInt() ?? 0,
      matchesWon: ((json['rank'] is Map ? json['rank']['matchesWon'] : null) as num?)?.toInt() ?? 0,
      winStreak: ((json['rank'] is Map ? json['rank']['winStreak'] : null) as num?)?.toInt() ?? 0,
    );
  }
}

class FootballTeamMemberSummary {
  const FootballTeamMemberSummary({required this.userId, required this.role, this.status});
  final String userId;
  final String role;
  final String? status;

  factory FootballTeamMemberSummary.fromJson(Map<String, dynamic> json) => FootballTeamMemberSummary(
    userId: json['userId']?.toString() ?? json['user_id']?.toString() ?? '',
    role: (json['role']?.toString() ?? 'PLAYER').toUpperCase(),
    status: json['status']?.toString(),
  );
}
