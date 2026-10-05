const List<String> _racketFormatOptions = [
  'MALE_SINGLES',
  'FEMALE_SINGLES',
  'MALE_DOUBLES',
  'FEMALE_DOUBLES',
  'MIXED_DOUBLES',
  'OPEN_SINGLES',
  'OPEN_DOUBLES',
];

const List<String> _footballFormatOptions = [
  'FOOTBALL_MALE',
  'FOOTBALL_FEMALE',
  'FOOTBALL_MIXED',
];

List<String> quickTournamentFormatOptions({required bool isFootball}) =>
    isFootball ? _footballFormatOptions : _racketFormatOptions;

Map<String, String> quickTournamentApiFormatFields(String formatKey) {
  final genderRestriction = _genderRestrictionForFormat(formatKey);
  return {
    'format': formatKey.contains('SINGLES') ? 'singles' : 'doubles',
    if (genderRestriction != null) 'genderRestriction': genderRestriction,
  };
}

Map<String, String> quickTournamentDivisionFormatFields(String formatKey) {
  final genderRestriction = _genderRestrictionForFormat(formatKey);
  return {
    'matchType': formatKey.contains('SINGLES')
        ? 'SINGLES'
        : formatKey == 'MIXED_DOUBLES'
            ? 'MIXED_DOUBLES'
            : 'DOUBLES',
    if (genderRestriction != null) 'genderRestriction': genderRestriction,
  };
}

String? _genderRestrictionForFormat(String formatKey) => switch (formatKey) {
      'MALE_SINGLES' || 'MALE_DOUBLES' || 'FOOTBALL_MALE' => 'MALE',
      'FEMALE_SINGLES' || 'FEMALE_DOUBLES' || 'FOOTBALL_FEMALE' => 'FEMALE',
      'MIXED_DOUBLES' || 'FOOTBALL_MIXED' => 'MIXED',
      _ => null,
    };
