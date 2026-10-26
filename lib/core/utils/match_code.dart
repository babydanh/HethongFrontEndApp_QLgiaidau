import 'dart:ui';

import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

/// Returns the trimmed backend code, or null when it is missing or blank.
String? buildMatchCode(String? code) {
  final trimmed = code?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

/// Raw backend code for [match], or null for club and standalone matches.
String? matchCodeOrNull(MatchModel match) {
  if (match.clubMatchSessionId != null || match.isStandaloneMatch) return null;
  return buildMatchCode(match.matchCode);
}

/// Display label for [match]: `#<matchCode>`, or the legacy "Trận N" label.
String formatMatchCode(MatchModel match, {AppLocalizations? l10n}) {
  final code = matchCodeOrNull(match);
  if (code != null) return '#$code';
  final strings =
      l10n ?? lookupAppLocalizations(PlatformDispatcher.instance.locale);
  return strings.workspaceMatchLabel(match.matchNumber);
}
