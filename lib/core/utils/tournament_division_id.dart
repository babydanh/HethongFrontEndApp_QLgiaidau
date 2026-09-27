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
