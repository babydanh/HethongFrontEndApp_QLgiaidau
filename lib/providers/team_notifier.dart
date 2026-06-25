import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/data/models/team_model.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';

class TeamService {
  final Ref ref;
  final String tournamentId;

  TeamService(this.ref, this.tournamentId);

  Future<void> _checkConstraints() async {
    final tournamentAsync = ref.read(tournamentProvider(tournamentId));
    final tournament = tournamentAsync.value;
    
    if (tournament == null) {
      throw StateError('Không tìm thấy thông tin giải đấu.');
    }
    
    if (tournament.status == AppConstants.statusInProgress || 
        tournament.status == AppConstants.statusCompleted) {
      throw StateError('Không thể thay đổi danh sách đội khi giải đấu đang diễn ra hoặc đã kết thúc.');
    }
  }

  Future<void> addTeam(Team team) async {
    await _checkConstraints();
    await ref.read(teamRepositoryProvider).create(tournamentId, team);
  }

  Future<void> updateTeam(Team team) async {
    await _checkConstraints();
    await ref.read(teamRepositoryProvider).update(tournamentId, team.id, team.toJson());
  }

  Future<void> deleteTeam(String teamId) async {
    await _checkConstraints();
    await ref.read(teamRepositoryProvider).delete(tournamentId, teamId);
  }

  Future<void> importTeams(List<Team> teams) async {
    await _checkConstraints();
    await ref.read(teamRepositoryProvider).importTeams(tournamentId, teams);
  }

  Future<void> deleteAllTeams() async {
    await _checkConstraints();
    // Xóa tất cả các đội
    await ref.read(teamRepositoryProvider).deleteAll(tournamentId);
    // Đồng thời reset bracket (xóa toàn bộ trận đấu) để tránh tham chiếu rác
    await ref.read(matchRepositoryProvider).deleteAll(tournamentId);
  }
}

final teamServiceProvider = Provider.family<TeamService, String>((ref, tournamentId) {
  return TeamService(ref, tournamentId);
});
