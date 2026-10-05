String? normalizeDivisionGenderRestriction(String? value) {
  final normalized = value
      ?.trim()
      .toUpperCase()
      .replaceAll(RegExp(r'[\s-]+'), '_');
  return switch (normalized) {
    'MALE' || 'MEN' || 'NAM' => 'MALE',
    'FEMALE' || 'WOMEN' || 'NU' || 'NỮ' => 'FEMALE',
    'MIXED' ||
    'MIXED_DOUBLES' ||
    'MIXED_GENDER' ||
    'NAM_NU' ||
    'NAM_NỮ' => 'MIXED',
    _ => null,
  };
}

bool requiresGenderProfileForDivision(String? restriction) {
  final normalized = restriction?.trim().toUpperCase();
  return normalized != null && normalized.isNotEmpty && normalized != 'OPEN';
}
