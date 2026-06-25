import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/utils/token_generator.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_repository.dart';
import 'package:uuid/uuid.dart';

class CreateTournamentParams {
  final String name;
  final String sport;
  final String format;
  final String? category;
  final String bracketType;
  final String description;
  final int maxTeams;
  final int roundCount;

  const CreateTournamentParams({
    required this.name,
    required this.sport,
    required this.format,
    required this.category,
    required this.bracketType,
    required this.description,
    required this.maxTeams,
    required this.roundCount,
  });
}

class CreateTournamentUseCase {
  final ITournamentRepository _tournamentRepository;

  const CreateTournamentUseCase(this._tournamentRepository);

  Future<Tournament> call(CreateTournamentParams params) {
    final tokens = TokenGenerator.generateAll();
    final now = DateTime.now();

    final tournament = Tournament(
      id: const Uuid().v4(),
      name: params.name.trim(),
      sport: params.sport,
      format: params.format,
      category: params.category,
      bracketType: params.bracketType,
      status: AppConstants.statusDraft,
      adminToken: tokens[AppConstants.roleAdmin]!,
      refereeToken: tokens[AppConstants.roleReferee]!,
      viewerToken: tokens[AppConstants.roleViewer]!,
      creatorId: 'admin-mobile-id',
      maxTeams: params.maxTeams,
      description: params.description.trim(),
      roundCount: params.roundCount,
      createdAt: now,
      updatedAt: now,
    );

    return _tournamentRepository.create(tournament);
  }
}
