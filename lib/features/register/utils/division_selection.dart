import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

import 'package:app_quanly_giaidau/domain/entities/tournament_registration.dart';

bool isRegistrationDivisionActive(TournamentDivisionOption division) =>
    division.status?.trim().toUpperCase() != 'CANCELLED' &&
    division.isRegistrationOpen;

List<TournamentDivisionOption> registrationDivisionOptions(
  Iterable<TournamentDivisionOption> divisions,
) => divisions
    .where((division) => division.status?.trim().toUpperCase() != 'CANCELLED')
    .toList(growable: false);

List<TournamentDivisionOption> activeRegistrationDivisions(
  Iterable<TournamentDivisionOption> divisions,
) => divisions.where(isRegistrationDivisionActive).toList(growable: false);

String? resolveRegistrationDivisionId(
  Iterable<TournamentDivisionOption> divisions, {
  String? preferredDivisionId,
}) {
  final activeDivisions = activeRegistrationDivisions(divisions);
  if (preferredDivisionId != null &&
      activeDivisions.any((division) => division.id == preferredDivisionId)) {
    return preferredDivisionId;
  }

  return activeDivisions.length == 1 ? activeDivisions.single.id : null;
}

String registrationDivisionClosedReasonLabel(
  AppLocalizations l10n,
  TournamentDivisionOption division,
) => switch (division.registrationClosedReason?.toUpperCase()) {
  'TOURNAMENT_LOCKED' || 'DIVISION_LOCKED' => l10n.registerDivisionLocked,
  'DEADLINE_PASSED' => l10n.registerDivisionDeadlinePassed,
  'TOURNAMENT_NOT_OPEN' => l10n.registerTournamentNotOpen,
  _ => division.isFull
      ? l10n.registerDivisionFull
      : l10n.registerDivisionClosed,
};
