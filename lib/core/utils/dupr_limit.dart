/// DUPR limit helpers shared by the division editor and the register screens.
/// The backend is the source of truth; these only guide the user client-side.

/// Selectable limit values: 2.0 to 6.0 in 0.5 steps.
const List<double> duprLimitOptions = [
  2.0,
  2.5,
  3.0,
  3.5,
  4.0,
  4.5,
  5.0,
  5.5,
  6.0,
];

enum DuprLimitStatus { ok, missing, belowMin, aboveMax }

/// Both bounds are inclusive. No limit means [DuprLimitStatus.ok]; a limit
/// with no rating means [DuprLimitStatus.missing].
DuprLimitStatus checkDuprAgainstLimit({
  required double? value,
  required double? minDupr,
  required double? maxDupr,
}) {
  if (minDupr == null && maxDupr == null) return DuprLimitStatus.ok;
  if (value == null) return DuprLimitStatus.missing;
  if (minDupr != null && value < minDupr) return DuprLimitStatus.belowMin;
  if (maxDupr != null && value > maxDupr) return DuprLimitStatus.aboveMax;
  return DuprLimitStatus.ok;
}

/// `3.0 – 3.5`, `≤ 3.5`, `≥ 3.0`, or null when there is no limit.
String? formatDuprRange(double? minDupr, double? maxDupr) {
  if (minDupr != null && maxDupr != null) {
    return '${minDupr.toStringAsFixed(1)} – ${maxDupr.toStringAsFixed(1)}';
  }
  if (maxDupr != null) return '≤ ${maxDupr.toStringAsFixed(1)}';
  if (minDupr != null) return '≥ ${minDupr.toStringAsFixed(1)}';
  return null;
}

/// Picks the rating from external-rating rows: `API` rows first, then `SELF`.
/// Rows whose value is not numeric are skipped.
double? pickDuprFromRatings(List<Map<String, dynamic>> rows) {
  for (final source in const ['API', 'SELF']) {
    for (final row in rows) {
      if (row['source'] != source) continue;
      final raw = row['value'];
      final value = raw is num ? raw.toDouble() : double.tryParse('$raw');
      if (value != null) return value;
    }
  }
  return null;
}
