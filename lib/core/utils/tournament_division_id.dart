import 'package:app_quanly_giaidau/domain/entities/tournament.dart';

/// Returns the division identifier that can exist in persisted tournament data.
///
/// Quick tournaments may expose a synthetic `default_*` division in the UI;
/// registration persistence intentionally stores those applications without a
/// division, so lookup requests must not filter by that synthetic identifier.
String? persistedTournamentDivisionId(String? divisionId) {
  if (divisionId == null ||
      divisionId.isEmpty ||
      divisionId.startsWith('default_')) {
    return null;
  }
  return divisionId;
}

/// Returns the division a registration call should carry when the caller has
/// no division picker of its own (community roster, poll vote, ...).
///
/// Mirrors the server rule in `tournament-registration.repository.ts` and
/// `tournament-lite.service.ts`: an omitted division resolves to the only
/// active division, and a tournament with several active divisions is rejected
/// instead of guessed. Returns the id only when exactly one active division
/// exists so these callers stop relying on the fallback — and never infer a
/// division from a player's gender. Synthetic `default_*` ids are dropped by
/// [persistedTournamentDivisionId]: they exist only in the UI.
String? soleActiveTournamentDivisionId(
  Iterable<TournamentDivision> divisions,
) {
  final activeIds = divisions
      .where(
        (division) => division.status?.trim().toUpperCase() != 'CANCELLED',
      )
      .map((division) => persistedTournamentDivisionId(division.id))
      .whereType<String>()
      .toSet();
  return activeIds.length == 1 ? activeIds.single : null;
}