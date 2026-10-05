import 'package:app_quanly_giaidau/domain/entities/tournament_registration.dart';

bool isRegistrationDivisionActive(TournamentDivisionOption division) =>
    division.status?.trim().toUpperCase() != 'CANCELLED';

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
