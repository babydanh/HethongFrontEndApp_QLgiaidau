import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_repository.dart';

class FinalizeTournamentUseCase {
  final ITournamentRepository _tournamentRepository;

  const FinalizeTournamentUseCase(this._tournamentRepository);

  Future<void> call(String tournamentId) {
    return _tournamentRepository.update(
      tournamentId,
      {
        'status': AppConstants.statusCompleted,
        'updatedAt': DateTime.now(),
      },
    );
  }
}
