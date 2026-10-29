// DUPR limit helpers shared by the division editor and the register screens.
// The backend is the source of truth; these only guide the user client-side.

/// Selectable limit values: 2.0 to 6.0 in 0.5 steps.
/// UI choice; Backend accepts 1.0–8.0 in 0.5 steps; stored values outside the
/// list are still shown by the editor.
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

/// Range the backend accepts for a self-declared DUPR rating.
const double duprRatingMin = 1.0;
const double duprRatingMax = 8.0;

/// True when [value] is finite, within 1.0–8.0 and has at most 2 decimals.
bool isValidDuprRating(double value) {
  if (!value.isFinite || value < duprRatingMin || value > duprRatingMax) {
    return false;
  }
  return ((value * 100).round() / 100 - value).abs() < 1e-9;
}

final RegExp _ratingText = RegExp(r'^\d+(\.\d{1,2})?$');

/// Parses typed text ("3.5" or "3,5"); null when empty, malformed, outside
/// 1.0–8.0 or with more than 2 decimals.
double? parseDuprRating(String text) {
  final normalized = text.trim().replaceAll(',', '.');
  if (!_ratingText.hasMatch(normalized)) return null;
  final value = double.parse(normalized);
  return isValidDuprRating(value) ? value : null;
}

/// Display text with 1 to 2 decimals (3 -> "3.0", 3.62 -> "3.62").
String formatDuprRating(double value) {
  final text = ((value * 100).round() / 100).toStringAsFixed(2);
  return text.endsWith('0') ? text.substring(0, text.length - 1) : text;
}
