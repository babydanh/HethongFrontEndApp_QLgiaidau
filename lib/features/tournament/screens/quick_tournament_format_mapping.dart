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

/// Cấp giải gửi `POST /tournaments/lite`. Giới tính MALE/FEMALE chỉ nằm ở
/// nội dung; cấp giải chỉ mang `MIXED` cho nội dung hỗn hợp.
Map<String, String> quickTournamentApiFormatFields(String formatKey) {
  return {
    'format': _apiFormat(formatKey),
    if (_hasMixedTournamentGender(formatKey)) 'genderRestriction': 'MIXED',
  };
}

Map<String, String> quickTournamentDivisionFormatFields(String formatKey) {
  final genderRestriction = _genderRestrictionForFormat(formatKey);
  return {
    'matchType': _divisionMatchType(formatKey),
    if (genderRestriction != null) 'genderRestriction': genderRestriction,
  };
}

String _apiFormat(String formatKey) {
  if (formatKey == 'MIXED_DOUBLES') return 'mixed_doubles';
  if (_isSingles(formatKey)) return 'singles';
  return 'doubles';
}

String _divisionMatchType(String formatKey) {
  if (_isSingles(formatKey)) return 'SINGLES';
  if (formatKey == 'MIXED_DOUBLES') return 'MIXED_DOUBLES';
  return 'DOUBLES';
}

// Bóng đá là đội-đấu-đội, backend ép nội dung về SINGLES.
bool _isSingles(String formatKey) =>
    formatKey.contains('SINGLES') || formatKey.startsWith('FOOTBALL_');

bool _hasMixedTournamentGender(String formatKey) =>
    formatKey == 'MIXED_DOUBLES' || formatKey == 'FOOTBALL_MIXED';

String? _genderRestrictionForFormat(String formatKey) => switch (formatKey) {
      'MALE_SINGLES' || 'MALE_DOUBLES' || 'FOOTBALL_MALE' => 'MALE',
      'FEMALE_SINGLES' || 'FEMALE_DOUBLES' || 'FOOTBALL_FEMALE' => 'FEMALE',
      'MIXED_DOUBLES' || 'FOOTBALL_MIXED' => 'MIXED',
      _ => null,
    };
