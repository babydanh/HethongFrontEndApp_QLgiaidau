import 'package:app_quanly_giaidau/domain/repositories/tournament_repository.dart';

class FinalizeTournamentUseCase {
  final ITournamentRepository _tournamentRepository;

  const FinalizeTournamentUseCase(this._tournamentRepository);

  Future<void> call(String tournamentId) {
    // Chỉ backend chấp nhận `status`; `updatedAt` do server tự sinh.
    return _tournamentRepository.updateStatus(tournamentId, 'COMPLETED');
  }
}
