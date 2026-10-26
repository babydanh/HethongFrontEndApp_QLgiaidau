import 'dart:ui';

import 'package:app_quanly_giaidau/core/participants/match_side_players.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

const Map<String, String> _vietnameseLetters = {
  'a': 'àáạảãâầấậẩẫăằắặẳẵ',
  'e': 'èéẹẻẽêềếệểễ',
  'i': 'ìíịỉĩ',
  'o': 'òóọỏõôồốộổỗơờớợởỡ',
  'u': 'ùúụủũưừứựửữ',
  'y': 'ỳýỵỷỹ',
  'd': 'đ',
};

final Map<int, String> _foldTable = {
  for (final entry in _vietnameseLetters.entries)
    for (final rune in entry.value.runes) rune: entry.key,
};
final RegExp _combiningMarks = RegExp(r'[\u0300-\u036f]');
final RegExp _notLetterOrSpace = RegExp(r'[^a-z\s]');
final RegExp _spaces = RegExp(r'\s+');

/// Initials of the last two words of [name], accent-free and upper case
/// ("Nguyễn Văn An" -> "VA"). Same rule and test vectors as Web.
String abbreviateNameForCode(String? name) {
  if (name == null) return '';
  final folded = name
      .toLowerCase()
      .replaceAll(_combiningMarks, '')
      .runes
      .map((rune) => _foldTable[rune] ?? String.fromCharCode(rune))
      .join()
      .replaceAll(_notLetterOrSpace, '');
  final words = folded.split(_spaces).where((word) => word.isNotEmpty).toList();
  final lastTwo = words.length > 2 ? words.sublist(words.length - 2) : words;
  return lastTwo.map((word) => word[0]).join().toUpperCase();
}

/// `<code><side 1 initials><side 2 initials>`; a side without a name is
/// skipped. Null when [code] is missing or blank.
String? buildMatchCode(String? code, String? side1, String? side2) {
  final base = code?.trim() ?? '';
  if (base.isEmpty) return null;
  return '$base${abbreviateNameForCode(side1)}${abbreviateNameForCode(side2)}';
}

/// Name that stands for one side of [match]: the first player (doubles use
/// their first member), or the team name for football and player-less sides.
String? _sideNameForCode(MatchModel match, int side) {
  if (!isFootballMatch(match)) {
    final players = matchSidePlayers(match, side);
    if (players.isNotEmpty) return players.first.fullName;
  }
  return matchSideTeamName(match, side);
}

/// Display code of [match], or null when the backend sent none. Club matches
/// never show a code.
String? matchCodeOrNull(MatchModel match) {
  if (match.clubMatchSessionId != null || match.isStandaloneMatch) return null;
  return buildMatchCode(
    match.matchCode,
    _sideNameForCode(match, 1),
    _sideNameForCode(match, 2),
  );
}

/// Match code when present, otherwise the legacy "Trận N" label.
String formatMatchCode(MatchModel match, {AppLocalizations? l10n}) {
  final code = matchCodeOrNull(match);
  if (code != null) return code;
  final strings =
      l10n ?? lookupAppLocalizations(PlatformDispatcher.instance.locale);
  return strings.workspaceMatchLabel(match.matchNumber);
}
