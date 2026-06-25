import 'package:app_quanly_giaidau/domain/entities/team.dart';

abstract class ITeamRepository {
  Future<Team> create(String tournamentId, Team team);
  Future<void> importTeams(String tournamentId, List<Team> teams);
  Future<Team?> getById(String tournamentId, String teamId);
  Stream<List<Team>> watchByTournament(String tournamentId);
  Future<List<Team>> getAllByTournament(String tournamentId);
  Future<void> update(String tournamentId, String teamId, Map<String, dynamic> data);
  Future<void> checkIn(String tournamentId, String teamId);
  Future<Team?> findByQrCode(String tournamentId, String qrCode);
  Future<void> delete(String tournamentId, String teamId);
  Future<void> deleteAll(String tournamentId);
  Future<int> count(String tournamentId);
}
