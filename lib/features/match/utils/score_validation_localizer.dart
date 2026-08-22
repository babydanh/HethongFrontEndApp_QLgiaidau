import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

String formatScoreValidationError(AppLocalizations l10n, String token) {
  final parts = token.split('|');
  if (parts.length < 7 || parts.first != 'scoreValidation') return token;

  final code = parts[1];
  final setNumber = int.tryParse(parts[2]) ?? 1;
  final score1 = int.tryParse(parts[3]) ?? 0;
  final score2 = int.tryParse(parts[4]) ?? 0;
  final target = int.tryParse(parts[5]) ?? 0;
  final maxPoints = int.tryParse(parts[6]) ?? 0;
  final label = switch (code) {
    'sideOutDeuceMargin' ||
    'sideOutTarget' ||
    'sideOutExactTarget' ||
    'sideOutMaximumScore' => l10n.scoreValidationGameLabel(setNumber),
    'tennisSet' || 'tennisTiebreak' => l10n.scoreValidationSetLabel(setNumber),
    _ => l10n.scoreValidationRallyLabel(setNumber),
  };

  return switch (code) {
    'tie' => l10n.scoreValidationTie(label, score1, score2),
    'minimumScore' => l10n.scoreValidationMinimum(label, target),
    'deuceMargin' => l10n.scoreValidationDeuceMargin(label),
    'exactTarget' => l10n.scoreValidationExactTarget(label, target),
    'maximumScore' => l10n.scoreValidationMaximum(label, maxPoints),
    'tennisSet' => l10n.scoreValidationTennisSet(label, score1, score2),
    'tennisTiebreak' => l10n.scoreValidationTennisTiebreak(label, score1, score2),
    'sideOutDeuceMargin' => l10n.scoreValidationSideOutDeuce(label),
    'sideOutTarget' => l10n.scoreValidationSideOutTarget(label, target),
    'sideOutExactTarget' => l10n.scoreValidationSideOutExactTarget(label, target),
    'sideOutMaximumScore' => l10n.scoreValidationSideOutMaximum(label, maxPoints),
    _ => l10n.scoreValidationUnknown,
  };
}
