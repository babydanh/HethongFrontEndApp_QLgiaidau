import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_repository.dart';

class PublishTournamentDrawUseCase {
  final IMatchRepository _matchRepository;
  final ITournamentRepository _tournamentRepository;

  const PublishTournamentDrawUseCase(
    this._matchRepository,
    this._tournamentRepository,
  );

  Future<void> call(String tournamentId, List<MatchModel> matches) async {
    await _matchRepository.createBatch(tournamentId, matches);
    await _tournamentRepository.update(
      tournamentId,
      {
        'status': AppConstants.statusInProgress,
        'updatedAt': DateTime.now(),
      },
    );
  }
}
