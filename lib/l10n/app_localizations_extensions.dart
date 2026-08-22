import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

extension AppLocalizationsDisplayNames on AppLocalizations {
  String sportDisplayName(String? key) {
    return switch (key?.trim().toLowerCase()) {
      AppConstants.sportFootball => createClubTournament_sportFootball,
      AppConstants.sportBadminton => createClubTournament_sportBadminton,
      AppConstants.sportTennis => createClubTournament_sportTennis,
      AppConstants.sportPickleball => createClubTournament_sportPickleball,
      AppConstants.sportTableTennis => createClubTournament_sportTableTennis,
      _ => key?.trim() ?? '',
    };
  }

  String formatDisplayName(String? key) {
    return switch (key?.trim().toLowerCase()) {
      AppConstants.formatSingles => createClubTournament_formatSingles,
      AppConstants.formatDoubles => createClubTournament_formatDoubles,
      AppConstants.formatMixedDoubles => createClubTournament_formatMixedDoubles,
      _ => key?.trim().replaceAll('_', ' ') ?? '',
    };
  }

  String categoryDisplayName(String? key) {
    return switch (key?.trim().toLowerCase()) {
      AppConstants.categoryMenSingles => tournamentCategoryMenSingles,
      AppConstants.categoryWomenSingles => tournamentCategoryWomenSingles,
      AppConstants.categoryMenDoubles => tournamentCategoryMenDoubles,
      AppConstants.categoryWomenDoubles => tournamentCategoryWomenDoubles,
      AppConstants.categoryMixedDoubles => tournamentCategoryMixedDoubles,
      _ => key?.trim().replaceAll('_', ' ') ?? '',
    };
  }

  String bracketDisplayName(String? key) {
    return switch (key?.trim().toLowerCase()) {
      AppConstants.bracketSingleElimination =>
        createClubTournament_bracketSingleElimination,
      AppConstants.bracketDoubleElimination =>
        createClubTournament_bracketDoubleElimination,
      AppConstants.bracketRoundRobin => createClubTournament_bracketRoundRobin,
      AppConstants.bracketGroupStageKnockout =>
        createClubTournament_bracketGroupStageKnockout,
      _ => key?.trim().replaceAll('_', ' ') ?? '',
    };
  }

  String bracketDescription(String? key) {
    return switch (key?.trim().toLowerCase()) {
      AppConstants.bracketSingleElimination =>
        createClubTournament_bracketSingleEliminationDescription,
      AppConstants.bracketDoubleElimination =>
        createClubTournament_bracketDoubleEliminationDescription,
      AppConstants.bracketRoundRobin =>
        createClubTournament_bracketRoundRobinDescription,
      AppConstants.bracketGroupStageKnockout =>
        createClubTournament_bracketGroupStageKnockoutDescription,
      _ => '',
    };
  }
}
