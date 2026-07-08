import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/data/models/team_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/team_repository.dart';

class ApiTeamRepository implements ITeamRepository {
  static const _log = AppLogger('ApiTeamRepo');
  final DioClient _dioClient;

  ApiTeamRepository(this._dioClient);

  @override
  Future<Team> create(String tournamentId, Team team) async {
    _log.info('Creating team via API: ${team.name} inside $tournamentId');
    // Với backend REST API, việc đăng ký VĐV/Đội đi qua endpoint đăng ký giải đấu
    final payload = {
      'teamName': team.name,
      'contactPhone': team.contactEmail.isNotEmpty ? team.contactEmail : '0900000000',
      'playerNames': team.members.isNotEmpty ? team.members : [team.name],
    };
    final response = await _dioClient.dio.post('/tournaments/$tournamentId/register', data: payload);
    if (response.statusCode == 200 || response.statusCode == 201) {
      // Map API response back to Team model
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
    yield await getAllByTournament(tournamentId);
    yield* Stream.periodic(const Duration(seconds: 12))
        .asyncMap((_) => getAllByTournament(tournamentId));
  }

  @override
  Future<List<Team>> getAllByTournament(String tournamentId) async {
    _log.debug('Fetching all participants/teams for tournament: $tournamentId');
    try {
      final response = await _dioClient.dio.get('/tournaments/$tournamentId/participants');
      if (response.statusCode == 200) {
        final List<dynamic> list = response.data['data'] ?? response.data ?? [];
        return list.map((json) {
          // Xử lý mapping format API NestJS khác với Team model cũ của app
          final String id = json['id'] ?? '';
          final String teamName = json['teamName'] ?? '';
          final List<dynamic> rosters = json['rosters'] ?? [];
          final List<String> members = rosters.map((r) => r['fullName'] as String).toList();
          
          return Team(
            id: id,
            name: teamName,
            members: members.isNotEmpty ? members : [teamName],
            contactEmail: json['contactPhone'] ?? '',
            qrCode: json['qrCode'] ?? id,
            approvalStatus:
                json['teamStatus']?.toString().toUpperCase() ??
                json['status']?.toString().toUpperCase() ??
                'PENDING',
            createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
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
