import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_repository.dart';

class ResetTournamentDrawUseCase {
  final IMatchRepository _matchRepository;
  final ITournamentRepository _tournamentRepository;

  const ResetTournamentDrawUseCase(
    this._matchRepository,
    this._tournamentRepository,
  );

  Future<void> call(String tournamentId) async {
    await _matchRepository.deleteAll(tournamentId);
    await _tournamentRepository.update(
      tournamentId,
      {
        'status': AppConstants.statusRegistration,
        'updatedAt': DateTime.now(),
      },
    );
  }
}
