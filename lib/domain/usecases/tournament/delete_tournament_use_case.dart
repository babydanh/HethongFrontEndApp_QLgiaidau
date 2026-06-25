import 'package:app_quanly_giaidau/domain/repositories/token_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_repository.dart';

class DeleteTournamentUseCase {
  final ITournamentRepository _tournamentRepository;
  final ITokenRepository _tokenRepository;

  const DeleteTournamentUseCase(
    this._tournamentRepository,
    this._tokenRepository,
  );

  Future<void> call(String tournamentId) async {
    await _tokenRepository.deleteTokensByTournament(tournamentId);
    await _tournamentRepository.delete(tournamentId);
  }
}
